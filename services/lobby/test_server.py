from __future__ import annotations

import json
import threading
import unittest
import urllib.error
import urllib.request

from services.lobby.server import (
    CHAT_MESSAGE_LIMIT,
    LobbyError,
    LobbyHTTPServer,
    LobbyStore,
    MAX_CHAT_MESSAGE_CHARS,
)


class LobbyServiceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = LobbyHTTPServer(("127.0.0.1", 0), LobbyStore())
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls) -> None:
        # Avoid BaseServer.shutdown's platform-dependent wait when the test
        # runner tears down an otherwise idle loopback server.
        cls.server._BaseServer__shutdown_request = True
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def request(self, method, path, payload=None, token=None, expected=200):
        data = None if payload is None else json.dumps(payload).encode()
        headers = {"Connection": "close"}
        if payload is not None:
            headers["Content-Type"] = "application/json"
        if token:
            headers["Authorization"] = f"Bearer {token}"
        request = urllib.request.Request(
            self.base + path, data=data, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(request, timeout=2) as response:
                self.assertEqual(expected, response.status)
                self.assertEqual("no-store", response.headers["Cache-Control"])
                return json.load(response)
        except urllib.error.HTTPError as error:
            self.assertEqual(expected, error.code)
            return json.load(error)

    def session(self, name, build="4", product_id="meleepad", **overrides):
        payload = {
            "display_name": name,
            "product_id": product_id,
            "app_version": "0.1.0",
            "build": build,
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        payload.update(overrides)
        return self.request(
            "POST",
            "/v1/sessions",
            payload,
            expected=201,
        )

    def test_health_does_not_require_authentication(self):
        self.assertEqual(
            {"status": "ok"}, self.request("GET", "/healthz", expected=200)
        )

    def test_capabilities_do_not_require_authentication(self):
        result = self.request("GET", "/v1/capabilities", expected=200)
        self.assertEqual("pad-lobby-1", result["protocol"])
        self.assertEqual(
            {"meleepad", "kartpad"},
            {product["product_id"] for product in result["products"]},
        )

    def test_rooms_are_private_to_the_current_product_but_activity_is_shared(self):
        melee = self.session("MeleeHost")
        melee_room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "1234abcd", "region": "asia", "capacity": 4},
            melee["token"],
            201,
        )
        kart = self.session(
            "KartHost",
            product_id="kartpad",
            protocol="retro-wfc-1",
            game_id="RMCE01",
        )
        kart_room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "4321dcba", "region": "asia", "capacity": 4},
            kart["token"],
            201,
        )
        melee_listing = self.request("GET", "/v1/rooms", token=melee["token"])
        self.assertIn(melee_room["room_id"], [r["room_id"] for r in melee_listing["rooms"]])
        self.assertNotIn(kart_room["room_id"], json.dumps(melee_listing))

        activity = self.request("GET", "/v1/activity", token=melee["token"])
        by_product = {item["product_id"]: item for item in activity["products"]}
        self.assertGreaterEqual(by_product["meleepad"]["open_rooms"], 1)
        self.assertEqual(1, by_product["kartpad"]["open_rooms"])
        self.assertEqual(1, by_product["kartpad"]["players"])
        serialized = json.dumps(activity)
        self.assertNotIn("KartHost", serialized)
        self.assertNotIn(kart_room["room_id"], serialized)
        self.assertNotIn("4321dcba", serialized)

    def test_unsupported_products_fail_closed(self):
        rejected = self.request(
            "POST",
            "/v1/sessions",
            {
                "display_name": "UnknownHost",
                "product_id": "unknownpad",
                "app_version": "0.1.0",
                "build": "4",
                "protocol": "unknown-1",
                "game_id": "UNKNOWN",
                "game_revision": "r0",
            },
            expected=400,
        )
        self.assertEqual("UNSUPPORTED_PRODUCT", rejected["error"]["code"])

    def test_room_code_is_hidden_until_compatible_join(self):
        host = self.session("Host")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "1234abcd", "region": "asia"},
            host["token"],
            201,
        )
        guest = self.session("Guest")
        listing = self.request("GET", "/v1/rooms", token=guest["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        self.assertTrue(card["compatible"])
        self.assertTrue(card["joinable"])
        self.assertEqual(1, card["open_seats"])
        self.assertEqual(
            [{"session_id": host["session_id"], "name": "Host", "role": "host"}],
            card["roster"],
        )
        self.assertGreaterEqual(card["updated_seconds_ago"], 0)
        self.assertNotIn("traversal_code", card)
        joined = self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"]
        )
        self.assertEqual("1234abcd", joined["traversal_code"])

    def test_incompatible_build_is_visible_but_cannot_join(self):
        host = self.session("VersionHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "aabbccdd", "region": "auto"},
            host["token"],
            201,
        )
        guest = self.session("OldBuild", build="3")
        listing = self.request("GET", "/v1/rooms", token=guest["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        self.assertFalse(card["compatible"])
        self.assertEqual("Different app build", card["compatibility"])
        failure = self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"], 409
        )
        self.assertEqual("INCOMPATIBLE", failure["error"]["code"])

    def test_room_chat_accepts_bounded_text_and_rejects_invalid_content(self):
        host = self.session("ChatHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "deadbeef", "region": "europe"},
            host["token"],
            201,
        )
        rejected = self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"kind": "legacy-preset"},
            host["token"],
            400,
        )
        self.assertEqual("UNKNOWN_FIELD", rejected["error"]["code"])
        accepted = self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"text": "  Battlefield first?  "},
            host["token"],
            201,
        )
        self.assertEqual("Battlefield first?", accepted["text"])
        self.assertEqual(host["session_id"], accepted["sender_id"])
        for invalid_text in ("", "x" * (MAX_CHAT_MESSAGE_CHARS + 1), "line\nbreak"):
            invalid = self.request(
                "POST",
                f"/v1/rooms/{room['room_id']}/messages",
                {"text": invalid_text},
                host["token"],
                400,
            )
            self.assertEqual("INVALID_MESSAGE", invalid["error"]["code"])
        for _ in range(CHAT_MESSAGE_LIMIT - 1):
            self.request(
                "POST",
                f"/v1/rooms/{room['room_id']}/messages",
                {"text": "Ready when you are"},
                host["token"],
                201,
            )
        limited = self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"text": "Hello"},
            host["token"],
            429,
        )
        self.assertEqual("RATE_LIMITED", limited["error"]["code"])
        messages = self.request(
            "GET", f"/v1/rooms/{room['room_id']}/messages?after=0", token=host["token"]
        )["messages"]
        self.assertEqual(CHAT_MESSAGE_LIMIT, len(messages))
        self.assertEqual("Battlefield first?", messages[0]["text"])

    def test_room_chat_hides_blocked_players_and_denies_outsiders(self):
        host = self.session("ChatOwner")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "abcddcba", "region": "asia"},
            host["token"],
            201,
        )
        guest = self.session("ChatGuest")
        outsider = self.session("ChatOutsider")
        self.request("POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"])
        self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"text": "Hello from the room"},
            guest["token"],
            201,
        )
        self.request(
            "POST", "/v1/blocks", {"session_id": guest["session_id"]}, host["token"]
        )
        messages = self.request(
            "GET", f"/v1/rooms/{room['room_id']}/messages?after=0", token=host["token"]
        )["messages"]
        self.assertEqual([], messages)
        denied = self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"text": "I should not be here"},
            outsider["token"],
            403,
        )
        self.assertEqual("ROOM_ACCESS", denied["error"]["code"])

    def test_report_also_hides_reported_hosts(self):
        host = self.session("ReportedHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "cafebabe", "region": "other"},
            host["token"],
            201,
        )
        guest = self.session("Reporter")
        listing = self.request("GET", "/v1/rooms", token=guest["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        result = self.request(
            "POST",
            "/v1/reports",
            {
                "session_id": card["host_id"],
                "room_id": card["room_id"],
                "reason": "offensive_name",
            },
            guest["token"],
            202,
        )
        self.assertTrue(result["accepted"])
        listing = self.request("GET", "/v1/rooms", token=guest["token"])
        self.assertNotIn(room["room_id"], {item["room_id"] for item in listing["rooms"]})

    def test_host_only_heartbeat_and_delete(self):
        host = self.session("Owner")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "01020304", "region": "north-america"},
            host["token"],
            201,
        )
        guest = self.session("NotOwner")
        denied = self.request(
            "PUT",
            f"/v1/rooms/{room['room_id']}/heartbeat",
            {"state": "waiting"},
            guest["token"],
            403,
        )
        self.assertEqual("HOST_ONLY", denied["error"]["code"])
        self.request(
            "PUT",
            f"/v1/rooms/{room['room_id']}/heartbeat",
            {"state": "in_game"},
            host["token"],
        )
        self.request("DELETE", f"/v1/rooms/{room['room_id']}", token=host["token"])

    def test_full_room_and_nonmember_messages_fail_closed(self):
        host = self.session("FullHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "11223344", "region": "oceania"},
            host["token"],
            201,
        )
        guest = self.session("FirstGuest")
        outsider = self.session("Outsider")
        self.request("POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"])
        full = self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, outsider["token"], 409
        )
        self.assertEqual("ROOM_FULL", full["error"]["code"])
        denied = self.request(
            "GET", f"/v1/rooms/{room['room_id']}/messages", token=outsider["token"], expected=403
        )
        self.assertEqual("ROOM_ACCESS", denied["error"]["code"])

    def test_room_capacity_supports_two_to_four_players(self):
        host = self.session("FourHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "12344321", "region": "asia", "capacity": 4},
            host["token"],
            201,
        )
        guests = [self.session(f"Guest{index}") for index in range(1, 5)]
        for guest in guests[:3]:
            self.request("POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"])
        listing = self.request("GET", "/v1/rooms", token=guests[0]["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        self.assertEqual(4, card["players"])
        self.assertEqual(4, card["capacity"])
        self.assertEqual(0, card["open_seats"])
        self.assertFalse(card["joinable"])
        self.assertEqual(
            ["FourHost", "Guest1", "Guest2", "Guest3"],
            [player["name"] for player in card["roster"]],
        )
        full = self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, guests[3]["token"], 409
        )
        self.assertEqual("ROOM_FULL", full["error"]["code"])

    def test_final_room_slots_are_reserved_atomically(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        base = {
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "5",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        host = store.authenticate(
            store.create_session({**base, "display_name": "AtomicHost"})["token"]
        )
        guests = [
            store.authenticate(
                store.create_session({**base, "display_name": f"Atomic{index}"})["token"]
            )
            for index in range(5)
        ]
        room = store.create_room(
            host,
            {"traversal_code": "abcdef12", "region": "auto", "capacity": 4},
        )
        outcomes = []
        outcomes_lock = threading.Lock()
        start = threading.Barrier(len(guests))

        def join(guest):
            start.wait()
            try:
                store.join_room(guest, room["room_id"])
                result = "joined"
            except LobbyError as error:
                result = error.code
            with outcomes_lock:
                outcomes.append(result)

        threads = [threading.Thread(target=join, args=(guest,)) for guest in guests]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=2)
        self.assertEqual(3, outcomes.count("joined"))
        self.assertEqual(2, outcomes.count("ROOM_FULL"))
        self.assertEqual(4, store.room_list(guests[0])["rooms"][0]["players"])

    def test_invalid_room_capacities_are_rejected(self):
        host = self.session("CapacityHost")
        for capacity in (1, 5, True, "4"):
            rejected = self.request(
                "POST",
                "/v1/rooms",
                {"traversal_code": "87654321", "region": "auto", "capacity": capacity},
                host["token"],
                400,
            )
            self.assertEqual("INVALID_CAPACITY", rejected["error"]["code"])

    def test_report_target_must_belong_to_referenced_room(self):
        first_host = self.session("FirstHost")
        first_room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "11112222", "region": "auto"},
            first_host["token"],
            201,
        )
        self_report = self.request(
            "POST",
            "/v1/reports",
            {
                "session_id": first_host["session_id"],
                "room_id": first_room["room_id"],
                "reason": "other",
            },
            first_host["token"],
            400,
        )
        self.assertEqual("INVALID_TARGET", self_report["error"]["code"])
        second_host = self.session("SecondHost")
        self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "33334444", "region": "auto"},
            second_host["token"],
            201,
        )
        reporter = self.session("ReporterTwo")
        rejected = self.request(
            "POST",
            "/v1/reports",
            {
                "session_id": second_host["session_id"],
                "room_id": first_room["room_id"],
                "reason": "spam",
            },
            reporter["token"],
            400,
        )
        self.assertEqual("REPORT_CONTEXT", rejected["error"]["code"])

    def test_public_roster_member_can_be_reported_then_hidden(self):
        host = self.session("RosterHost")
        room = self.request(
            "POST",
            "/v1/rooms",
            {"traversal_code": "44556677", "region": "asia", "capacity": 4},
            host["token"],
            201,
        )
        member = self.session("RosterMember")
        self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, member["token"]
        )
        reporter = self.session("RosterReporter")
        listing = self.request("GET", "/v1/rooms", token=reporter["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        self.assertEqual(["RosterHost", "RosterMember"], [p["name"] for p in card["roster"]])
        accepted = self.request(
            "POST",
            "/v1/reports",
            {
                "session_id": member["session_id"],
                "room_id": room["room_id"],
                "reason": "offensive_name",
            },
            reporter["token"],
            202,
        )
        self.assertTrue(accepted["accepted"])
        listing = self.request("GET", "/v1/rooms", token=reporter["token"])
        card = next(item for item in listing["rooms"] if item["room_id"] == room["room_id"])
        self.assertEqual(["RosterHost"], [p["name"] for p in card["roster"]])
        self.assertEqual(2, card["players"])

    def test_room_directory_reports_freshness_and_match_state(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        base = {
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "5",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        host = store.authenticate(
            store.create_session({**base, "display_name": "FreshHost"})["token"]
        )
        guest = store.authenticate(
            store.create_session({**base, "display_name": "FreshGuest"})["token"]
        )
        room = store.create_room(
            host,
            {"traversal_code": "8899aabb", "region": "europe", "capacity": 3},
        )
        now[0] += 12
        card = store.room_list(guest)["rooms"][0]
        self.assertEqual(12, card["updated_seconds_ago"])
        self.assertEqual(2, card["open_seats"])
        self.assertTrue(card["joinable"])
        store.heartbeat(host, room["room_id"], {"state": "in_game"})
        card = store.room_list(guest)["rooms"][0]
        self.assertEqual(0, card["updated_seconds_ago"])
        self.assertFalse(card["joinable"])

    def test_gameplay_heartbeats_keep_room_alive_then_return_it_to_waiting(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        base = {
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "5",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        host = store.authenticate(
            store.create_session({**base, "display_name": "MatchHost"})["token"]
        )
        guest = store.authenticate(
            store.create_session({**base, "display_name": "MatchGuest"})["token"]
        )
        room = store.create_room(
            host,
            {"traversal_code": "a1b2c3d4", "region": "asia", "capacity": 4},
        )
        for _ in range(4):
            now[0] += 15
            store.heartbeat(host, room["room_id"], {"state": "in_game"})
        card = store.room_list(guest)["rooms"][0]
        self.assertEqual("in_game", card["state"])
        self.assertFalse(card["joinable"])

        store.heartbeat(host, room["room_id"], {"state": "waiting"})
        card = store.room_list(guest)["rooms"][0]
        self.assertEqual("waiting", card["state"])
        self.assertTrue(card["joinable"])

    def test_reports_are_deduplicated_and_separately_rate_limited(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        base = {
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "5",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        reporter = store.authenticate(
            store.create_session({**base, "display_name": "RateReporter"})["token"]
        )
        targets = []
        for index in range(6):
            host = store.authenticate(
                store.create_session({**base, "display_name": f"RateHost{index}"})["token"]
            )
            room = store.create_room(
                host,
                {
                    "traversal_code": f"{index + 1:08x}",
                    "region": "auto",
                },
            )
            targets.append((host, room))
        for host, room in targets[:5]:
            self.assertTrue(
                store.report(
                    reporter,
                    {
                        "session_id": host.session_id,
                        "room_id": room["room_id"],
                        "reason": "spam",
                    },
                )["accepted"]
            )
        first_host, first_room = targets[0]
        self.assertTrue(
            store.report(
                reporter,
                {
                    "session_id": first_host.session_id,
                    "room_id": first_room["room_id"],
                    "reason": "spam",
                },
            )["accepted"]
        )
        final_host, final_room = targets[5]
        with self.assertRaises(LobbyError) as limited:
            store.report(
                reporter,
                {
                    "session_id": final_host.session_id,
                    "room_id": final_room["room_id"],
                    "reason": "spam",
                },
            )
        self.assertEqual("RATE_LIMITED", limited.exception.code)

    def test_stale_rooms_expire(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        payload = {
            "display_name": "ExpiryHost",
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "4",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        host_token = store.create_session(payload)["token"]
        guest_payload = dict(payload)
        guest_payload["display_name"] = "ExpiryGuest"
        guest_token = store.create_session(guest_payload)["token"]
        host = store.authenticate(host_token)
        guest = store.authenticate(guest_token)
        store.create_room(host, {"traversal_code": "55667788", "region": "auto"})
        self.assertEqual(1, len(store.room_list(guest)["rooms"]))
        now[0] += 46
        self.assertEqual([], store.room_list(guest)["rooms"])

    def test_joined_guest_can_extend_presence(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        base = {
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": "4",
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        }
        host_token = store.create_session({**base, "display_name": "PresenceHost"})["token"]
        guest_token = store.create_session({**base, "display_name": "PresenceGuest"})["token"]
        host = store.authenticate(host_token)
        guest = store.authenticate(guest_token)
        room = store.create_room(
            host, {"traversal_code": "99aabbcc", "region": "auto"}
        )
        store.join_room(guest, room["room_id"])
        now[0] += 15
        store.heartbeat_member(guest, room["room_id"])
        now[0] += 10
        message = store.send_message(guest, room["room_id"], {"text": "Hello"})
        self.assertEqual("Hello", message["text"])

    def test_auth_and_input_validation_fail_closed(self):
        missing = self.request("GET", "/v1/rooms", expected=401)
        self.assertEqual("AUTH_REQUIRED", missing["error"]["code"])
        rejected = self.request(
            "POST",
            "/v1/sessions",
            {
                "display_name": "bad/name",
                "product_id": "meleepad",
                "app_version": "0.1.0",
                "build": "4",
                "protocol": "moderngekko-netplay-8",
                "game_id": "GALE01",
                "game_revision": "r0",
            },
            expected=400,
        )
        self.assertEqual("INVALID_FIELD", rejected["error"]["code"])


if __name__ == "__main__":
    unittest.main()

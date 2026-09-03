from __future__ import annotations

import json
import threading
import unittest
import urllib.error
import urllib.request

from services.lobby.server import LobbyHTTPServer, LobbyStore, QUICK_MESSAGE_LIMIT


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

    def session(self, name, build="4"):
        return self.request(
            "POST",
            "/v1/sessions",
            {
                "display_name": name,
                "app_version": "0.1.0",
                "build": build,
                "protocol": "moderngekko-netplay-8",
                "game_id": "GALE01",
                "game_revision": "r0",
            },
            expected=201,
        )

    def test_health_does_not_require_authentication(self):
        self.assertEqual(
            {"status": "ok"}, self.request("GET", "/healthz", expected=200)
        )

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
        self.assertEqual("Different MeleePad build", card["compatibility"])
        failure = self.request(
            "POST", f"/v1/rooms/{room['room_id']}/join", {}, guest["token"], 409
        )
        self.assertEqual("INCOMPATIBLE", failure["error"]["code"])

    def test_quick_chat_rejects_free_text_and_rate_limits(self):
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
            {"kind": "custom", "text": "unbounded content"},
            host["token"],
            400,
        )
        self.assertEqual("UNKNOWN_FIELD", rejected["error"]["code"])
        for _ in range(QUICK_MESSAGE_LIMIT):
            self.request(
                "POST",
                f"/v1/rooms/{room['room_id']}/messages",
                {"kind": "ready"},
                host["token"],
                201,
            )
        limited = self.request(
            "POST",
            f"/v1/rooms/{room['room_id']}/messages",
            {"kind": "hello"},
            host["token"],
            429,
        )
        self.assertEqual("RATE_LIMITED", limited["error"]["code"])

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

    def test_stale_rooms_expire(self):
        now = [100.0]
        store = LobbyStore(now=lambda: now[0])
        payload = {
            "display_name": "ExpiryHost",
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
        message = store.send_message(guest, room["room_id"], {"kind": "hello"})
        self.assertEqual("Hello!", message["text"])

    def test_auth_and_input_validation_fail_closed(self):
        missing = self.request("GET", "/v1/rooms", expected=401)
        self.assertEqual("AUTH_REQUIRED", missing["error"]["code"])
        rejected = self.request(
            "POST",
            "/v1/sessions",
            {
                "display_name": "bad/name",
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

#!/usr/bin/env python3
"""Small, dependency-free public-lobby service for MeleePad.

This service discovers compatible traversal rooms; it never proxies gameplay.
Run it behind an HTTPS reverse proxy outside local development.
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import re
import secrets
import socketserver
import threading
import time
import urllib.parse
import uuid
from collections import defaultdict, deque
from dataclasses import dataclass, field
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Callable


MAX_BODY_BYTES = 8 * 1024
SESSION_TTL_SECONDS = 2 * 60 * 60
ROOM_TTL_SECONDS = 45
RESERVATION_TTL_SECONDS = 20
MAX_ROOMS = 500
MAX_MESSAGES_PER_ROOM = 50
QUICK_MESSAGE_LIMIT = 4
QUICK_MESSAGE_WINDOW_SECONDS = 10
GENERAL_REQUEST_LIMIT = 120
GENERAL_REQUEST_WINDOW_SECONDS = 60

PROTOCOL_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
VERSION_PATTERN = re.compile(r"^[A-Za-z0-9.+-]{1,32}$")
GAME_PATTERN = re.compile(r"^[A-Z0-9-]{1,24}$")
ROOM_CODE_PATTERN = re.compile(r"^[0-9a-f]{8}$")
DISPLAY_NAME_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 ._-]{0,19}$")
REGIONS = {"auto", "north-america", "europe", "asia", "oceania", "other"}
ROOM_STATES = {"waiting", "in_game"}
REPORT_REASONS = {"offensive_name", "harassment", "spam", "other"}
QUICK_MESSAGES = {
    "hello": "Hello!",
    "ready": "Ready when you are.",
    "moment": "One moment, please.",
    "good_luck": "Good luck—have fun!",
    "good_games": "Good games!",
    "rematch": "Rematch?",
}
BLOCKED_NAME_FRAGMENTS = {
    "nigger",
    "faggot",
    "kike",
}


class LobbyError(Exception):
    def __init__(self, status: int, code: str, message: str):
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message


@dataclass
class Session:
    session_id: str
    token_hash: bytes
    display_name: str
    app_version: str
    build: str
    protocol: str
    game_id: str
    game_revision: str
    expires_at: float
    blocked_sessions: set[str] = field(default_factory=set)


@dataclass
class Room:
    room_id: str
    owner_session_id: str
    traversal_code: str
    region: str
    created_at: float
    last_heartbeat: float
    state: str = "waiting"
    reservations: dict[str, float] = field(default_factory=dict)
    messages: deque[dict[str, Any]] = field(
        default_factory=lambda: deque(maxlen=MAX_MESSAGES_PER_ROOM)
    )
    next_message_id: int = 1


class SlidingWindowLimiter:
    def __init__(self, limit: int, window_seconds: float):
        self.limit = limit
        self.window_seconds = window_seconds
        self._events: dict[str, deque[float]] = defaultdict(deque)

    def allow(self, key: str, now: float) -> bool:
        events = self._events[key]
        cutoff = now - self.window_seconds
        while events and events[0] <= cutoff:
            events.popleft()
        if len(events) >= self.limit:
            return False
        events.append(now)
        return True


class LobbyStore:
    def __init__(self, now: Callable[[], float] = time.time):
        self._now = now
        self._lock = threading.RLock()
        self._sessions: dict[str, Session] = {}
        self._token_sessions: dict[bytes, str] = {}
        self._rooms: dict[str, Room] = {}
        self._reports: deque[dict[str, Any]] = deque(maxlen=1000)
        self._quick_message_limits = SlidingWindowLimiter(
            QUICK_MESSAGE_LIMIT, QUICK_MESSAGE_WINDOW_SECONDS
        )
        self._request_limits = SlidingWindowLimiter(
            GENERAL_REQUEST_LIMIT, GENERAL_REQUEST_WINDOW_SECONDS
        )

    def _purge(self) -> None:
        now = self._now()
        expired_sessions = [
            session_id
            for session_id, session in self._sessions.items()
            if session.expires_at <= now
        ]
        for session_id in expired_sessions:
            session = self._sessions.pop(session_id)
            self._token_sessions.pop(session.token_hash, None)
        expired_rooms: list[str] = []
        for room_id, room in self._rooms.items():
            room.reservations = {
                session_id: expiry
                for session_id, expiry in room.reservations.items()
                if expiry > now and session_id in self._sessions
            }
            if (
                room.owner_session_id not in self._sessions
                or room.last_heartbeat + ROOM_TTL_SECONDS <= now
            ):
                expired_rooms.append(room_id)
        for room_id in expired_rooms:
            self._rooms.pop(room_id, None)

    @staticmethod
    def _token_hash(token: str) -> bytes:
        return hashlib.sha256(token.encode("ascii")).digest()

    @staticmethod
    def _required_string(
        payload: dict[str, Any], key: str, pattern: re.Pattern[str]
    ) -> str:
        value = payload.get(key)
        if not isinstance(value, str) or not pattern.fullmatch(value):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_FIELD", key)
        return value

    @staticmethod
    def _reject_unknown(payload: dict[str, Any], allowed: set[str]) -> None:
        if not payload.keys() <= allowed:
            raise LobbyError(
                HTTPStatus.BAD_REQUEST,
                "UNKNOWN_FIELD",
                "Request contains an unsupported field.",
            )

    @staticmethod
    def _validate_display_name(payload: dict[str, Any]) -> str:
        name = LobbyStore._required_string(payload, "display_name", DISPLAY_NAME_PATTERN)
        folded = name.casefold().replace(" ", "")
        if any(fragment in folded for fragment in BLOCKED_NAME_FRAGMENTS):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "NAME_REJECTED", "display_name")
        return name

    def create_session(self, payload: dict[str, Any]) -> dict[str, Any]:
        self._reject_unknown(
            payload,
            {
                "display_name",
                "app_version",
                "build",
                "protocol",
                "game_id",
                "game_revision",
            },
        )
        display_name = self._validate_display_name(payload)
        app_version = self._required_string(payload, "app_version", VERSION_PATTERN)
        build = self._required_string(payload, "build", VERSION_PATTERN)
        protocol = self._required_string(payload, "protocol", PROTOCOL_PATTERN)
        game_id = self._required_string(payload, "game_id", GAME_PATTERN)
        game_revision = self._required_string(payload, "game_revision", VERSION_PATTERN)
        token = secrets.token_urlsafe(32)
        session_id = uuid.uuid4().hex
        expires_at = self._now() + SESSION_TTL_SECONDS
        session = Session(
            session_id=session_id,
            token_hash=self._token_hash(token),
            display_name=display_name,
            app_version=app_version,
            build=build,
            protocol=protocol,
            game_id=game_id,
            game_revision=game_revision,
            expires_at=expires_at,
        )
        with self._lock:
            self._purge()
            self._sessions[session_id] = session
            self._token_sessions[session.token_hash] = session_id
        return {
            "session_id": session_id,
            "token": token,
            "expires_in": SESSION_TTL_SECONDS,
        }

    def authenticate(self, token: str | None) -> Session:
        if not token or len(token) > 128:
            raise LobbyError(HTTPStatus.UNAUTHORIZED, "AUTH_REQUIRED", "Sign in again.")
        candidate_hash = self._token_hash(token)
        with self._lock:
            self._purge()
            session_id = self._token_sessions.get(candidate_hash)
            if session_id is None:
                raise LobbyError(HTTPStatus.UNAUTHORIZED, "AUTH_INVALID", "Session expired.")
            session = self._sessions.get(session_id)
            if session is None or not hmac.compare_digest(
                session.token_hash, candidate_hash
            ):
                raise LobbyError(HTTPStatus.UNAUTHORIZED, "AUTH_INVALID", "Session expired.")
            return session

    @staticmethod
    def _compatibility(host: Session, guest: Session) -> tuple[bool, str]:
        checks = (
            (host.game_id, guest.game_id, "Different game"),
            (host.game_revision, guest.game_revision, "Different game revision"),
            (host.protocol, guest.protocol, "Different netplay protocol"),
            (host.app_version, guest.app_version, "Different MeleePad version"),
            (host.build, guest.build, "Different MeleePad build"),
        )
        for expected, actual, reason in checks:
            if expected != actual:
                return False, reason
        return True, "Compatible"

    def _players(self, room: Room) -> int:
        return 1 + len(room.reservations)

    def create_room(self, session: Session, payload: dict[str, Any]) -> dict[str, Any]:
        self._reject_unknown(payload, {"traversal_code", "region"})
        traversal_code = self._required_string(
            payload, "traversal_code", ROOM_CODE_PATTERN
        )
        region = payload.get("region", "auto")
        if region not in REGIONS:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_REGION", "region")
        now = self._now()
        room = Room(
            room_id=uuid.uuid4().hex,
            owner_session_id=session.session_id,
            traversal_code=traversal_code,
            region=region,
            created_at=now,
            last_heartbeat=now,
        )
        with self._lock:
            self._purge()
            if len(self._rooms) >= MAX_ROOMS:
                raise LobbyError(
                    HTTPStatus.SERVICE_UNAVAILABLE, "LOBBY_FULL", "Try again shortly."
                )
            for existing_id, existing in list(self._rooms.items()):
                if existing.owner_session_id == session.session_id:
                    self._rooms.pop(existing_id, None)
            self._rooms[room.room_id] = room
        return {"room_id": room.room_id, "heartbeat_after": 15}

    def room_list(self, guest: Session) -> dict[str, Any]:
        with self._lock:
            self._purge()
            rooms: list[dict[str, Any]] = []
            for room in sorted(
                self._rooms.values(), key=lambda item: item.created_at, reverse=True
            ):
                if room.owner_session_id in guest.blocked_sessions:
                    continue
                host = self._sessions.get(room.owner_session_id)
                if host is None:
                    continue
                compatible, reason = self._compatibility(host, guest)
                rooms.append(
                    {
                        "room_id": room.room_id,
                        "host_id": host.session_id,
                        "host": host.display_name,
                        "region": room.region,
                        "players": self._players(room),
                        "capacity": 2,
                        "state": room.state,
                        "app_version": host.app_version,
                        "build": host.build,
                        "protocol": host.protocol,
                        "game_id": host.game_id,
                        "game_revision": host.game_revision,
                        "compatible": compatible,
                        "compatibility": reason,
                    }
                )
            return {"rooms": rooms, "server_time": int(self._now())}

    def heartbeat(
        self, session: Session, room_id: str, payload: dict[str, Any]
    ) -> dict[str, Any]:
        self._reject_unknown(payload, {"state"})
        state = payload.get("state", "waiting")
        if state not in ROOM_STATES:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_STATE", "state")
        with self._lock:
            self._purge()
            room = self._owned_room(session, room_id)
            room.last_heartbeat = self._now()
            room.state = state
            return {"ok": True, "players": self._players(room)}

    def join_room(self, session: Session, room_id: str) -> dict[str, Any]:
        with self._lock:
            self._purge()
            room = self._room(room_id)
            host = self._sessions.get(room.owner_session_id)
            if host is None:
                raise LobbyError(HTTPStatus.NOT_FOUND, "ROOM_GONE", "Room expired.")
            if room.owner_session_id in session.blocked_sessions:
                raise LobbyError(HTTPStatus.NOT_FOUND, "ROOM_GONE", "Room unavailable.")
            compatible, reason = self._compatibility(host, session)
            if not compatible:
                raise LobbyError(HTTPStatus.CONFLICT, "INCOMPATIBLE", reason)
            if room.state != "waiting":
                raise LobbyError(HTTPStatus.CONFLICT, "GAME_RUNNING", "Match started.")
            if session.session_id != room.owner_session_id:
                if (
                    session.session_id not in room.reservations
                    and self._players(room) >= 2
                ):
                    raise LobbyError(HTTPStatus.CONFLICT, "ROOM_FULL", "Room is full.")
                room.reservations[session.session_id] = (
                    self._now() + RESERVATION_TTL_SECONDS
                )
            return {
                "room_id": room.room_id,
                "traversal_code": room.traversal_code,
                "host": host.display_name,
                "reservation_expires_in": RESERVATION_TTL_SECONDS,
            }

    def heartbeat_member(self, session: Session, room_id: str) -> dict[str, Any]:
        with self._lock:
            self._purge()
            room = self._room(room_id)
            if room.owner_session_id == session.session_id:
                raise LobbyError(
                    HTTPStatus.BAD_REQUEST, "HOST_USES_ROOM_HEARTBEAT", "Invalid role."
                )
            if session.session_id not in room.reservations:
                raise LobbyError(
                    HTTPStatus.FORBIDDEN, "ROOM_ACCESS", "Join the room again."
                )
            room.reservations[session.session_id] = self._now() + ROOM_TTL_SECONDS
            return {"ok": True, "heartbeat_after": 15}

    def leave_room(self, session: Session, room_id: str) -> dict[str, Any]:
        with self._lock:
            room = self._room(room_id)
            room.reservations.pop(session.session_id, None)
            return {"ok": True}

    def delete_room(self, session: Session, room_id: str) -> dict[str, Any]:
        with self._lock:
            self._owned_room(session, room_id)
            self._rooms.pop(room_id, None)
            return {"ok": True}

    def send_message(
        self, session: Session, room_id: str, payload: dict[str, Any]
    ) -> dict[str, Any]:
        self._reject_unknown(payload, {"kind"})
        kind = payload.get("kind")
        if kind not in QUICK_MESSAGES:
            raise LobbyError(
                HTTPStatus.BAD_REQUEST,
                "INVALID_MESSAGE",
                "Only preset quick-chat messages are accepted.",
            )
        now = self._now()
        with self._lock:
            self._purge()
            room = self._room(room_id)
            self._require_membership(session, room)
            if not self._quick_message_limits.allow(session.session_id, now):
                raise LobbyError(
                    HTTPStatus.TOO_MANY_REQUESTS,
                    "RATE_LIMITED",
                    "Wait before sending another message.",
                )
            message = {
                "id": room.next_message_id,
                "sender_id": session.session_id,
                "sender": session.display_name,
                "kind": kind,
                "text": QUICK_MESSAGES[kind],
                "created_at": int(now),
            }
            room.next_message_id += 1
            room.messages.append(message)
            return message

    def messages(self, session: Session, room_id: str, after: int) -> dict[str, Any]:
        with self._lock:
            self._purge()
            room = self._room(room_id)
            self._require_membership(session, room)
            messages = [
                message
                for message in room.messages
                if message["id"] > after
                and message["sender_id"] not in session.blocked_sessions
            ]
            return {"messages": messages}

    def block(self, session: Session, payload: dict[str, Any]) -> dict[str, Any]:
        self._reject_unknown(payload, {"session_id"})
        target = payload.get("session_id")
        if not isinstance(target, str) or not re.fullmatch(r"[0-9a-f]{32}", target):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_TARGET", "session_id")
        if target == session.session_id:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_TARGET", "session_id")
        with self._lock:
            session.blocked_sessions.add(target)
        return {"ok": True}

    def report(self, session: Session, payload: dict[str, Any]) -> dict[str, Any]:
        self._reject_unknown(payload, {"session_id", "room_id", "reason"})
        target = payload.get("session_id")
        room_id = payload.get("room_id")
        reason = payload.get("reason")
        if not isinstance(target, str) or not re.fullmatch(r"[0-9a-f]{32}", target):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_TARGET", "session_id")
        if not isinstance(room_id, str) or not re.fullmatch(r"[0-9a-f]{32}", room_id):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_ROOM", "room_id")
        if reason not in REPORT_REASONS:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_REASON", "reason")
        with self._lock:
            self._reports.append(
                {
                    "reporter": session.session_id,
                    "target": target,
                    "room_id": room_id,
                    "reason": reason,
                    "created_at": int(self._now()),
                }
            )
            session.blocked_sessions.add(target)
        return {"accepted": True}

    def allow_request(self, key: str) -> bool:
        with self._lock:
            return self._request_limits.allow(key, self._now())

    def _room(self, room_id: str) -> Room:
        room = self._rooms.get(room_id)
        if room is None:
            raise LobbyError(HTTPStatus.NOT_FOUND, "ROOM_GONE", "Room expired.")
        return room

    def _owned_room(self, session: Session, room_id: str) -> Room:
        room = self._room(room_id)
        if room.owner_session_id != session.session_id:
            raise LobbyError(HTTPStatus.FORBIDDEN, "HOST_ONLY", "Host access required.")
        return room

    @staticmethod
    def _require_membership(session: Session, room: Room) -> None:
        if (
            room.owner_session_id != session.session_id
            and session.session_id not in room.reservations
        ):
            raise LobbyError(HTTPStatus.FORBIDDEN, "ROOM_ACCESS", "Join the room first.")


class LobbyHTTPServer(ThreadingHTTPServer):
    daemon_threads = True
    request_queue_size = 128

    def __init__(self, address: tuple[str, int], store: LobbyStore):
        super().__init__(address, LobbyHandler)
        self.store = store

    def server_bind(self) -> None:
        # HTTPServer performs a reverse-DNS lookup during bind. It is not used
        # by this API and can stall startup on hosts without working DNS.
        socketserver.TCPServer.server_bind(self)
        self.server_name = str(self.server_address[0])
        self.server_port = int(self.server_address[1])


class LobbyHandler(BaseHTTPRequestHandler):
    server: LobbyHTTPServer
    # One request per connection keeps the stdlib development server bounded
    # and avoids tying up worker threads on idle keep-alive sockets.
    protocol_version = "HTTP/1.0"

    def log_message(self, _format: str, *args: Any) -> None:
        # The standard handler logs client IPs. Lobby diagnostics intentionally
        # exclude IP addresses, tokens, traversal codes, and message contents.
        return

    def _send(self, status: int, payload: dict[str, Any]) -> None:
        encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.close_connection = True
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(encoded)

    def _payload(self) -> dict[str, Any]:
        content_type = self.headers.get("Content-Type", "")
        if content_type.split(";", 1)[0].strip() != "application/json":
            raise LobbyError(
                HTTPStatus.UNSUPPORTED_MEDIA_TYPE,
                "JSON_REQUIRED",
                "Use application/json.",
            )
        raw_length = self.headers.get("Content-Length")
        try:
            length = int(raw_length or "0")
        except ValueError as error:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_LENGTH", "Invalid body.") from error
        if length <= 0 or length > MAX_BODY_BYTES:
            raise LobbyError(
                HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
                "BODY_SIZE",
                "Request body is too large.",
            )
        try:
            payload = json.loads(self.rfile.read(length))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_JSON", "Invalid JSON.") from error
        if not isinstance(payload, dict):
            raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_JSON", "Object required.")
        return payload

    def _token(self) -> str | None:
        authorization = self.headers.get("Authorization", "")
        if not authorization.startswith("Bearer "):
            return None
        return authorization[7:]

    def _session(self) -> Session:
        return self.server.store.authenticate(self._token())

    def _dispatch(self, method: str) -> None:
        client_key = self.client_address[0]
        if not self.server.store.allow_request(client_key):
            raise LobbyError(
                HTTPStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", "Try again shortly."
            )
        parsed = urllib.parse.urlsplit(self.path)
        path = parsed.path.rstrip("/") or "/"
        query = urllib.parse.parse_qs(parsed.query)
        store = self.server.store

        if method == "GET" and path == "/healthz":
            self._send(HTTPStatus.OK, {"status": "ok"})
            return
        if method == "POST" and path == "/v1/sessions":
            self._send(HTTPStatus.CREATED, store.create_session(self._payload()))
            return

        session = self._session()
        if method == "GET" and path == "/v1/rooms":
            self._send(HTTPStatus.OK, store.room_list(session))
            return
        if method == "POST" and path == "/v1/rooms":
            self._send(HTTPStatus.CREATED, store.create_room(session, self._payload()))
            return
        if method == "POST" and path == "/v1/blocks":
            self._send(HTTPStatus.OK, store.block(session, self._payload()))
            return
        if method == "POST" and path == "/v1/reports":
            self._send(HTTPStatus.ACCEPTED, store.report(session, self._payload()))
            return

        match = re.fullmatch(r"/v1/rooms/([0-9a-f]{32})/heartbeat", path)
        if match and method == "PUT":
            self._send(
                HTTPStatus.OK,
                store.heartbeat(session, match.group(1), self._payload()),
            )
            return
        match = re.fullmatch(r"/v1/rooms/([0-9a-f]{32})/join", path)
        if match and method == "POST":
            payload = self._payload()
            store._reject_unknown(payload, set())
            self._send(HTTPStatus.OK, store.join_room(session, match.group(1)))
            return
        match = re.fullmatch(r"/v1/rooms/([0-9a-f]{32})/members/me", path)
        if match and method == "DELETE":
            self._send(HTTPStatus.OK, store.leave_room(session, match.group(1)))
            return
        match = re.fullmatch(
            r"/v1/rooms/([0-9a-f]{32})/members/me/heartbeat", path
        )
        if match and method == "PUT":
            payload = self._payload()
            store._reject_unknown(payload, set())
            self._send(HTTPStatus.OK, store.heartbeat_member(session, match.group(1)))
            return
        match = re.fullmatch(r"/v1/rooms/([0-9a-f]{32})/messages", path)
        if match and method == "POST":
            self._send(
                HTTPStatus.CREATED,
                store.send_message(session, match.group(1), self._payload()),
            )
            return
        if match and method == "GET":
            try:
                after = max(0, int(query.get("after", ["0"])[0]))
            except ValueError as error:
                raise LobbyError(HTTPStatus.BAD_REQUEST, "INVALID_CURSOR", "after") from error
            self._send(HTTPStatus.OK, store.messages(session, match.group(1), after))
            return
        match = re.fullmatch(r"/v1/rooms/([0-9a-f]{32})", path)
        if match and method == "DELETE":
            self._send(HTTPStatus.OK, store.delete_room(session, match.group(1)))
            return

        raise LobbyError(HTTPStatus.NOT_FOUND, "NOT_FOUND", "Endpoint not found.")

    def _handle(self, method: str) -> None:
        try:
            self._dispatch(method)
        except LobbyError as error:
            self._send(
                error.status,
                {"error": {"code": error.code, "message": error.message}},
            )
        except (BrokenPipeError, ConnectionResetError):
            return
        except Exception:
            self._send(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                {"error": {"code": "INTERNAL", "message": "Request failed."}},
            )

    def do_GET(self) -> None:  # noqa: N802
        self._handle("GET")

    def do_POST(self) -> None:  # noqa: N802
        self._handle("POST")

    def do_PUT(self) -> None:  # noqa: N802
        self._handle("PUT")

    def do_DELETE(self) -> None:  # noqa: N802
        self._handle("DELETE")


def main() -> None:
    parser = argparse.ArgumentParser(description="MeleePad public-lobby service")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    server = LobbyHTTPServer((args.host, args.port), LobbyStore())
    print(f"MeleePad lobby listening on {args.host}:{server.server_port}")
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

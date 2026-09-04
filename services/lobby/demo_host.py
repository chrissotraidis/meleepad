#!/usr/bin/env python3
"""Publish one safe, synthetic room card for local UI development."""

from __future__ import annotations

import argparse
import json
import time
import urllib.request


def request(base: str, path: str, payload: dict, token: str | None = None) -> dict:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    operation = urllib.request.Request(
        base + path,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST" if path != "/heartbeat" else "PUT",
    )
    with urllib.request.urlopen(operation, timeout=3) as response:
        return json.load(response)


def main() -> None:
    parser = argparse.ArgumentParser(description="Publish a local demo lobby room")
    parser.add_argument("--base", default="http://127.0.0.1:8765")
    parser.add_argument("--name", default="FalconFan")
    parser.add_argument("--code", default="00000000")
    parser.add_argument("--build", default="5")
    parser.add_argument("--capacity", type=int, choices=(2, 3, 4), default=4)
    parser.add_argument(
        "--guest",
        action="append",
        default=[],
        help="add a synthetic seated player (repeat up to capacity minus one)",
    )
    args = parser.parse_args()
    session = request(
        args.base,
        "/v1/sessions",
        {
            "display_name": args.name,
            "product_id": "meleepad",
            "app_version": "0.1.0",
            "build": args.build,
            "protocol": "moderngekko-netplay-8",
            "game_id": "GALE01",
            "game_revision": "r0",
        },
    )
    room = request(
        args.base,
        "/v1/rooms",
        {
            "traversal_code": args.code,
            "region": "asia",
            "capacity": args.capacity,
        },
        session["token"],
    )
    member_tokens: list[str] = []
    for name in args.guest[: max(0, args.capacity - 1)]:
        member = request(
            args.base,
            "/v1/sessions",
            {
                "display_name": name,
                "product_id": "meleepad",
                "app_version": "0.1.0",
                "build": args.build,
                "protocol": "moderngekko-netplay-8",
                "game_id": "GALE01",
                "game_revision": "r0",
            },
        )
        request(
            args.base,
            f"/v1/rooms/{room['room_id']}/join",
            {},
            member["token"],
        )
        member_tokens.append(member["token"])
    print(
        f"Demo room active: {room['room_id']} ({1 + len(member_tokens)}/{args.capacity})",
        flush=True,
    )
    heartbeat = args.base + f"/v1/rooms/{room['room_id']}/heartbeat"
    try:
        while True:
            time.sleep(15)
            headers = {
                "Authorization": f"Bearer {session['token']}",
                "Content-Type": "application/json",
            }
            operation = urllib.request.Request(
                heartbeat,
                data=b'{"state":"waiting"}',
                headers=headers,
                method="PUT",
            )
            with urllib.request.urlopen(operation, timeout=3):
                pass
            for token in member_tokens:
                member_heartbeat = args.base + (
                    f"/v1/rooms/{room['room_id']}/members/me/heartbeat"
                )
                member_operation = urllib.request.Request(
                    member_heartbeat,
                    data=b"{}",
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    method="PUT",
                )
                with urllib.request.urlopen(member_operation, timeout=3):
                    pass
    except KeyboardInterrupt:
        print("Demo room stopped.")


if __name__ == "__main__":
    main()

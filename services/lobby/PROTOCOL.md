# Pad Lobby Protocol 1

Pad Lobby Protocol 1 (`pad-lobby-1`) is a small JSON-over-HTTPS directory
protocol for online-capable Pad game projects. The reference implementation is
`server.py`.

It coordinates discovery only. Gameplay remains peer to peer or uses the
game-specific online service selected by each app.

## Identity and compatibility

Every session declares these independent fields:

- `product_id`: app family, such as `meleepad` or `kartpad`;
- `app_version` and `build`: exact client release;
- `protocol`: that product's gameplay networking protocol;
- `game_id` and `game_revision`: exact game content compatibility;
- `display_name`: the player's bounded public name.

Room listings are scoped to the authenticated session's `product_id`. A client
cannot discover or join another product's room through `GET /v1/rooms`.

## Shared activity

`GET /v1/activity` is authenticated and returns aggregate counts for registered
products:

```json
{
  "products": [
    {
      "product_id": "meleepad",
      "display_name": "MeleePad",
      "open_rooms": 1,
      "in_game_rooms": 2,
      "players": 7
    }
  ],
  "server_time": 1788451200
}
```

Activity deliberately excludes player names, session and room IDs, chat,
connection codes, addresses, and history. Clients should hide products with no
activity and must not imply that a different product's room is joinable.

## Capabilities

`GET /v1/capabilities` is unauthenticated so clients and operators can inspect
the directory version and registered products. Unknown `product_id` values fail
closed during session creation.

## Existing room API

The reference service retains the `/v1/sessions`, `/v1/rooms`, room heartbeat,
join, member heartbeat, chat, block, and report endpoints documented by its
source and tests. Tokens and connection codes are secrets. They must never be
logged or included in public listings or aggregate activity.

## Deployment boundary

The reference server is intentionally in-memory and single-process. Loopback
HTTP is for development. Any Internet deployment requires HTTPS termination,
trusted proxy configuration, connection limits, persistent moderation and
report storage, operational monitoring, backups, and a published abuse contact.

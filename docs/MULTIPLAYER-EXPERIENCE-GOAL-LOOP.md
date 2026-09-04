# MeleePad multiplayer experience goal loop

Status: active
Started: 2026-09-04
Builds on: `MULTIPLAYER-NEXT-PASS-GOAL-LOOP.md`

## Goal

Make Online Play feel like a clear, welcoming MeleePad match night while
improving the evidence available when something fails. A first-time player
should understand the three connection choices, choose a public room size,
recognize every player and seat, and know when a match can start without having
to understand netplay terminology.

This pass stays native and small: system typography, SF Symbols, existing
network paths, bounded room chat, and structured local diagnostics. It does
not add accounts, profiles, analytics, a second gameplay transport, or a
deployed public matchmaking service.

## Definition of done

One unchanged candidate must demonstrate:

1. **Learnable setup:** plain-language copy explains Public Games, Private Room,
   Direct IP, compatibility, room size, Ready, and Start at the point of need.
2. **Optional depth:** first-time guidance and help are one tap away but do not
   slow down returning players.
3. **Match-night identity:** a consistent navy/cyan presentation, four distinct
   seat accents, named players, and explicit `YOU`/`HOST` labels make the lobby
   recognizable without relying on color alone.
4. **Useful diagnostics:** important setup, request, recovery, occupancy, Ready,
   and Start transitions are recorded as bounded structured events.
5. **Privacy by construction:** diagnostics never contain player names, room
   codes, traversal codes, IP addresses, authorization tokens, or chat text.
6. **Accessible behavior:** help controls have meaningful labels and hints,
   tappable targets remain at least 44 points, text uses Dynamic Type, and the
   complete flow remains scrollable.
7. **Regression safety:** focused diagnostics and UI source contracts, the full
   repository check, a clean iOS build, and current-build visual inspection pass.
8. **Useful public directory:** every room card explains who is seated, open
   seats, host, region, freshness, match state, exact build compatibility, and
   why Join is available or unavailable.
9. **Committed identity:** editing a player name creates a visible unconfirmed
   state; browsing, joining, and hosting require an explicit confirmation.
10. **First-class room coordination:** joined public-room members can type and
    read bounded messages, then hide or report another sender from the room.
11. **Question-led help:** the in-app FAQ and README answer which mode to use,
    what names and chat mean, how Direct IP works, and why a connection may
    fail without forcing every player through advanced details.

Passing this loop means **educational multiplayer development experience**. It
does not mean secure public matchmaking or proven four-device gameplay.

## Working loop

For each gate:

1. state the player question or support question the gate must answer;
2. add the smallest failing contract;
3. make the smallest native implementation change;
4. verify success, failure, cancellation, and large-text behavior;
5. inspect diagnostics for usefulness and forbidden data;
6. build and visually inspect the current candidate; and
7. record evidence before moving to the next gate.

If an explanation turns into a permanent wall of text, collapse it or move it
behind contextual help. If a visual flourish weakens contrast, scan order, or
Dynamic Type, remove it. If a log field cannot be proven safe, do not record it.

## Gates

### MX0 — preserve the security boundary

- Keep the public lobby disabled without an HTTPS endpoint (Simulator loopback
  remains the development exception).
- Keep Private Room and Direct IP working and visibly unencrypted.
- Never describe current public discovery as production-ready or secure.

### MX1 — teach the mental model

- Present a three-step expandable guide: choose connection, fill seats, ready
  and start.
- Provide a persistent help affordance that explains every connection method.
- Add contextual room-size help and accessibility hints on unfamiliar controls.
- Use player language first; keep traversal, UDP, and buffering in secondary
  explanations.

### MX2 — create a coherent match-night theme

- Use the existing deep navy surface with one electric-cyan Online Play accent.
- Use system icons only; do not introduce game-derived or copyrighted artwork.
- Give P1–P4 stable blue, red, orange, and green accents with visible text labels.
- Keep warnings orange/red and success meaning in text as well as color.

### MX3 — make people recognizable

- Label the nickname field as the player's visible room name.
- Show names in room cards and seat cards, with `YOU` and `HOST` badges.
- Keep nickname validation predictable and moderation controls close to public
  player listings.
- Do not persist identity beyond what the existing lobby session requires.

### MX4 — build privacy-safe support breadcrumbs

- Log only categorical routes, actions, results, status codes, durations, byte
  counts, capacities, occupancy counts, compatibility counts, and buffer mode.
- Suppress successful high-frequency heartbeat/message polling logs; retain
  failures and meaningful transitions.
- Add export-time defenses for keyed secrets and IPv4 addresses.
- Prohibit player names, room or traversal codes, addresses, tokens, and message
  contents at every online logging call site.

### MX5 — verify the complete experience

- Run the diagnostics privacy test with representative secrets and addresses.
- Run the online-play source contract and the complete repository check.
- Build the iOS Simulator target without changing the candidate.
- Inspect Public Games, expanded education, help, unavailable-service, a
  populated four-seat lobby, landscape, and Accessibility Extra Large states.
- Recheck Cancel, Refresh, Join, Create Game, Ready, Start, report, and fallback
  actions after every layout change.

### MX6 — carry the right work forward

- Keep production deployment, identity/accounts, encryption/relay design,
  operator retention, abuse operations, and four-device gameplay evidence in
  the security and physical-test gates of the prior loop.
- Use diagnostic reports to refine failure categories only after real reports
  demonstrate a recurring gap; do not add speculative telemetry.

### MX7 — complete the public-game decision card

- Show the host and every visible seated player, plus hidden and open-seat
  counts, without exposing room codes or addresses.
- Distinguish Joinable, Full, In match, and Update needed before the player taps.
- Show region, selected room size, listing freshness, app version/build, and the
  exact compatibility result.
- Explain that the host chooses rules/stage in-game and that connection quality
  is known only after joining.
- Provide per-player name reporting and keep blocked roster names out of later
  listings.

### MX8 — keep discovery current without churn

- Refresh the visible public directory every 10 seconds and retain manual
  Refresh for immediate checks.
- Do not interrupt nickname editing, create duplicate sessions, or log routine
  successful polling.
- Save the validated player name locally so returning players keep a stable
  identity; never include it in diagnostics.

### MX9 — make the player commit their visible name

- Put Confirm beside the name field and show a persistent confirmed/changed
  state.
- Pause automatic browsing while the name is being edited or unconfirmed.
- Require the exact confirmed name before Refresh, Join, or Host creates a
  lobby session.

### MX10 — make room chat feel present and safe

- Replace the buried preset menu with a visible Room Chat section, empty state,
  160-character composer, Send action, and readable message cards.
- Keep authorization per message, bounded history, rate limits, room expiry,
  text/control filtering, blocked-sender filtering, and diagnostic content
  exclusion.
- Offer Hide Player and Report Chat Message on remote messages.
- Keep public deployment closed until published contact, durable moderation,
  and response operations are real.

### MX11 — turn help into a practical FAQ

- Let players choose Public Games, Private Room, Direct IP, Names & Chat, or
  Safety & Troubleshooting instead of reading one large alert.
- Put mode-specific FAQ buttons inside Private Room and Direct IP so the answer
  is available beside the fields it explains.
- Explain Direct IP address/port, firewall, NAT, VPN, encryption, and relay
  limitations in plain language.
- Mirror the same answers in collapsible README FAQ entries.

## Current execution order

1. MX4 privacy defenses and structured lobby request events.
2. MX1 contextual education and rewritten player-facing copy.
3. MX2–MX3 themed hero, player identity, and four seat accents.
4. MX7 complete public-game cards, roster moderation, and actionable states.
5. MX8–MX9 live refresh and explicit player-name confirmation.
6. MX10 first-class bounded room chat and sender safety.
7. MX11 question-led in-app and README help.
8. MX5 focused tests, full checks, build, and visual inspection.
9. Stop at MX6; do not silently add accounts, telemetry, or deploy a service.

## Progress — 2026-09-04

| Gate | Status | Evidence / remaining boundary |
|---|---|---|
| MX0 | Preserved | Existing availability, HTTPS/loopback, fallback, and unencrypted-copy boundaries remain in place. |
| MX1 | Development pass | Expandable three-step guide, global help, contextual room-size help, and control hints are implemented and present in the current-build accessibility tree. Spoken VoiceOver and physical-device review remain. |
| MX2 | Development pass | The brighter cobalt/indigo hero, quiet controller watermark, four-seat palette, stronger primary actions, and stable P1–P4 accents use system assets and passed current-build inspection. The hero now compacts inside a match room so the active controls take priority. |
| MX3 | Development pass | The visible-name explanation plus `YOU` and `HOST` seat badges are implemented and visible in a current-build four-seat host lobby. Multi-device identity order remains to be exercised. |
| MX4 | Development pass | Categorical client/UI events, poll suppression, keyed-secret/IP redaction, and removal of room-code tracing passed privacy tests and a live runtime-log inspection. |
| MX5 | Development pass | Focused tests, 18 service tests, the full repository check, Release Simulator and signed iPhoneOS builds, current-build help/setup/public-list/room-chat/four-seat states, Accessibility Extra Large inspection, and an in-place physical-iPad launch to 59.9 FPS passed. Spoken VoiceOver, controller focus, and a real multi-device match remain. |
| MX6 | Open boundary | Production service security and four-device gameplay evidence remain separate future gates. |
| MX7 | Development pass | The current build shows the bounded roster, open seats, freshness, joinability, match/build detail, disabled-state reasons, rules/connection expectations, and per-player safety actions. Service coverage verifies full rooms, match state, and roster-member blocking/reporting. |
| MX8 | Development pass | Ten-second refresh, manual refresh, and validated on-device nickname persistence are implemented. A 12-second unchanged-directory run preserved the existing controls and accessibility tree, and routine successful polling produced no UI or client log churn. Physical-device lifecycle review remains. |
| MX9 | Development pass | A confirmed name now reads as identity instead of a disabled button. Editing reveals Confirm Name, disables discovery actions, and clearly returns to the unconfirmed state. The interaction passed normal and Accessibility Extra Large inspection. |
| MX10 | Development pass | Two authenticated room members exchanged typed messages in the current build. Left/right conversation bubbles, the 160-character composer, focus treatment, live count, empty/sent/received states, rate limits, filtering, and remote safety action passed simulator and accessibility-tree inspection. Production moderation operations remain open. |
| MX11 | Development pass | Topic-based global help, contextual Private Room and Direct IP help, and three new collapsible README FAQ answers compile and pass source contracts. Spoken VoiceOver and physical-device help navigation remain. |

# Slippi IPA release readiness

Historical pre-release assessment. The subsequent public-source migration and
Preview 5 packaging are documented in [the release notes](releases/v0.1.0-preview.5.md).

Build 26 has owner-reported successful Unranked play corroborated by two normal game-end reports. Repeated earlier failures remain relevant; instrumentation was added, not a proven root-cause repair. Ranked, Direct, Teams and Party are admitted by the host policy but do not yet have equivalent real-service acceptance. The latest session contains only Unranked searches. Missing/disabled menu options and post-selection service errors must be distinguished before assigning the cause.

The latest published GitHub release is Preview 4, build 18, with an unsigned module-free IPA. Its release notes explicitly say it is not playable as downloaded, ISO import alone is insufficient, and it does not contain Slippi rollback. The current private device build is materially different: it contains the owner's ISO/extracted game data, private generated modules and a development provisioning profile. Do not upload that private bundle as a public release asset.

The existing public package script rejects those private inputs and still checks for build 18. It needs a new candidate version, clean staged public inputs and updated audit/release metadata. Merely changing the expected build number does not make the public package independently usable. Recipients need a working, documented route to generate/provision compatible native Slippi modules from their own game data and sign their app. The clean source build must include the now-active private C++ integration and exact dependencies, not rely on an ignored development overlay or local retained archives. Corresponding source and notices must match the binary.

For a tonight preview, describe only the acceptance actually established: experimental Unranked on the tested iPad. Do not advertise Ranked/Teams/Party as verified or claim the disconnect cause is fixed. Before publishing, validate the recipient setup and upgrade path, preserve account/import/save state, audit the exact archive, and publish matching source/provenance and checksums. A private tester IPA and a public downloadable standalone update have different packaging requirements; the working owner build alone does not establish the latter.

No new release asset was published by this readiness check. Logs remain active on build 26.

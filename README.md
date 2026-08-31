# Silent Aim: UI Edition

Use `silent-aim-ui.lua`. This is a separate upgrade of the script pasted in the conversation, not a replacement for the workspace's existing `silent-aim.lua`. Existing workspace files were left unchanged.

## Start

Rejoin the Roblox experience to clear previously executed scripts, then run this edition once. It starts disabled. The user reported that the pasted baseline redirected shots in their setup; this revised edition has not been tested in Roblox or Xeno.

- **Right Alt:** toggle targeting. The same control is available in the Control tab and status card.
- **Right Shift:** show or hide the control window. The status card remains available independently.
- **End:** disable this edition and remove its interface, drawings and event listeners.
- **Diagnostics:** view recent events, enable console logging, optionally log target changes, or print a snapshot.

The status card is visible only to the local player. ACTIVE means targeting is enabled and hook installation returned without an error. It does not certify that a weapon uses the selected method, that native hooks behave correctly, or that the server accepted a hit. ERROR reports hook installation or observed target-selection errors.

## Changes

- Navy-and-teal theme with Control, Visuals, Profiles and Diagnostics tabs.
- Persistent, width-adaptive status card with enable and menu buttons.
- Method, selected target and equipped Tool information. A missing Tool does not disable targeting; some custom weapons do not use Tools.
- Synchronized toggle state and exported settings. The original undefined `Settings` export is corrected.
- Bounded event history, optional console output and target-change logging, and error notifications.
- Profile name validation and list refresh. Existing per-place profile storage is retained. Loading a profile leaves targeting disabled.
- Cleanup for this edition's UI, drawings and listeners. Hooks remain installed but disabled; rejoin for a clean hook state.
- No comments in the delivered Lua file.

## Preserved implementation and limits

The target-selection helpers, probability function and both hook bodies match the pasted baseline after comment removal. This is a UI upgrade, not a rewrite of weapon interception. Its original method options, prediction behavior, visibility implementation, ray-length behavior and other targeting quirks remain. In particular, the pasted visibility routine can error because it includes character objects among cast points. This edition reports an observed targeting error and disables targeting rather than continuing to show ACTIVE.

The exact original loader for [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib/blob/main/Library.lua) is retained and runs before hook installation. The delivered file therefore downloads and executes that remote UI library when the user runs it. The dependency is not vendored or pinned and can change. It was inspected for the UI APIs used here, but not executed or comprehensively security-audited. Original `Drawing` and profile-filesystem dependencies are also retained.

Keeping the loader does not establish that it supplies missing executor hooks. This edition makes no compatibility or server-hit guarantee. Running alongside older scripts may leave other targeting behavior active even after unloading this edition.

Include the existing `LICENSE` file when redistributing this derivative. Original targeting attribution: Averiias, Stefanuk12 and xaxa.

## Verification

Run `node tests/ui-run.mjs` using the workspace's installed development dependencies.

Checks cover Luau compilation, comment-free source, unchanged targeting-code hashes, toggle synchronization, status labels, visual controls, profile validation and disabled loading, observer errors, unload cleanup, and complete/partial hook-installation failures. Seven behavior scenarios run against mocked Roblox and Linoria APIs. The tests do not execute the remote UI library.

The pre-existing `npm test` suite remains unchanged and checks the separate `silent-aim.lua`, not this UI edition.

Actual rendering, native executor hooks, weapon compatibility, damage and server-accepted hits remain unverified. Test those in Roblox; use the Diagnostics tab to capture any new errors.

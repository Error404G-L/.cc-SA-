

## Start

Rejoin the Roblox experience to clear previously executed scripts, then run this edition once. It starts disabled. The user reported that the pasted baseline redirected shots in their setup; this revised edition has not been tested in Roblox or Xeno.
Fully close and reopen Roblox to clear previously executed scripts, then run this edition once. It automatically enables targeting after hook initialization succeeds. Set `AutoEnableOnStart = false` near the top to opt out. Missing APIs or failed installation still produce ERROR and leave targeting disabled. The user reported that the pasted baseline redirected shots in their setup; this revised edition has not been tested in Roblox or Xeno.

- **Right Alt:** toggle targeting. The same control is available in the Control tab and status card.
- **Right Shift:** show or hide the control window. The status card remains available independently.
- **End:** disable this edition and remove its interface, drawings and event listeners.
- **Diagnostics:** view recent events, enable console logging, optionally log target changes, or print a snapshot.

The status card is visible only to the local player. ACTIVE means targeting is enabled and hook installation returned without an error. It does not certify that a weapon uses the selected method, that native hooks behave correctly, or that the server accepted a hit. ERROR reports hook installation or observed target-selection errors.
The status card is visible only to the local player. ACTIVE means targeting is enabled, required API names resolve to functions, and hook installation returned callable originals without an error. It does not certify that a weapon uses the selected method, that native hooks behave correctly, or that the server accepted a hit. ERROR reports hook installation or observed target-selection errors.

## Changes

- Profile name validation and list refresh. Existing per-place profile storage is retained. Loading a profile leaves targeting disabled.
- Cleanup for this edition's UI, drawings and listeners. Hooks remain installed but disabled; rejoin for a clean hook state.
- No comments in the delivered Lua file.
- Automatic activation only after successful hook initialization.
- Duplicate-execution guard to prevent this revision from stacking hooks in the same shared environment, including after unload. Restart Roblox to run it again. This cannot detect copies of earlier scripts that lack the guard or scripts running in another environment.

## Stability revision and limits

After the user reported a Roblox crash, the inherited hooks and helpers received focused fixes. They are no longer byte-for-byte identical to the original paste:

## Preserved implementation and limits
- Mouse X/Y and unrelated properties now delegate directly to the original getter; they no longer read the same property recursively from inside its hook.
- Mouse UnitRay uses an original CFrame origin's Position and a Vector3 unit direction, with a zero-distance fallback.
- Unrelated or disabled namecalls return before random chance calculation and target selection.
- Visibility casts now contain only Vector3 positions, with characters in the ignore list; absent characters and cameras are handled.
- Screen projection uses the current camera, and zero-distance ray directions do not normalize a zero vector.

The target-selection helpers, probability function and both hook bodies match the pasted baseline after comment removal. This is a UI upgrade, not a rewrite of weapon interception. Its original method options, prediction behavior, visibility implementation, ray-length behavior and other targeting quirks remain. In particular, the pasted visibility routine can error because it includes character objects among cast points. This edition reports an observed targeting error and disables targeting rather than continuing to show ACTIVE.
The original method options, prediction behavior, probability function and 1,000-stud redirected-ray behavior remain. These changes address identifiable code defects, but they do not establish the cause of the user's native Roblox crash. Lua error handling cannot reliably recover a native executor/client crash or restore a hook whose executor failed to return its original function. If Roblox crashes again, stop testing this revision and preserve the final console message or crash log before another run.

The exact original loader for [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib/blob/main/Library.lua) is retained and runs before hook installation. The delivered file therefore downloads and executes that remote UI library when the user runs it. The dependency is not vendored or pinned and can change. It was inspected for the UI APIs used here, but not executed or comprehensively security-audited. Original `Drawing` and profile-filesystem dependencies are also retained.


Run `node tests/ui-run.mjs` using the workspace's installed development dependencies.

Checks cover Luau compilation, comment-free source, unchanged targeting-code hashes, toggle synchronization, status labels, visual controls, profile validation and disabled loading, observer errors, unload cleanup, and complete/partial hook-installation failures. Seven behavior scenarios run against mocked Roblox and Linoria APIs. The tests do not execute the remote UI library.
Checks cover Luau compilation, comment-free source, the unchanged probability-function hash, automatic activation, toggle synchronization, status labels, visual controls, profile validation and disabled loading, observer errors, unload cleanup, failed API checks, invalid hook returns, complete/partial hook-installation failures, duplicate execution, mouse coordinate delegation, UnitRay types, visibility arguments, and unrelated namecall pass-through. Fourteen behavior scenarios run against mocked Roblox and Linoria APIs. The tests do not execute the remote UI library.

The pre-existing `npm test` suite remains unchanged and checks the separate `silent-aim.lua`, not this UI edition.

Actual rendering, native executor hooks, weapon compatibility, damage and server-accepted hits remain unverified. Test those in Roblox; use the Diagnostics tab to capture any new errors.

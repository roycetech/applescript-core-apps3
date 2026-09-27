# Agent guide — applescript-core-apps3

This repository holds **third-party app wrappers** and related AppleScript libraries. It depends on [applescript-core](https://github.com/roycetech/applescript-core) (`core/*` script libraries, build tooling, decorators, spot tests).

When editing or adding `.applescript` files here, follow the conventions below.

## Naming

Use **full, descriptive names**. Do not shorten or abbreviate identifiers (variables, handler parameters, repeat variables) unless the name is already an established project term (for example `sut` in spot tests meaning “system under test”).

| Avoid | Prefer | Notes |
|--------|--------|--------|
| `container` | `uiContainer` | `container` is reserved in AppleScript; use `uiContainer` for a UI element subtree being searched or traversed. |
| `st` | `nextStaticText` | In `repeat with … in static texts`, use `nextStaticText` (not bare `staticText`—ambiguous with the element type). |
| `g`, `el`, `btn` | `nextGroup`, `nextElement`, `nextButton` | Use a `next…` prefix for repeat variables; spell out the role. |
| `tmp`, `res` | `temporaryValue`, `handlerResult` | Unless matching an existing handler return pattern in the same file. |

For **`repeat with` loops** over UI collections, name the loop variable `next…` plus the element kind (`nextStaticText`, `nextGroup`, `nextButton`, and so on). Do not reuse the bare accessibility class name as the variable name.

**Examples**

```applescript
-- Prefer
on findStaticTextByLabel(uiContainer, wantedLabel)
	tell application "System Events" to tell process "Cursor"
		repeat with nextStaticText in static texts of uiContainer
			set textValue to value of nextStaticText
			if textValue is missing value then set textValue to name of nextStaticText
			if textValue is wantedLabel then return contents of nextStaticText
		end repeat
		repeat with nextGroup in groups of uiContainer
			set found to my findStaticTextByLabel(nextGroup, wantedLabel)
			if found is not missing value then return found
		end repeat
	end tell
	missing value
end findStaticTextByLabel

-- Avoid
on findLabel(container, wanted)
	repeat with st in static texts of container
		...
	end repeat
end findLabel
```

Handler names may use a leading underscore for private helpers (for example `_findPlanStaticText`) when that matches the surrounding file.

## AppleScript and UI automation

- **Electron apps** (Cursor, Claude, VS Code, Chrome): prefer **label- or description-based** lookup (`whose`, recursive search under `uiContainer`, or `entire contents`) over long fixed `group N` chains; layout indices change between app versions.
- **Clicks in web content**: this project often uses `core/cliclick` (`lclick` / `leftClick`) on the UI element reference, not only `click` in System Events.
- **Cursor**: main web root is commonly  
  `UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window`  
  (see `getHtmlContent()` in Cursor decorators). Dialogs and sheets may need `window 1` or `sheet 1 of window 1` per file headers in `cursor.applescript`.
- Reuse existing helpers (`core/ui-util`, decorator modules, `getHtmlContent`, spot-check cases) before adding parallel traversal logic.
- **`use scripting additions` is required as soon as the file has any `use <name> : script "..."` import.** Without any such import, `scripting additions` terminology (`do shell script`, `display dialog`, and the like) is implied automatically — you don't need to declare it. But the moment a file adds even one `use ... : script "..."` line, that implicit availability goes away, and any use of `do shell script` / `display dialog` / other scripting-additions terms elsewhere in that same file will fail to compile (a confusing, unrelated-looking parse error, not an obvious "missing scripting additions" message) unless you add `use scripting additions` explicitly, typically as the first `use` line. If a file already has library imports and needs a scripting-additions term, add the line — don't chase the compile error as if it were something else.

## Project structure

- **`App Wrappers/<App>/<version>/`**: app-specific libraries (`*.applescript`), often split into `dec-*` decorators composed from the main `new()` handler.
- **Build**: `@Build` comments point at `./scripts/build-lib.sh 'App Wrappers/...'`.
- **Spot tests**: many scripts define `spotCheck()` when run from Script Editor, Script Debugger, or `osascript`.
- **Scratch**: `scratch.applescript` is for local experiments; do not treat it as production API.

## Change discipline

- Match **existing style** in the file you edit (headers, logging via `core/logger-factory`, `tell` structure, decorator `property parent : mainScript`).
- Keep diffs **minimal**; do not refactor unrelated wrappers.
- Do not create git commits unless the user asks.
- **`@Change Logs` entries are for the file's real history, not your scratchpad.** While iterating live against a running app (trying a fix, testing it, finding it wrong, trying again), do not add a change log line for every attempt — that's dev-cycle noise, not a change worth recording, and it bloats every future read of the file (more tokens per query, for entries that were never even verified). Add **one entry** once a fix is actually verified working, describing the final state, not the trail of attempts it took to get there. If you're unsure whether something is verified yet, don't log it yet.

## Commits and PRs

Follow the user’s git safety rules: no config changes, no force-push to main, commit only when requested, use HEREDOC commit messages that explain **why**.

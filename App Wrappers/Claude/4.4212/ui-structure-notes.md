# Claude 4.4212 — UI structure notes

Reference notes for `claude.applescript`, captured live against a running
Claude desktop app on 2026-11-02 — **in an unusual way**: the window being
automated was this very Claude Code conversation's own Claude desktop window
(and, across the session, more than one of the user's open tabs), since
that's what was available to test against. Expect the exact indices below to
need re-deriving sooner than usual as a result — this project's explicit
choice for this file is speed over reliability (see "Design choice" below).

## Known-good anchors (don't change without re-verifying)

- `getHtmlContent()` → `UI element 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of front window`.
  Unchanged from Claude 1.4; still resolves the Electron content root (AXWebArea).
- `getSidebarUI()` → `group 1 of group 1 of group 1 of group 1 of group 1 of htmlContent`.
  Unchanged from Claude 1.4; still resolves.
- `MAIN_CONTENT_PATH` (in `_getMainContent()`, used only by `switchModel()`'s
  dropdown-menu scan) → `{1, 1, 1}`, applied as `group (item N) of ... of
  htmlContent`. Verified stable across 5+ separate derivations, including
  after sending messages and after the DOM grew from ~380 to ~780 elements.

## Known-broken (why this file exists)

Claude 1.4's `getPromptUI()`/`_getMainContent()`/`_getModelTrigger()` walked a
**fixed chain of "item 1 of AXChildren"** from `getHtmlContent()`, assuming
the "main" landmark (and everything under it) was always the first child at
every level. On this build it isn't — at one level it's the 4th of 6 siblings
(the other 5 are mostly `group`, one is `status`) — so that chain silently
landed on an unrelated branch and both handlers always returned
`missing value`.

Also broken, unrelated: `spotCheck()` called `sut's getCurrentProjectPath()`,
a handler that was never defined in this file (copy-paste leftover from the
Cursor/Sublime wrapper template, which do define it) — every spot-test case
failed before reaching its own logic. Fixed by deleting that call.

## Design choice: full hardcoded candidate paths, no fallback search

`getPromptUI()` and `_getModelTrigger()` each resolve via a short list of
*full* index paths from `getHtmlContent()` straight to the target
(`PROMPT_PATH_CANDIDATES`, `MODEL_TRIGGER_PATH_CANDIDATES`), tried in order by
`_resolveFirstMatchingPath()`. Each candidate is one compound specifier walk
using generic `UI element N` indexing (not `group N` — the final targets
aren't class `group`), so even trying every candidate costs ~0s. There is
deliberately **no** tree-search fallback when every candidate fails.

This was chosen after measuring the alternative (a bounded recursive/bulk
search scoped under "main") at anywhere from ~1s to ~30s per call, trending
slower as the conversation's own DOM grows (380 → 780+ elements over the
course of this session) — see "Why not a bounded search" below. The project
explicitly prioritizes speed and accepts that this **will** break again and
need a new candidate added; do not "fix" a failure here by reintroducing a
tree search — add another candidate instead (see recipe below).

**Known instability pattern:** of the ~26 indices in a full path, only
positions 5 and 19 have been observed to drift, and they vary
**independently** - all 4 combinations of `{2, 3} × {2, 3}` at those two
positions have been observed live, so all 4 are carried as candidates below.
Confirmed causes:

- A sibling near "main" reflows every so often with no interaction at all
  (most likely a live status/typing region) - this alone can flip position 5
  without touching position 19.
- **Sidebar shown vs. hidden** shifts position 19 (one more sibling exists
  somewhere in the tree while the sidebar is visible). Confirmed reproducible:
  toggling `hideSidebar()`/`showSidebar()` reliably flips it and back, 3/3
  samples each state.
- Don't assume the two positions move together - they were first assumed to
  (only 3 combinations were seen at first), until a 4th, independent
  combination showed up live, which is what prompted generating the full
  2×2 matrix instead of patching one combination at a time.

```applescript
property PROMPT_PATH_CANDIDATES : {{1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 7, 1, 1, 1, 1, 1}}
property MODEL_TRIGGER_PATH_CANDIDATES : {{1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 8, 1}, {1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 8, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1}}
```

**Multiple windows/tabs:** the automation always acts on `front window`
(whichever Claude window/tab is frontmost at call time, per `getHtmlContent()`
above), not a specific one. If you have several Claude windows/tabs open and
switch between them while scripting, each call can land on a different one -
treat an unexpected failure as "maybe a different window than last time" before
assuming the layout itself changed. There's currently no way to target a
specific window by name; `front window`'s title can be read via
`System Events to process "Claude"` if that's ever needed.

**Self-inflicted instability, found the hard way:** while deriving candidates
against this very Claude Code conversation's own window, a scan failed
mid-walk trying to read a `static text "1m 33s"` inside a `"Background tasks"`
group - the live elapsed-time counter for a `Bash` command still running in
this very session. Running backgrounded shell commands while deriving or
testing paths against this conversation's own window **changes the tree out
from under the scan** (that counter updates every second and the whole
"Background tasks" group can appear/disappear). If a derivation run fails
with an error mentioning "Background tasks" or a countdown-looking static
text, it's very likely this, not a real layout change - retry once nothing is
running in the background.

Other window/tab states not yet tested as candidates: split view, no project
folder attached, narrow window width. If `getPromptUI()`/`_getModelTrigger()`
fail in one of those, assume it's another layout variant and follow the
recipe below rather than guessing.

## Why not a bounded search (rejected approaches, for the record)

A few things were tried against the slow bounded-search approach before
settling on full candidate paths:

- `entire contents of <anchor>` (bulk fetch) + filter by `role description`:
  fast (~1s) for finding "main" itself, but returned **0 elements** when
  applied again starting from the found "main" element — the same WebKit
  caching quirk Claude 1.4's own comments already warned about for bulk
  queries on nested content.
- Same bulk approach filtering by `description`, `class`, or `role` instead of
  `role description`: reliable, but measured just as slow as a per-element
  recursive walk (9-18s+) — `role description` alone appears to be
  materialized for free as part of a bulk fetch; every other property costs a
  fresh ~15-20ms round-trip per element either way, so cost scales with
  however many elements are under the search root.

`_getMainContent()`'s `{1, 1, 1}` anchor + bounded search is kept, but now
only for `switchModel()`'s dropdown-menu scan (it needs a *live region* to
scan after opening the dropdown, not a single fixed target, so candidate
paths don't apply there).

## Recipe: adding a new path candidate when all current ones fail

1. Get `getHtmlContent()` (unchanged, don't rebuild this).
2. Run a small standalone discovery script that does a depth-first search for
   the target (by `description is "Prompt"`, or `description starts with
   "Model:"`), recording the child index chosen at each level:
   ```applescript
   on findPathToDescription(uielement, targetDescription, pathSoFar)
       tell application "System Events" to tell process "Claude"
           try
               if (description of uielement) is targetDescription then return pathSoFar
           end try
           try
               set kids to value of attribute "AXChildren" of uielement
           on error
               return missing value
           end try
       end tell
       repeat with i from 1 to count of kids
           set found to my findPathToDescription(contents of item i of kids, targetDescription, pathSoFar & {i})
           if found is not missing value then return found
       end repeat
       missing value
   end findPathToDescription
   ```
   (Swap the `is` comparison for `starts with` for the model trigger's
   `"Model:"` prefix.) This walk is slow (several seconds to tens of
   seconds) — that's expected and fine, it's a one-time derivation, not
   something that ships in the handler.
3. Run it 2-3 times, a few seconds apart, to confirm the result is current
   (not a stale blip).
4. Verify it resolves fast via the actual shipped mechanism before adding it:
   ```applescript
   set currentElement to htmlContent
   repeat with nextIndex in newPath
       set currentElement to UI element (contents of nextIndex) of currentElement
   end repeat
   -- should return in ~0s and have the expected description
   ```
5. Prepend the new path to the front of `PROMPT_PATH_CANDIDATES` /
   `MODEL_TRIGGER_PATH_CANDIDATES` (so it's tried first) rather than replacing
   the old ones outright — old candidates may still match in a different
   window/tab layout state.

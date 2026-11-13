# Cursor 3.27 agent panel — UI structure notes

Reference notes for `dec-cursor-agent-panel.applescript`, captured live against a
running Cursor 3.27 on 2026-10-29. These are specific to this exact Cursor build
and the current window/panel configuration — expect them to go stale the next
time Cursor updates its UI. When that happens, don't guess: re-run the discovery
recipe below against the new build and replace the values here.

## Known-good anchors (don't change these without re-verifying)

- `getHtmlContent()` → `UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window`.
  This is the Electron content root (AXWebArea). Reliable across the states tested.
- `getPromptUI()` → reliable via its existing fallback chain (known group paths,
  then the "Plan, Build and run" placeholder search, then the "Cursor Agents"
  window check). Don't touch this — it already works and other code depends on it.
- `isAgentPanelPresent()` / `isAgentPanelFocused()` → both derive from
  `getPromptUI()` only, NOT from `getAgentPanel()`/`getComposerRoot()`. Confirmed
  stable before and after the switchAgentMode rewrite below.

## Known-broken (not yet fixed)

- `getAgentPanel()` / `getComposerRoot()` / `_hasComposerChrome()` — their 3
  hardcoded candidate `group N` chains from the content root do **not** match
  the current layout at all. `_hasComposerChrome()`'s anchor (a `pop up button`
  at a fixed path) no longer exists at that path — the composer toolbar moved.
  This breaks `_getModelTrigger()`, and therefore `switchAgentModel()` and
  `switchAgentEffort()`, which still call through these. Not touched as part of
  the switchAgentMode fix (out of scope, no live verification done).

## Composer toolbar row (mode + model + effort controls)

The toolbar row (a group with several sibling `group`s — one per control) sits at:

```
MODE_TOOLBAR_PATH_CANDIDATES = {
	{1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 2, 3, 1, 1, 2, 1},  -- many agent tabs open
	{1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 3, 4, 1, 1, 2, 1}  -- a single agent tab
}
```

Confirmed live 2026-11-03: positions 18-19 flip between `2, 3` and `3, 4`
depending on whether a single agent tab or multiple agent tabs are open — not
drift, a genuine layout difference tied to tab count. Both are carried as
candidates in `MODE_TOOLBAR_PATH_CANDIDATES`, tried in order via
`_resolveModeToolbarPath()`; only add a third if a future state produces yet
another combination (per the recipe below) rather than replacing either.

Applied as `group (item N of path) of ... of htmlContent`, walking down from
`getHtmlContent()` — see `_getModeTriggerGroup()` in
`dec-cursor-agent-panel.applescript` for the exact loop. Each candidate resolves
in ~1s (vs. 15-30s for a dynamic `entire contents` scan of the ~750-900 element
subtree that contains it).

Sibling groups observed under this toolbar row (index varies — 4 groups seen once,
6 another time, likely depends on which controls are visible/enabled):

- **Item 1**: the mode indicator (Agent/Ask/Plan/Multitask/Debug) — see below.
- One of the others: the model picker, a native `pop up button` whose `name` is
  the current model (e.g. `"Composer 2.5"`, `"Grok 4.6"`). This is the ONE
  `pop up button` found anywhere under the composer area — a reliable anchor
  for re-deriving this path later (see recipe).
- Remaining groups: effort selector, voice/other controls — not mapped in detail.

### Mode indicator group (item 1 of the toolbar row)

Structure: 3 nested sub-groups, each wrapping one `static text`:

1. Icon sub-group — `static text` with **no visible value, no name, no
   AXIdentifier, no AXDescription, no AXHelp/tooltip even on hover**. Its
   accessible text value is a single non-printable character (length 1, looks
   empty when logged) — not literally `""`. Do not match on "is empty string";
   match on actual content instead (see below).
2. Text label sub-group — `static text` whose value is the mode name exactly as
   shown in `_modeMenuLabel()`: `"Agent"`, `"Ask"`, `"Plan"`, `"Multitask"`,
   `"Debug"`. **Only present when the agent panel is wide enough to show text.**
   This sub-group is removed from the tree entirely when narrow — not just
   visually hidden.
3. Chevron sub-group — another empty/unprintable `static text`, same as #1.

**Narrow-panel limitation (confirmed, not a bug to "fix"):** when the panel is
too narrow to show the text label, there is NO accessible signal anywhere in
this structure to tell modes apart (no id, no DOM class, no tooltip). This was
verified by: hovering the icon and checking `AXHelp`/`AXDescription` (both
empty), checking for a tooltip window appearing (none), and dumping every
attribute of the icon's static text and its wrapping group (nothing
distinguishing). `getAgentMode()` returns `missing value` in this state by
design — `switchAgentMode()` degrades by trusting a clean click+type+Return
instead of retrying against an unreadable mode.

`getAgentMode()` matches the found static text's lowercased value against the
known mode set `{"agent","ask","plan","multitask","debug"}` rather than
checking for non-empty, specifically because of the icon's non-empty-but-blank
character gotcha above.

## Recipe: re-deriving `MODE_TOOLBAR_PATH_CANDIDATES` when this breaks again

Use the model picker's `pop up button` as the anchor — it's the only one in the
composer area and easy to find reliably, even when the rest of the layout shifts:

1. Get a reliable starting point: `getPromptUI()` (already works, don't rebuild this).
2. Walk up `AXParent` ~10-15 times from the prompt to reach a container that's
   large enough to contain the whole composer tab (a few hundred to ~1000
   descendant elements is normal).
3. Within that scope, do `entire contents` once and find the single element
   whose `class is pop up button`. (Expect this scan to take 10-30s — that's
   fine, it's a one-time derivation, not something that ships in the handler.)
4. From that pop up button, walk up exactly 3 `AXParent`s to reach the toolbar
   row (the direct parent of the sibling groups for mode/model/effort/etc).
5. To turn that into a fast, hardcoded path: starting at the toolbar row, walk
   UP to `getHtmlContent()` one `AXParent` at a time. At each step, before
   moving up, find the current element's index within `groups of itsParent`
   (loop and compare element identity with `is`). Prepend each index found
   (`set beginning of indexPath to foundIndex`) so the list ends up ordered
   outermost-first. That list is a new candidate for `MODE_TOOLBAR_PATH_CANDIDATES`.
6. Verify: `group (item 1 of path) of group (item 2 of path) of ... of
   htmlContent` should resolve in ~1s and `UI elements of (that)` should have
   the mode-indicator group as item 1 (look for the static text matching a
   known mode name inside it).
7. Test in BOTH wide and narrow panel states, AND with both a single agent tab
   and multiple agent tabs open, before trusting it — confirmed live that tab
   count alone changes two positions in this path (see above), so don't assume
   a path derived in one tab-count state covers the other; verify each
   separately and add a new candidate (don't replace an existing one) if it
   doesn't match.

This hardcoded-path approach is a deliberate speed/robustness tradeoff: it WILL
break on the next Cursor layout change, by design — see `@Change Logs` in
`dec-cursor-agent-panel.applescript`.

## Terminal (`dec-cursor-terminal.applescript`)

Reference notes for the terminal decorator, captured live against a running
Cursor 3.27 on 2026-10-30, same caveat as above: specific to this exact build
and panel layout, expect it to go stale.

### The terminal text field

The terminal (xterm) widget is a `text field` directly under `getHtmlContent()`,
identifiable by its accessibility description, which always starts with
`"Terminal N, <shell>"` (e.g. `"Terminal 1, zsh"`), followed by a fixed block of
screen-reader help text.

Fixed path from `getHtmlContent()` (fast, no tree walk), captured 2026-11-11.
Every level is `UI element N` (outermost first):

```
TERMINAL_PATH_CANDIDATES = {{1, 3, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 3, 1, 1}}
```

`_findTerminalTextField()` tries each candidate (checking the description
contains `"Terminal"`) and falls back to a full-tree scan (`entire contents`,
10s+) only if none resolve. Resolves in well under a second; verified twice,
3s apart.

**Why the old chain was unstable:** it used `group N`, which counts only
groups, so any non-group sibling appearing or disappearing shifted the index.
`UI element N` counts all children and is stable. Always use `UI element N`.

### Terminal tabs (multiple terminals)

With 2+ terminals, the panel shows an `AXList` described `"Terminal tabs"`; its
children are the tabs (`"Terminal 1 zsh"`, ...). Fixed path from
`getHtmlContent()` (`UI element N`, captured 2026-11-11):

```
TERMINAL_TAB_LIST_PATH = {1, 3, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 1, 1}
```

With a single terminal the list isn't rendered (count = 1). Split panes are
separate entries (`"Terminal 3 zsh, split 2 of 2"`) but share one tab group, so
clicking either shows the group's active pane. The text field (see above) is
always the active terminal's, and still resolves with several terminals. The
toolbar "+" button creates a *split*, so `newTerminal()` uses Ctrl+Shift+`.
The tab close button and toolbar "Kill Terminal" aren't exposed with several
terminals (no AX element even on hover), so `closeTerminal()` switches to the tab
and runs "Terminal: Kill the Active Terminal Instance" from the command palette.

### Recipe: re-deriving the fixed path when it breaks

1. Get `getHtmlContent()` (already works, don't rebuild this).
2. `entire contents` of it once, filter to `class is text field` and
   `description contains "Terminal"` — this is the fallback's own lookup, so
   if even this fails, the terminal panel probably isn't open.
3. From that text field, walk up via the `AXParent` attribute, and at each
   level find the element's index within `UI elements of` its parent by
   matching `AXPosition` (plain identity/`=` comparison on the element
   references themselves is NOT reliable here — different queries for "the
   same" element don't compare equal, only their `AXPosition` values do).
4. Build the compound specifier outermost-first, using each level's own
   `class` (`group`, `text field`, or the literal `UI element` for whichever
   level isn't a plain group). Resolve with `UI element N` at every level.
5. Verify immediately, in the same script, by resolving that exact compound
   specifier and checking its `description` contains `"Terminal"`. Do this at
   least twice, a few seconds apart, before trusting it — per the instability
   note above, a single successful derivation is not enough confidence here.
6. Update the path in both this file and `_findTerminalTextField()` in
   `dec-cursor-terminal.applescript`.

## Agent panel width (narrow detection / widening)

Measured live 2026-11-06: the mode label disappears when the panel is ~341px wide
and is still shown at ~377px (minimum panel width is ~299px). The prompt text area
is panel width minus ~53px, and its left edge sits ~28px right of the panel's drag
handle, so `isAgentPanelNarrow()` / `widenAgentPanelIfNarrow()` work from the prompt
(`NARROW_PROMPT_WIDTH` 300 = 354px panel / 301px prompt, the narrowest width still showing the label; `WIDE_PROMPT_WIDTH` 406) and drag from
`promptLeft - 28` at the window's vertical middle. The drag only registers while
Cursor is frontmost. Read `size of` into a variable before `item 1 of` it, or the
specifier parse fails.

## Primary side bar (`dec-cursor-side-bar.applescript`)

Captured live against Cursor 3.27 on 2026-11-06. The panel showing in the left
side bar is identified by the accessibility `description` of its first section
header, found at a fixed path from `getHtmlContent()` (`UI element N` at every
level, outermost first):

```
SIDE_BAR_HEADER_PATH_CANDIDATES = {{1, 3, 1, 1, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 1}}
```

Descriptions seen at that path: `"Search Section"` (a `group`), `"Explorer Section:
<folder name>"` (a `button`), `"Run Section"` (a `button`). The Explorer text
varies with the folder, so match on the `"Explorer Section"` prefix. Resolves in
well under a second. The Activity Bar itself isn't exposed in the tree, so the
section header is the signal.

Confirmed in two windows (Explorer in one, Run and Debug in the other); Search
resolved at the same path through its container in a third check.

### Recipe: re-deriving the path when it breaks

1. With the wanted panel open, scan `entire contents` of `getHtmlContent()` once
   (a few seconds on a small window) for the element whose description contains
   `" Section"`.
2. Walk up via `AXParent`. At each level, collect every sibling index whose
   `AXPosition`, `AXSize` and class match the current element: overlapping panes
   often share a frame, so more than one index can match.
3. Resolve depth-first through the candidate indexes, keeping only the combination
   whose leaf has the expected description. Add it as a new candidate rather than
   replacing the old one.

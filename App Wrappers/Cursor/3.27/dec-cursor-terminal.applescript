(*
	@Purpose:
		Handlers for terminal operations.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-terminal'

	@Created: Fri, Oct 30, 2026, at 01:50:22 PM
	@Last Modified: Wed, Nov 11, 2026, at 11:50:37 AM

	@Change Logs:
		Wed, Nov 11, 2026, at 11:50:37 AM - AI Fixed unstable terminal lookup: replaced the "group N" chain with TERMINAL_PATH_CANDIDATES, a "UI element N" chain (group-only indexing shifted whenever a non-group sibling changed). Added getTerminalCount(), newTerminal(), switchTerminal(index) and closeTerminal(index) for multiple terminals.
		Fri, Oct 30, 2026, at 01:50:22 PM - AI Cloned from Cursor 3.18, since its fixed group-index chain to the terminal text field no longer resolves at all under 3.27 ("Invalid index"). _findTerminalTextField() now tries a fixed group-index chain captured live on 2026-10-30 first (fast: one compound specifier, no full-tree walk), falling back to a full-tree description-based scan only if that fails -- same "hardcoded path, dynamic fallback" shape as getPromptUI() in dec-cursor-agent-panel.applescript. The fallback alone was correct but too slow (several seconds, much more under load) since it fetches a property per element across the whole content root; see "## Terminal" in ui-structure-notes.md for the full path and the recipe for re-deriving it when it goes stale. Also fixed focusTerminal(): "set focused of ... to true" silently no-ops on this xterm-based text field (no error, focus never actually changes) -- switched to cliclick's leftClick, which does focus it, per the project's existing "click web content via cliclick" convention. isTerminalFocused() is no longer WIP; it reads focused of the found text field directly (no need to force frontmost just to query state). Verified live against a running Cursor 3.27: terminal lookup (both the fast path and the fallback), showTerminal/hideTerminal, focusTerminal + isTerminalFocused flipping to true after a cliclick, and isTerminalFocused reading back false beforehand.
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use cliclickLib : script "core/cliclick"

property logger : missing value

property kb : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Show Terminal
		Manual: Hide Terminal
		Manual: Run Command
		Manual: New Terminal

		Manual: Terminal Count
		Manual: Switch Terminal
		Manual: Close Terminal
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutLib to script "core/cursor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Terminal visible: {}", sut's isTerminalVisible())
	logger's infof("Terminal focused: {}", sut's isTerminalFocused())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showTerminal()
		
	else if caseIndex is 3 then
		sut's hideTerminal()
		
	else if caseIndex is 4 then
		sut's runTerminalCommand("ls")
		
	else if caseIndex is 5 then
		sut's newTerminal()
		
	else if caseIndex is 6 then
		logger's infof("Terminal count: {}", sut's getTerminalCount())
		
	else if caseIndex is 7 then
		logger's infof("Switched to terminal 1: {}", sut's switchTerminal(1))
		
	else if caseIndex is 8 then
		logger's infof("Closed terminal 2: {}", sut's closeTerminal(2))
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	set cliclick to cliclickLib's new()
	
	script CursorTerminalDecorator
		property parent : mainScript

		(* Captured live on Cursor 3.27, 2026-11-11, same "UI element N" convention as TERMINAL_PATH_CANDIDATES. *)
		property TERMINAL_TAB_LIST_PATH : {1, 3, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 1, 1}
		
		
		on runTerminalCommand(shellCommand)
			if running of application "Cursor" is false then return
			if not isTerminalVisible() then showTerminal()
			
			focusTerminal()
			kb's typeText(shellCommand)
			kb's pressKey(return)
		end runTerminalCommand
		
		
		on isTerminalVisible()
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			my _findTerminalTextField(htmlContent) is not missing value
		end isTerminalVisible
		
		
		on showTerminal()
			if isTerminalVisible() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			kb's pressControlKey("`")
		end showTerminal
		
		
		on hideTerminal()
			if not isTerminalVisible() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			kb's pressControlKey("`")
		end hideTerminal
		
		
		
		on focusTerminal()
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return
			set targetTextField to my _findTerminalTextField(htmlContent)
			if targetTextField is missing value then return
			
			leftClick of cliclick at targetTextField
		end focusTerminal
		
		
		on isTerminalFocused()
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			set targetTextField to my _findTerminalTextField(htmlContent)
			if targetTextField is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				focused of targetTextField
			end tell
		end isTerminalFocused
		
		
		(*
			@returns the number of terminals in the panel (0 when it isn't visible).
				VS Code hides the tab list while there is only one terminal, so a
				visible terminal with no tab list counts as 1.
		*)
		on getTerminalCount()
			if not isTerminalVisible() then return 0
			
			set tabList to my _getTerminalTabList()
			if tabList is missing value then return 1
			
			tell application "System Events" to tell process "Cursor"
				count of UI elements of tabList
			end tell
		end getTerminalCount
		
		
		(* Opens a new terminal (showing the panel first if needed) and focuses it. *)
		on newTerminal()
			if running of application "Cursor" is false then return
			
			if not isTerminalVisible() then showTerminal()
			
			(* The toolbar "+" button was tried first, but it created a split pane instead of a new terminal tab. *)
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			kb's pressControlShiftKey("`")
		end newTerminal
		
		
		(*
			Focuses the terminal at the given 1-based tab position.
			@returns true when switched; false if there is no such terminal.
		*)
		on switchTerminal(terminalIndex)
			if running of application "Cursor" is false then return false
			if not isTerminalVisible() then return false
			
			set tabList to my _getTerminalTabList()
			if tabList is missing value then return terminalIndex is 1
			
			tell application "System Events" to tell process "Cursor"
				if terminalIndex < 1 or terminalIndex > (count of UI elements of tabList) then return false
				
				set frontmost to true
				set targetTab to UI element terminalIndex of tabList
			end tell
			leftClick of cliclick at targetTab
			true
		end switchTerminal
		
		
		(*
			Closes (kills) the terminal at the given 1-based tab position by
			switching to it and running the "Terminal: Kill the Active Terminal
			Instance" command from the command palette. (The tab's close button
			and the toolbar's Kill Terminal button aren't exposed to accessibility
			once there are several terminals.) For a split pane this closes just
			that pane.
			@returns true when closed; false if there is no such terminal.
		*)
		on closeTerminal(terminalIndex)
			if not switchTerminal(terminalIndex) then return false
			
			kb's pressCommandShiftKey("p")
			delay 0.5
			kb's typeText("Terminal: Kill the Active Terminal Instance")
			delay 0.5
			kb's pressKey(return)
			delay 1
			true
		end closeTerminal
		
		
		(*
			The container whose children are the terminal tabs, or missing value
			(single terminal: VS Code doesn't render the list).
		*)
		on _getTerminalTabList()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			my _resolveUiElementPath(htmlContent, TERMINAL_TAB_LIST_PATH)
		end _getTerminalTabList
		
		
		on _resolveUiElementPath(rootElement, indexPath)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to rootElement
					repeat with nextIndex in indexPath
						set currentElement to UI element (contents of nextIndex) of currentElement
					end repeat
					return currentElement
				end try
			end tell
			missing value
		end _resolveUiElementPath
		
		
		(*
			Electron content root (AXWebArea). Same anchor as Cursor's agent-panel
			decorator -- see ui-structure-notes.md in this folder.
		*)
		on getHtmlContent()
			if running of application "Cursor" is false then return missing value
			
			tell application "System Events" to tell process "Cursor"
				UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
			end tell
		end getHtmlContent
		
		
		(*
			Fast path: a fixed "UI element N" index chain from getHtmlContent(),
			captured live against Cursor 3.27 on 2026-11-11 -- see "## Terminal" in
			ui-structure-notes.md (same folder) for the path, how it was derived and
			the recipe for re-deriving it. Indexes count every child ("UI element"),
			not just groups: the earlier "group N" chain was unstable because any
			non-group sibling shifted the group numbering.

			Falls back to a full-tree description-based scan (slow: 10s+) only when
			no candidate resolves -- same "hardcoded path, dynamic fallback" shape as
			getPromptUI() in dec-cursor-agent-panel.applescript. Add a new candidate
			when the layout shifts.
		*)
		property TERMINAL_PATH_CANDIDATES : {{1, 3, 1, 1, 2, 2, 1, 2, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 3, 1, 1}}
		
		on _findTerminalTextField(uiContainer)
			repeat with nextCandidatePath in TERMINAL_PATH_CANDIDATES
				set fastPathField to my _resolveTerminalPath(uiContainer, contents of nextCandidatePath)
				if fastPathField is not missing value then return fastPathField
			end repeat
			
			tell application "System Events" to tell process "Cursor"
				repeat with nextUiElement in (entire contents of uiContainer)
					try
						if class of nextUiElement is text field and description of nextUiElement contains "Terminal" then
							return contents of nextUiElement
						end if
					end try
				end repeat
			end tell
			missing value
		end _findTerminalTextField
		
		
		on _resolveTerminalPath(rootElement, indexPath)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to rootElement
					repeat with nextIndex in indexPath
						set currentElement to UI element (contents of nextIndex) of currentElement
					end repeat
					if description of currentElement contains "Terminal" then return currentElement
				end try
			end tell
			missing value
		end _resolveTerminalPath
		
	end script
end decorate

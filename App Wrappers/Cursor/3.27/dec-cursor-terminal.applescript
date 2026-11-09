(*
	@Purpose:
		Handlers for terminal operations.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-terminal'

	@Created: Fri, Oct 30, 2026, at 01:50:22 PM
	@Last Modified: Fri, Oct 30, 2026, at 01:50:22 PM

	@Change Logs:
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
			Fast path: a fixed group-index chain captured live against a running
			Cursor 3.27 on 2026-10-30 -- see "## Terminal" in ui-structure-notes.md
			(same folder) for the full path, how it was derived, and the recipe for
			re-deriving it once it goes stale (it will -- the terminal/panel area
			reflows based on what else is open, same as the composer toolbar paths
			documented there).

			Falls back to a full-tree description-based scan (slow: a few seconds,
			sometimes much more under load, since it's hundreds of individual
			accessibility round-trips) only when the fixed chain fails to resolve
			-- same "hardcoded path, dynamic fallback" shape as getPromptUI() in
			dec-cursor-agent-panel.applescript.
		*)
		on _findTerminalTextField(uiContainer)
			tell application "System Events" to tell process "Cursor"
				try
					set fastPathField to text field 1 of group 1 of group 3 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of uiContainer
					if description of fastPathField contains "Terminal" then return fastPathField
				end try

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
		
	end script
end decorate

(*
	@Purpose:
		Handlers for terminal operations.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/dec-cursor-terminal'

	@Created: Sun, Sep 13, 2026 at 12:12:39 PM
	@Last Modified: Sun, Sep 13, 2026 at 12:12:39 PM
		
	@Change Logs:
		Fri, Oct 30, 2026, at 01:50:22 PM - AI Fixed focusTerminal(): "set focused of ... to true" was silently a no-op on the terminal's xterm-based text field (no error, focus never actually changed) -- switched to cliclick's leftClick, which does focus it, per the project's existing "click web content via cliclick" convention. isTerminalFocused() is no longer WIP; it was already reading the right property, it just never worked because nothing actually focused the field first. Also stopped forcing frontmost just to read focus state, matching the working isAgentPanelFocused() pattern in dec-cursor-agent-panel.applescript. Mirrors the fix verified live against the 3.27 sibling file; this repo has no running Cursor 3.18 to test against directly.
		Thu, Sep 24, 2026, at 09:43:02 AM - Added isTerminalFocused() handler.
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
	
	-- activate application "" 
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
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				exists (text field 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 2 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window)
			end tell
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
				set targetTextField to text field 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 2 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
			end tell

			leftClick of cliclick at targetTextField
		end focusTerminal


		on isTerminalFocused()
			if running of application "Cursor" is false then return false

			tell application "System Events" to tell process "Cursor"
				set targetTextField to text field 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 2 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
				focused of targetTextField
			end tell
		end isTerminalFocused
		
	end script
end decorate

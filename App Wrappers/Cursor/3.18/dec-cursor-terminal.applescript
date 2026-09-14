(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/dec-cursor-terminal'

	@Created: Sun, Sep 13, 2026 at 12:12:39 PM
	@Last Modified: Sun, Sep 13, 2026 at 12:12:39 PM
	
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

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
				
				set focused of targetTextField to true
			end tell
		end focusTerminal
	end script
end decorate

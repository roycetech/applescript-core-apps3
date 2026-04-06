(*
	@Purpose:
		High-level Cursor workflows (Ask Mode, etc.).
		Highly experimental and subject to change.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh App Wrappers/Cursor/2.5/dec-cursor-high-level  

	@Created: Sat, Feb 28, 2026 at 12:00:00 PM
	@Last Modified: 2026-03-12 12:00:00
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"

property logger : missing value

property kb : missing value

property COMMAND_PALETTE_OPEN_CHAT_IN_AGENT_MODE : "Open Chat in Agent Mode"
property COMMAND_PALETTE_OPEN_CHAT_IN_ASK_MODE : "Open Chat in Ask Mode"

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Show chat in Agent Mode
		Manual: Show chat in Ask Mode
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
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showChatInAgentMode()
		
	else if caseIndex is 3 then
		sut's showChatInAskMode()
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(* @mainScript - script "core/cursor" *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set kb to kbLib's new()
	
	script CursorHighLevelDecorator
		property parent : mainScript
		
		(*
			Test Cases:
				Agent mode hidden
				Agent mode shown
				Chat mode shown
				Chat mode hidden
				
			NOTE: Worst case is when you run this command when already on the target chat mode.
		*)
		on showChatInAgentMode()
			if running of application "Cursor" is false then return
			
			if not isSecondarySideBarVisible() then
				logger's debug("Not visible initially, showing...")
				showSecondarySideBar()
			end if
			
			logger's debug("Hitting command i")
			_focusApp()
			kb's pressCommandKey("i")
			delay 1
			if not isSecondarySideBarVisible() then
				logger's debug("Sidebar not found, hitting again")
				kb's pressCommandKey("i")
			end if
		end showChatInAgentMode
		
		
		(* 	Test Cases:
				Agent mode shown - 
				Chat mode shown -
				Agent mode hidden - 
				Chat mode hidden -
		*)
		on showChatInAskMode()
			if running of application "Cursor" is false then return
			
			if isSecondarySideBarVisible() then -- Case 1 and 2
				runCommandPalette(COMMAND_PALETTE_OPEN_CHAT_IN_ASK_MODE)
				if not isSecondarySideBarVisible() then -- Case 2
					showSecondarySideBar()
					return
				else -- Case 1
					-- noop
				end if
			else
				_focusApp()
				kb's pressCommandKey("i")
				delay 1
				runCommandPalette(COMMAND_PALETTE_OPEN_CHAT_IN_ASK_MODE)
				if not isSecondarySideBarVisible() then -- Case 4
					showSecondarySideBar()
					return
				else -- Case 3
					-- noop 
				end if
			end if
			
			
			
		end showChatInAskMode
		
		
	end script
end decorate
(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	Notes:
		Buttons one and two, hidden, are for going to the next or previous page respectively.

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Stream Deck/7.4/dec-stream-deck-virtual-deck'

	@Created: Sun, Sep 13, 2026 at 10:49:48 AM
	@Last Modified: Sun, Sep 13, 2026 at 10:49:48 AM
	
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
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
	set sutLib to script "core/stream-deck"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Virtual deck present: {}", sut's isVirtualDeckPresent())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script StreamDeckVirtualDeckDecorator
		property parent : mainScript
		
		on isVirtualDeckPresent()
			if running of application "Elgato Stream Deck" is false then return false
			
			tell application "System Events" to tell process "Stream Deck"
				try
					set dialogWindow to first window whose description is "dialog"
					return value of attribute "AXIdentifier" of button 1 of dialogWindow starts with  "ESDStreamDeckApplication.uiSD_GridWidget."
					
				end try
			end tell
			false
		end isVirtualDeckPresent
	end script
end decorate

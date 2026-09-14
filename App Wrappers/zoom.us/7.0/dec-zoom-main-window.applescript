(*
	@Purpose:
		Handlers for the main window, before the meeting.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/zoom.us/7.0/dec-zoom-main-window'

	@Created: Sun, Sep 13, 2026 at 05:36:35 PM
	@Last Modified: Sun, Sep 13, 2026 at 05:36:35 PM
	
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
	set sutLib to script "core/zoom"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerNewMeeting()
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script ZoomMainWindowDecorator
		property parent : mainScript
		
		(*
			Hit the New Meeting button
		*)
		on triggerNewMeeting()
			if running of application "zoom.us" is false then return
			
			tell application "System Events" to tell process "zoom.us"
				click (first button of group 1 of group 1 of splitter group 1 of front window whose description starts with "Start a new")
			end tell
		end triggerNewMeeting
	end script
end decorate

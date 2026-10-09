(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Slack/slack'

	@Created: Tue, Sep 22, 2026 at 01:49:28 PM
	@Last Modified: July 24, 2023 10:56 AM
*)

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sut to new()
	logger's infof("Is video focused: {}", sut's isVideoFocused())
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	
	script SlackInstance
	
		on isVideoFocused()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			tell application "System Events" to tell process "Slack"
				exists (static text "Video clip" of group 1 of group 3 of group 1 of group 1 of group 2 of group 3 of group 1 of group 2 of group 1 of htmlContent)
			end tell
		end isVideoFocused
		
		on getHtmlContent()
			if running of application "Slack" is false then return missing value
			
			tell application "System Events" to tell process "Slack"
				try
					return UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
				end try
			end tell
			
			missing value
		end getHtmlContent
	end script
end new

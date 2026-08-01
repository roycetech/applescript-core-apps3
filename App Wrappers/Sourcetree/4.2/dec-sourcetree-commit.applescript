(*
	@Purpose:


	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Sourcetree/4.2/dec-sourcetree-commit'

	@Created: Sat, Jul 11, 2026 at 05:21:28 PM

	@Last Modified: Sat, Jul 11, 2026 at 05:21:28 PM
	@Change Logs:
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

property logger : missing value

property cliclick : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
        	Manual: Trigger Author
        	Manual: Switch Author Type
        	Manual: Switch Author to Alternative
        	Dummy
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
	set sutLib to script "core/sourcetree"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	(* 
	set currentCommitEmail to sut's getCurrentCommitEmail()
	logger's infof("Current commit email: {}", currentCommitEmail)
	*)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's triggerAuthor()
		logger's info("Selected author type: " & sut's getSelectedAuthorType())
		logger's infof("Author popup is visible: {}", sut's isAuthorPopupVisible())
		
	else if caseIndex is 3 then
		set sutAuthorType to "unicorn"
		set sutAuthorType to "alternative"
		set sutAuthorName to "spotAuthorName"
		set sutAuthorEmail to "spotAuthorEmail"
		-- set sutAuthorType to "default"
		
		logger's infof("sutAuthorType: {}", sutAuthorType)
		
		sut's switchAuthorType(sutAuthorType, sutAuthorName, sutAuthorEmail)
		
	else if caseIndex is 4 then
		set sutAuthorName to "unicorn"
		set sutAuthorEmail to "unicorn@example.com"
		logger's infof("sutAuthorName: {}", sutAuthorName)
		logger's infof("sutAuthorEmail: {}", sutAuthorEmail)
		
		sut's switchAuthorType("alternative", sutAuthorName, sutAuthorEmail)
		(* 
		sut's setAlternativeName(sutAuthorName)
		sut's setAlternativeEmail(sutAuthorEmail)
		*)
		
	end if
	
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	
	script SourcetreeCommitDecorator
		property parent : mainScript
		
		on setAlternativeName(authorName)
			if running of application "Sourcetree" is false then return
			if isAuthorPopupVisible() is false then
				logger's debug("Author popup is not visible, triggering author popup...")
				triggerAuthor()
				delay 1
			end if
			
			tell application "System Events" to tell process "Sourcetree"
				set frontmost to true
				set value of text field 1 of pop over 1 of first image of splitter group 1 of splitter group 1 of splitter group 1 of front window to authorName
			end tell
		end setAlternativeName
		
		on setAlternativeEmail(email)
			if running of application "Sourcetree" is false then return
			if isAuthorPopupVisible() is false then
				triggerAuthor()
			end if
			
			tell application "System Events" to tell process "Sourcetree"
				set frontmost to true
				set value of text field 2 of pop over 1 of first image of splitter group 1 of splitter group 1 of splitter group 1 of front window to email
			end tell
		end setAlternativeEmail
		
		on getAlternativeEmail()
			if running of application "Sourcetree" is false then return
			
			if isAuthorPopupVisible() is false then
				triggerAuthor()
			end if
			
			tell application "System Events" to tell process "Sourcetree"
				return value of text field 2 of pop over 1 of first image of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end getAlternativeEmail
		
		(*
			@authorName - Optional name to set when type is alternative.
			@authorEmail - Optional email to set when type is alternative.
		*)
		on switchAuthorType(authorType, authorName, authorEmail)
			if running of application "Sourcetree" is false then return
			if isAuthorPopupVisible() is false then
				triggerAuthor()
			end if
			
			tell application "System Events" to tell process "Sourcetree"
				set frontmost to true
				try
					click radio button ("Use " & authorType & " author") of radio group 1 of pop over 1 of first image of splitter group 1 of splitter group 1 of splitter group 1 of front window
					delay 0.1
				end try
			end tell
			
			if authorType is "alternative" then
				setAlternativeName(authorName)
				setAlternativeEmail(authorEmail)
			end if
			
			tell application "System Events" to tell process "Sourcetree"
				perform action "AXCancel" of pop over 1 of image 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end switchAuthorType
		
		on triggerAuthor()
			if running of application "Sourcetree" is false then return
			if isAuthorPopupVisible() then return
			
			tell application "System Events" to tell process "Sourcetree"
				set frontmost to true
				set result to first image of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
			lclick of cliclick at result
		end triggerAuthor
		
		
		(*
            		Must be called after triggerAuthor()

			@returns "default" or "alternative"
		*)
		on getSelectedAuthorType()
			if running of application "Sourcetree" is false then return missing value
			
			tell application "System Events" to tell process "Sourcetree"
				title of (first radio button of radio group 1 of pop over 1 of first image of splitter group 1 of splitter group 1 of splitter group 1 of front window whose value is 1)
			end tell
			textUtil's stringBetween(result, space, space)
		end getSelectedAuthorType
		
		
		on isAuthorPopupVisible()
			if running of application "Sourcetree" is false then return false
			
			tell application "System Events" to tell process "Sourcetree"
				exists (button "OK" of pop over 1 of image 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window)
			end tell
		end isAuthorPopupVisible
		
		
		on getCurrentCommitEmail()
			if running of application "Sourcetree" is false then return missing value
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set rawValue to value of static text 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
					set displayedEmail to textUtil's stringBetween(rawValue, "<", ">")
					if displayedEmail is not missing value then return displayedEmail
					
				end try
			end tell
			
			triggerAuthor()
			set alternativeEmail to getAlternativeEmail()
			
			tell application "System Events" to tell process "Sourcetree"
				perform action "AXCancel" of pop over 1 of image 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
			
			-- triggerAuthor()
			alternativeEmail
		end getCurrentCommitEmail
		
	end script
end decorate

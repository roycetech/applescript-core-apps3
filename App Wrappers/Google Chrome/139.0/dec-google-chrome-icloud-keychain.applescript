(*
	@Purpose:
		See handlers.

	#WIP

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Google Chrome/139.0/dec-google-chrome-icloud-keychain'


	@Created: Wed, Aug 06, 2025 at 06:43:39 AM
	@Last Modified: Wed, Aug 06, 2025 at 06:43:39 AM
	@Change Logs:
*)
use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger"} contains the name of current application then spotCheck()

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
	set sutLib to script "core/google-chrome"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	tell application "System Events" to tell process "Google Chrome"
		set frontmost to true
		delay 1
	end tell
	
	logger's infof("Login UI available: {}", sut's getLoginUi() is not missing value)
	logger's infof("Password completion UI available: {}", sut's getPasswordAutoFillCompletionListUi() is not missing value)
	logger's infof("Is Keychain visible: {}", sut's isKeychainFormVisible())
	
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
	
	script GoogleChromeIcloudKeychainDecorator
		property parent : mainScript
		
		
		on getLoginUi()
			if getApplicationVersion() as integer is greater than or equal to "139.0" then
				tell application "System Events" to tell process "Chrome"
					return UI element "Login Page" of group 2 of group 1 of group 1 of group 1 of group "Login Page - Google Chrome" of front window
				end tell
			end if
			
			missing value
		end getLoginUi
		
		
		on getPasswordAutoFillCompletionListUi()
			if getApplicationVersion() as integer is greater than or equal to "139.0" then
				set loginUi to getLoginUi()
				if loginUi is missing value then return missing value
				
				tell application "System Events" to tell process "Chrome"
					try
						return UI element "Password AutoFill Completion List" of group 1 of group 2 of loginUi
					end try
				end tell
			end if
			
			missing value
			
		end getPasswordAutoFillCompletionListUi
		
		
		-- static text "iCloud Passwords" of group 1 of list 1 of group 1 of group 1 of UI element "Password AutoFill Completion List" of group 1 of group 2 of 
		
		on isKeychainFormVisible()
			set frontTab to getFrontTab()
			if frontTab is missing value then return false
			
			set completionUi to missing value
			try
				set completionUi to getPasswordAutoFillCompletionListUi()
			end try -- Fails when iCloudKey chain hasn't been approved yet.
			if completionUi is missing value then
				logger's debug("Password Auto Completion UI could not be retrieved")
				return false
			end if
			
			tell application "System Events" to tell process "Google Chrome"
				exists (static text "iCloud Passwords" of group 1 of list 1 of group 1 of group 1 of completionUi)
			end tell
		end isKeychainFormVisible
	end script
end decorate

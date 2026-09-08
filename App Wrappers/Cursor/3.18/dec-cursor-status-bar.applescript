(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/dec-cursor-status-bar'

	@Created: Sat, Sep 05, 2026 at 10:15:08 AM
	@Last Modified: Sat, Sep 05, 2026 at 10:15:08 AM
	
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
		Manual: Toggle Status Bar
		Manual: Show Status Bar
		Manual: Hide Status Bar
		Manual: Find Status Bar Item by Keyword

		Dummy 
		Dummy
		Dummy
		Dummy
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
	set sutLib to script "core/cursor"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if sut's isStatusBarPresent() then
		logger's infof("Status Bar present: {}", sut's isStatusBarPresent())
		logger's infof("Status Bar UI: {}", sut's getStatusBarUI() is not missing value)
	else
		logger's info("Status Bar not present")
	end if
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's toggleStatusBar()
		
	else if caseIndex is 3 then
		sut's showStatusBar()
		
	else if caseIndex is 4 then
		sut's hideStatusBar()
		
	else if caseIndex is 5 then
		if sut's isStatusBarPresent() then
			set cliclickLib to script "core/cliclick"
			set cliclick to cliclickLib's new()
			
			set sutStatusBarKeyword to "Five"
			logger's infof("sutStatusBarKeyword: {}", sutStatusBarKeyword)
			
			set sutStatusBarItem to sut's findStatusBarItemByKeyword(sutStatusBarKeyword)
			logger's infof("sutStatusBarItem: {}", sutStatusBarItem is not missing value)
			
			if sutStatusBarItem is not missing value then
				tell application "System Events" to tell process "Cursor"
					try
						lclick of cliclick at button 1 of sutStatusBarItem
						logger's info("Clicked Status Bar item")
					on error errorMessage
						logger's errorf("Error finding Status Bar item by keyword: {}", errorMessage)
					end try
				end tell
			end if
		end if
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script CursorStatusBarDecorator
		property parent : mainScript
		
		on findStatusBarItemByKeyword(keyword)
			if running of application "Cursor" is false then return missing value
			if not isStatusBarPresent() then return missing value
			
			tell application "System Events" to tell process "Cursor"
				-- entire contents
				try
					return first group of group 1 of group 3 of group 2 of group 1 of group 1 of last group of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window whose description contains keyword
				end try
			end tell
			
			missing value
		end findStatusBarItemByKeyword
		
		
		on showStatusBar()
			if running of application "Cursor" is false then return
			if isStatusBarPresent() then return
			
			toggleStatusBar()
		end showStatusBar
		
		
		on hideStatusBar()
			if running of application "Cursor" is false then return
			if not isStatusBarPresent() then return
			
			toggleStatusBar()
		end hideStatusBar
		
		
		on toggleStatusBar()
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
				
				try
					click (menu item "Status Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1)
					
				end try
			end tell
		end toggleStatusBar
		
		
		on isStatusBarPresent()
			if running of application "Cursor" is false then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					-- For inspection.
					-- description of groups of group 1 of group 3 of group 2 of group 1 of group 1 of group 2 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of window 1					
					
					return exists (first group of group 1 of group 3 of group 2 of group 1 of group 1 of last group of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window whose description is "remote")
					
					
				end try
			end tell
			
			false
		end isStatusBarPresent
		
		
		on getStatusBarUI()
			if running of application "Cursor" is false then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					-- 3.18
					-- return group 1 of group 3 of group 2 of group 1 of group 1 of group 1 of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
					-- 3.19
					return group 1 of group 3 of group 2 of group 1 of group 1 of last group of group 1 of UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
					
				on error errorMessage
					logger's errorf("Error getting Status Bar UI: {}", errorMessage)
				end try
			end tell
			
			missing value
		end getStatusBarUI
	end script
end decorate


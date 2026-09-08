(*
	@Project:
		applescript-core-apps3

	NOTES:
		Cursor prefers "Side Bar" over Sidebar.
		Cursor dialog should refer to window 1, instead of the usual window "Open" etc.

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/cursor'

	@Created: Wed, Feb 25, 2026 at 12:27:36 PM
	@Last Modified: 2026-03-31 18:35:40

	@Change Logs:
		Tue, Sep 08, 2026, at 09:18:02 AM - Added status bar decorator.
		Thu, Aug 13, 2026, at 05:00:20 PM - Added handlers to switch to and from IDE/Agents window.
		Sat, May 23, 2026, at 06:56:52 PM - Allow configured decorator.
		Fri, Mar 27, 2026, at 02:37:47 PM - Added return value to the
			#switchProjectTab handler.

*)
use scripting additions

use textUtil : script "core/string"
use unic : script "core/unicodes"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use retryLib : script "core/retry"
use configSystemLib : script "core/config"
use decoratorLib : script "core/decorator"

property logger : missing value

property retry : missing value
property kb : missing value
property configSystem : missing value

property CONFIG_TYPE_SYSTEM : "system"
property CONFIG_KEY_CURSOR_CLI : "Cursor CLI"

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Show secondary side bar
		Manual: Hide secondary side bar
		Manual: Show minimap
		Manual: Hide minimap

		Manual: Single file layout
		Manual: Open file path via UI
		Manual: Switch Project Tab
		Manual: Open file via Command O
		Manual: Run command palette: Command Palette

		Manual: Open File via Shell
		Manual: Close Current Project
		Manual: Switch IDE Window
		Manual: Switch To Agents Window
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
	
	set sut to new()
	logger's infof("Secondary side bar visible: {}", sut's isSecondarySideBarVisible())
	logger's infof("Is minimap visible: {}", sut's isMinimapVisible())
	logger's infof("Is agents window in front: {}", sut's isAgentsWindowFrontmost())
	logger's infof("Is status bar present: {}", sut's isStatusBarPresent())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSecondarySideBar()
		
	else if caseIndex is 3 then
		sut's hideSecondarySideBar()
		
	else if caseIndex is 4 then
		sut's showMinimap()
		
	else if caseIndex is 5 then
		sut's hideMinimap()
		
	else if caseIndex is 6 then
		sut's singleFileLayout()
		
	else if caseIndex is 7 then
		set sutFilePath to "/etc/hosts"
		logger's debugf("sutFilePath: {}", sutFilePath)
		
		sut's openFilePathViaUI(sutFilePath)
		
	else if caseIndex is 8 then
		set sutProjectTab to "Unicorn"
		-- set sutProjectTab to "applescript-core"
		logger's debugf("sutProjectTab: {}", sutProjectTab)
		
		sut's switchProjectTab(sutProjectTab)
		
	else if caseIndex is 9 then
		set sutFilePath to "~/Projects/@roycetech/applescript-hub/src/apps/Sublime Text/Script Menu - Open in Cursor.applescript"
		logger's debugf("sutFilePath: {}", sutFilePath)
		
		sut's openFilePathViaCommandO(sutFilePath)
		
	else if caseIndex is 10 then
		set sutCommandKey to "Open Chat in Ask Mode"
		logger's debugf("sutCommandKey: {}", sutCommandKey)
		
		sut's runCommandPalette(sutCommandKey)
		
	else if caseIndex is 11 then
		sut's openFileViaShell("~/.talon/user/roycetech/apps/Cursor.talon")
		
	else if caseIndex is 12 then
		sut's closeProject()
		
	else if caseIndex is 13 then
		sut's switchToIdeWindow()
		
	else if caseIndex is 14 then
		sut's switchToAgentsWindow()
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set decCursorLayout to script "core/dec-cursor-layout"
	set decCursorCurrentFile to script "core/dec-cursor-current-file"
	set kb to kbLib's new()
	set configSystem to configSystemLib's new(CONFIG_TYPE_SYSTEM)
	
	set appWithFileDialogLib to script "core/abstract-app-with-file-dialog"
	set appWithFileDialog to appWithFileDialogLib's new("Cursor")
	set appWithFileDialog's doSetDialogTypeAsWindowReference to false
	
	set decCursorHighLevel to script "core/dec-cursor-high-level"
	set decCursorStatusBar to script "core/dec-cursor-status-bar"
	
	script CursorInstance
		property parent : appWithFileDialog 
		
		on switchToIdeWindow()
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				try
					click (menu item "Open IDE" of menu 1 of menu bar item "File" of menu bar 1)
				end try
			end tell
		end switchToIdeWindow
		
		
		on switchToAgentsWindow()
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				try
					click (menu item "Switch to Agents Window" of menu 1 of menu bar item "File" of menu bar 1)
				on error the errorMessage number the errorNumber
					click (menu item "New Agents Window" of menu 1 of menu bar item "File" of menu bar 1)
					
				end try
			end tell
		end switchToAgentsWindow
		
		
		on isAgentsWindowFrontmost()
			if running of application "Cursor" is false then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					return title of front window is "Cursor Agents"
				end try
			end tell
			
			false
		end isAgentsWindowFrontmost
		
		
		(*
			@projectTabKeyword - e.g. applescript-core.
			@return - true if successful, false otherwise.
		*)
		on switchProjectTab(projectTabKeyword)
			if running of application "Cursor" is false then return
			
			tell application "System Events" to tell process "Cursor"
				try
					-- click (first radio button of tab group 1 of window 1 whose title contains projectTabKeyword)
					click (first radio button of tab group 1 of window 1 whose title ends with projectTabKeyword)
					return true
				end try
			end tell
			false
		end switchProjectTab
		
		
		on _focusApp()
			tell application "System Events" to tell process "Cursor"
				if frontmost is false then set frontmost to true
			end tell
		end _focusApp
		
		
		on openFileViaShell(filePath)
			set expandedFilePath to expandPath(filePath)
			set cursorCli to configSystem's getValue(CONFIG_KEY_CURSOR_CLI)
			if cursorCli is missing value then return
			
			tell application "System Events" to tell process "Cursor"
				do shell script cursorCli & space & quoted form of expandedFilePath
			end tell
		end openFileViaShell
		
		(*
			NOTE: Not reliable on long paths.
		*)
		on openFilePathViaUI(filePath)
			if running of application "Cursor" is false then return
			
			_focusApp()
			kb's pressCommandKey("p")
			delay 0.5
			
			_focusApp()
			kb's typeText(filePath)
			-- delay 2
			delay 1
			
			_focusApp()
			kb's pressKey(return)
		end openFilePathViaUI
		
		
		(*
		*)
		on openFilePathViaUIRushed(filePath)
			if running of application "Cursor" is false then return
			
			_focusApp()
			kb's pressCommandKey("p")
			delay 0.5
			
			_focusApp()
			kb's typeText(filePath)
			-- delay 2
			delay 0.2
			
			_focusApp()
			kb's pressKey(return)
		end openFilePathViaUIRushed
		
		
		on runCommandPalette(commandKey)
			if running of application "Cursor" is false then return
			
			_focusApp()
			kb's pressShiftCommandKey("p")
			delay 1 -- NOTE: Sub second delay results in intermittent failures.
			
			_focusApp()
			kb's typeText(commandKey)
			delay 1
			
			_focusApp()
			kb's pressKey(return)
			delay 1
		end runCommandPalette
		
		
		(*
			NOTE: Close the project by closing the window from the File menu. 
			It's best to not tick the "disable the prompt to close" on the first run.
		*)
		on closeProject()
			tell application "System Events" to tell process "Cursor"
				if (count of windows) is 0 then return
				
				set frontmost to true
				set titleToClose to the title of front window
				logger's debugf("titleToClose: {}", titleToClose)
				
				repeat 5 times
					set frontmost to true
					try
						click menu item "Close Window" of menu 1 of menu bar item "File" of menu bar 1
						delay 0.5
						set currentTitle to the title of front window
						logger's debugf("currentTitle: {}", currentTitle)
						
						if titleToClose is not equal to currentTitle then exit repeat
					end try
					delay 0.5
				end repeat
			end tell
		end closeProject
		
		on openFilePathViaCommandO(filePath)
			set fileUtil to script "core/file"
			if not fileUtil's posixFilePathExists(filePath) then return
			
			_focusApp()
			kb's pressCommandKey("o")
			delay 0.5
			
			fileDialogGoToFolder()
			fileDialogEnterPath(filePath)
			fileDialogAcceptFoundPath()
			fileDialogChooseSelectionWithAction("Open")
		end openFilePathViaCommandO
		
		(*
			@Overrides
		*)
		on fileDialogSheetUI()
			tell application "System Events" to tell process "Cursor"
				try
					return sheet 1 of window 1
					
				end try
			end tell
			missing value
		end fileDialogSheetUI
		
		
		on isMinimapVisible()
			if running of application "Cursor" is false then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK
					
				end try
			end tell
			
			false
		end isMinimapVisible
		
		
		(*  *)
		on showMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				
				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showMinimap
		
		
		(*  *)
		on hideMinimap()
			if running of application "Cursor" is false then return
			if isMinimapVisible() is false then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Minimap" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideMinimap
		
		
		on showSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				
				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			delay 1
		end showSecondarySideBar
		
		
		on hideSecondarySideBar()
			if running of application "Cursor" is false then return
			if isSecondarySideBarVisible() is false then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			delay 1
		end hideSecondarySideBar
		
		
		on isSecondarySideBarVisible()
			if running of application "Cursor" is false then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
					return value of attribute "AXMenuItemMarkChar" of result is equal to unic's MENU_CHECK
					
				end try
			end tell
			
			false
		end isSecondarySideBarVisible
	end script
	decCursorLayout's decorate(result)
	decCursorCurrentFile's decorate(result)
	decCursorHighLevel's decorate(result)
	decCursorStatusBar's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("CursorInstance")
end new

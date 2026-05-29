(*
	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Marked/2.6.46/marked-tab'

	@Created: Mon, Oct 13, 2025 at 07:28:19 AM
	@Last Modified: 2025-10-13 07:30:25
	
	@Change Logs:
		Sat, May 16, 2026, at 05:31:49 PM - Fix main window derivation when zoom percent is present in the window title.
*)
use regexPatternLib : script "core/regex-pattern"

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
	
	tell application "Marked 2"
		set sut to my new(front window)
	end tell
	logger's infof("Current document name: {}", sut's getDocumentName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


on new(pAppWindow)
	loggerFactory's inject(me)
	
	script MarkedTabInstance
		property appWindow : pAppWindow
		
		(* @Deprecated. Use the handler under advanced.*)
		on setPreprocessorArguments(arguments)
			if running of application "Marked 2" is false then return
			
			tell application "System Events" to tell process "Marked 2"
				try
					click (first menu item of menu 1 of menu bar item "Marked 2" of menu bar 1 whose title starts with "Settings")
					delay 0.1
					set moreItems to pop up button 1 of toolbar 1 of front window
					click moreItems
					delay 0.1
					click menu item "Advanced" of menu 1 of moreItems
					delay 0.1
					click radio button "Preprocessor" of tab group 1 of window "Advanced"
					delay 0.1
					
					-- Value is not getting detected.
					set the value of text field 2 of tab group 1 of window "Advanced" to arguments
					
					delay 0.1
					click (first button of front window whose description is "close button")
				on error the errorMessage number the errorNumber
					log errorMessage
					
				end try
			end tell
		end setPreprocessorArguments
		
		(*
			NOTE: Take into account when the document is zoomed, the percentage is displayed in the window title.
		*)
		on getDocumentName()
			set mainWindow to getMainWindow()
			if mainWindow is missing value then
				logger's debug("Main window was not found")
				return missing value
			end if
			
			try
				set windowName to name of mainWindow
			on error the errorMessage number the errorNumber -- Throws when the app window is minimized in the dock.
				logger's warn(errorMessage)
				return missing value
			end try
			
			set regex to regexPatternLib's new(".*(?=\\s\\(\\d{2}%\\))")
			set zoomLessName to regex's firstMatchInString(windowName)
			if zoomLessName is not missing value then return zoomLessName
			
			windowName
		end getDocumentName
		
		
		on getMainWindow()
			if running of application "Marked 2" is false then return missing value
			
			tell application "System Events" to tell process "Marked 2"
				try
					-- return first window whose title ends with ".md"  -- Doesn't capture window where zoom is indicated ".md (80%)"
					return first window whose title contains ".md"
				end try
			end tell
			
			missing value
		end getMainWindow
		
		
		on hideEditor()
			if running of application "Marked 2" is false then return
			
			tell application "System Events" to tell process "Marked 2"
				set frontmost to true
				try
					click menu item "Hide Editor Pane" of menu 1 of menu bar item "View" of menu bar 1
				end try -- ignore if it don't exist
			end tell
		end hideEditor
		
		
		on focus()
			if running of application "Marked 2" is false then return
			
			try
				tell application "System Events" to tell process "Marked 2"
					click (first menu item of first menu of menu bar item "Window" of first menu bar whose title is equal to name of my appWindow)
				end tell
				true
			on error
				false
			end try
		end focus
		
		
		on closeTab()
			tell appWindow to close
		end closeTab
	end script
end new


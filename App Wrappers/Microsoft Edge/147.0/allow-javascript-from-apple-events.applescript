(*
	@Purpose:
		Activate JavaScript from Apple Events.
		
	DOESN'T WORK programmatically. Tried click and perform action.
	WARNING: Will use keyboard simulation. Didn't work either, looked like it is detecting and ignoring automation.
	NOTE: Needs manual user interaction to select the menu item.
	
	@Created: Fri, Apr 24, 2026, at 03:40:32 PM
	
	TODO: Import unic below the header comment.
*)
use scripting additions

use unic : script "core/unicodes"
use kbLib : script "core/keyboard"
use std : script "core/std"
use systemEventLib : script "core/system-events"
use processLib : script "core/process"
use dockLib : script "core/dock" 

property APP_NAME : "Microsoft Edge"

property minimizeAfterRun : false
property hideAfterRun : false
property quitAfterRun : false
property unfocusAfterRun : true
property closeWindowAfterRun : false
property currentFrontAppName : missing value

set kb to kbLib's new()
set systemEvent to systemEventLib's new()
set my currentFrontAppName to systemEvent's getFrontAppName()
set dock to dockLib's new()

if not std's appExists(APP_NAME) then
	log "Microsoft Edge app was not found"
	return
end if

if running of application APP_NAME is false then
	set quitAfterRun to true
	activate application APP_NAME
	
else if currentFrontAppName is equal to APP_NAME then
	-- NOOP
else
	set process to processLib's new(APP_NAME)
	if process's isMinimized() then
		set my minimizeAfterRun to true
		process's unminimize()
		
	else if process's hasWindows() then
		log "D: Another app is focused."
		set unfocusAfterRun to true
	else
		set closeWindowAfterRun to true
		dock's clickApp(APP_NAME)
	end if
end if


tell application "System Events" to tell process (my APP_NAME)
	set frontmost to true -- This is required to detect the state.	
	try
		set allowJavaScriptFromAppleEventsMenuItem to menu item "Allow JavaScript from Apple Events" of menu 1 of menu item "Developer" of menu 1 of menu bar item "View" of menu bar 1
		set currentValue to value of attribute "AXMenuItemMarkChar" of allowJavaScriptFromAppleEventsMenuItem
		
		if currentValue is not equal to unic's MENU_CHECK then
			log "Allowing JavaScript from Apple Events"
			click menu bar item "View" of menu bar 1
			delay 0.1
			kb's pressKey("up")
			kb's pressKey("right")
			kb's pressKey("a")
			say "Hit return to proceed"
		else
			log "JavaScript is already allowed from Apple Events"
		end if
	end try
end tell

-- log "D: currentFrontAppName: " & currentFrontAppName

if quitAfterRun then
	-- log "D: quitting " & APP_NAME
	tell application APP_NAME to quit
	
else if closeWindowAfterRun then
	tell application "System Events" to tell process "Microsoft Edge"
		click (first button of window 1 whose description is "close button")
	end tell
	
else if minimizeAfterRun then
	-- log "D: Minimizing again..."
	process's minimize()
	
else if unfocusAfterRun then
	tell application "System Events" to tell process (my currentFrontAppName)
		set frontmost to true
	end tell
end if



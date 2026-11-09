(*
	Annotate editor handlers.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/CleanShot X/4.7.4/dec-cleanshot-x-annotate'

	@Created: Saturday, November 7, 2026
	@Last Modified: Saturday, November 7, 2026
	@Change Logs:
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

use cliclickLib : script "core/cliclick"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set spotScript to script "core/spot-test"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Set Color Swatch 1
		Manual: Set Color Swatch 5
	")
	
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set sutLib to script "core/cleanshot-x"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	-- The Annotate editor must already be open.
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		logger's infof("Handler result: {}", sut's setAnnotateColorByIndex(1))
		
	else if caseIndex is 3 then
		logger's infof("Handler result: {}", sut's setAnnotateColorByIndex(5))
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script CleanshotXAnnotateDecorator
		property parent : mainScript
		
		(*
			Annotate editor: changes the current annotation color.
			The Color popover is a separate unnamed AXSystemDialog window, so window indexes shift
			when it opens. It stays open after picking a swatch and closes when the Color button is
			clicked again. Do not press Escape, that also closes the editor.
			The swatches have no name or description, so they are addressed by position.

			@swatchIndex - 1 to 10, the position of the color in the popover.
			@returns true if the swatch was clicked.
		*)
		on setAnnotateColorByIndex(swatchIndex)
			if running of application "CleanShot X" is false then return false
			if swatchIndex < 1 or swatchIndex > 10 then return false

			set colorButton to _findAnnotateColorButton()
			if colorButton is missing value then return false

			-- A click on a background app only activates it, so CleanShot X must be frontmost.
			tell application "System Events" to tell process "CleanShot X"
				set frontmost to true
			end tell
			delay 0.2

			set wasPopoverOpen to _findColorPopover() is not missing value
			if not wasPopoverOpen then
				set cliclickInstance to cliclickLib's new()
				lclick of cliclickInstance at colorButton
			end if

			set colorPopover to missing value
			repeat 20 times
				set colorPopover to _findColorPopover()
				if colorPopover is not missing value then exit repeat
				delay 0.1
			end repeat
			if colorPopover is missing value then return false

			set swatchClicked to false
			tell application "System Events" to tell process "CleanShot X"
				try
					set swatchGroup to group swatchIndex of list 1 of list 1 of colorPopover
					set cliclickInstance to cliclickLib's new()
					lclick of cliclickInstance at swatchGroup
					set swatchClicked to true
				end try
			end tell

			if not wasPopoverOpen then
				delay 0.1
				set cliclickInstance to cliclickLib's new()
				lclick of cliclickInstance at colorButton
			end if

			swatchClicked
		end setAnnotateColorByIndex


		on _findAnnotateColorButton()
			tell application "System Events" to tell process "CleanShot X"
				try
					set editorWindow to first window whose name is "CleanShot"
					return first button of group 1 of toolbar 1 of editorWindow whose help is "Color"
				end try
			end tell

			missing value
		end _findAnnotateColorButton


		on _findColorPopover()
			tell application "System Events" to tell process "CleanShot X"
				try
					return first window whose subrole is "AXSystemDialog"
				end try
			end tell

			missing value
		end _findColorPopover
	end script
end decorate

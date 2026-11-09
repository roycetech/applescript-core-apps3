(*
	@Purpose:
		Handlers for detecting which primary (left) side bar panel is showing, e.g. Explorer or Search.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-side-bar'

	@Created: Fri, Nov 06, 2026, at 10:33:37 AM
	@Last Modified: Fri, Nov 06, 2026, at 10:33:37 AM

	@Change Logs:
		Fri, Nov 06, 2026, at 10:33:37 AM - AI Added getPrimarySideBarPanel(), isExplorerPanelShowing(), isSearchPanelShowing() and switchSideBarPanel(), reading the accessibility description of the side bar's first section header from a fixed index path. See "## Primary side bar" in ui-structure-notes.md. switchSideBarPanel() clicks the matching View menu item (Explorer, Search), then waits for the header to confirm.
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()

	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
		Manual: Switch To Explorer
		Manual: Switch To Search
	")

	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if

	set sutLib to script "core/cursor"
	set sut to sutLib's new()
	set sut to decorate(sut)

	logger's infof("Primary side bar panel: {}", sut's getPrimarySideBarPanel())
	logger's infof("Explorer showing: {}", sut's isExplorerPanelShowing())
	logger's infof("Search showing: {}", sut's isSearchPanelShowing())

	if caseIndex is 1 then

	else if caseIndex is 2 then

	else

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script CursorSideBarDecorator
		property parent : mainScript

		(*
			Index paths (UI element N, outermost first) from getHtmlContent() to the
			first child of the primary side bar's content container -- the section
			header whose description names the panel ("Search Section",
			"Explorer Section: <folder>", "Run Section"). Captured live 2026-11-06;
			see "## Primary side bar" in ui-structure-notes.md for how to re-derive.
		*)
		property SIDE_BAR_HEADER_PATH_CANDIDATES : {{1, 3, 1, 1, 2, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 1}}


		(*
			@returns "explorer", "search", or missing value when another panel
			(Source Control, Run and Debug, ...) is showing or the header isn't found.
		*)
		on getPrimarySideBarPanel()
			set headerDescription to _getSideBarHeaderDescription()
			if headerDescription is missing value then return missing value

			if headerDescription starts with "Explorer Section" then return "explorer"
			if headerDescription starts with "Search Section" then return "search"

			missing value
		end getPrimarySideBarPanel


		on isExplorerPanelShowing()
			getPrimarySideBarPanel() is "explorer"
		end isExplorerPanelShowing


		on isSearchPanelShowing()
			getPrimarySideBarPanel() is "search"
		end isSearchPanelShowing


		(*
			Switches the primary side bar via the View menu. The menu's check marks
			are stale until opened, so the DOM header is used to confirm instead.

			@panelName "explorer" or "search" (case-insensitive).
			@returns true when the wanted panel is showing afterwards.
		*)
		on switchSideBarPanel(panelName)
			if running of application "Cursor" is false then return false
			
			set wantedPanel to do shell script "printf %s " & quoted form of panelName & " | tr '[:upper:]' '[:lower:]'"
			if wantedPanel is "explorer" then
				set menuItemName to "Explorer"
			else if wantedPanel is "search" then
				set menuItemName to "Search"
			else
				logger's warnf("Unsupported side bar panel: {}", panelName)
				return false
			end if
			
			if getPrimarySideBarPanel() is wantedPanel then return true
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true -- Requires focus
				try
					click menu item menuItemName of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
			
			repeat 10 times
				delay 0.3
				if getPrimarySideBarPanel() is wantedPanel then return true
			end repeat
			
			false
		end switchSideBarPanel
		
		
		on _getSideBarHeaderDescription()
			if running of application "Cursor" is false then return missing value

			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value

			tell application "System Events" to tell process "Cursor"
				repeat with nextCandidatePath in SIDE_BAR_HEADER_PATH_CANDIDATES
					try
						set nextElement to htmlContent
						repeat with nextIndex in nextCandidatePath
							set nextElement to UI element (contents of nextIndex) of nextElement
						end repeat
						set headerDescription to description of nextElement as text
						if headerDescription contains " Section" then return headerDescription
					end try
				end repeat
			end tell

			missing value
		end _getSideBarHeaderDescription
	end script
end decorate

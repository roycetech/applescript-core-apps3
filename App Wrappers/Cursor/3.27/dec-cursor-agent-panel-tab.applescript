(*
	@Purpose:
		Handlers for the agent panel's chat tabs (title, count, close).

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-agent-panel-tab'

	@Created: Sat, Nov 14, 2026, at 10:00:00 AM
	@Last Modified: Sat, Nov 14, 2026, at 10:00:00 AM

	@Change Logs:
		Sat, Nov 14, 2026, at 10:00:00 AM - AI Split out of dec-cursor-agent-panel.applescript (getAgentTabTitle(), getAgentTabCount(), closeFrontAgentTab(), _getAgentTabGroup(), _findTabGroup()). Relies on _getAgentPanelCandidates() from the agent panel decorator, so decorate it first.
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
		Manual: Get Agent Tab Title
		Manual: Get Agent Tab Count
		Manual: Close Front Agent Tab
		Manual: Switch To Agent Tab
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
	
	logger's infof("Agent tab title: {}", sut's getAgentTabTitle())
	logger's infof("Agent tab count: {}", sut's getAgentTabCount())
	logger's infof("Selected agent tab index: {}", sut's getSelectedAgentTabIndex())

	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		logger's infof("Agent tab title: {}", sut's getAgentTabTitle())
		
	else if caseIndex is 3 then
		logger's infof("Agent tab count: {}", sut's getAgentTabCount())
		
	else if caseIndex is 4 then
		logger's infof("Closed: {}", sut's closeFrontAgentTab())
		
	else if caseIndex is 5 then
		set sutIndex to 1
		-- set sutIndex to 2
		logger's debugf("sutIndex: {}", sutIndex)
		
		logger's infof("Switched: {}", sut's switchToAgentTab(sutIndex))
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's injectBasic(me)
	
	script CursorAgentPanelTabDecorator
		property parent : mainScript
		
		(* @returns the title of the selected agent tab, or missing value. *)
		on getAgentTabTitle()
			set tabGroup to _getAgentTabGroup()
			if tabGroup is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextRadioButton in radio buttons of tabGroup
						if (value of nextRadioButton) is 1 then return description of group 1 of nextRadioButton
					end repeat
				end try
			end tell
			
			missing value
		end getAgentTabTitle
		
		
		(* @returns the number of agent tabs, or 0 when the tab strip isn't found. *)
		on getAgentTabCount()
			set tabGroup to _getAgentTabGroup()
			if tabGroup is missing value then return 0
			
			tell application "System Events" to tell process "Cursor"
				try
					return count of radio buttons of tabGroup
				end try
			end tell
			
			0
		end getAgentTabCount
		
		
		(* @returns the 1-based index of the selected agent tab, or 0 when none is selected or the tab strip isn't found. *)
		on getSelectedAgentTabIndex()
			set tabGroup to _getAgentTabGroup()
			if tabGroup is missing value then return 0
			
			tell application "System Events" to tell process "Cursor"
				try
					set tabCount to count of radio buttons of tabGroup
					repeat with tabIndex from 1 to tabCount
						if (value of radio button tabIndex of tabGroup) is 1 then return tabIndex
					end repeat
				end try
			end tell
			
			0
		end getSelectedAgentTabIndex
		
		
		(*
			Presses the "Close" button inside the selected agent tab, which is safer than
			focusing the tab and sending Cmd+W (which may close the wrong thing).
			@returns true if the close button was pressed.
		*)
		on closeFrontAgentTab()
			set tabGroup to _getAgentTabGroup()
			if tabGroup is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextRadioButton in radio buttons of tabGroup
						if (value of nextRadioButton) is 1 then
							perform action "AXPress" of button 1 of toolbar 1 of nextRadioButton
							return true
						end if
					end repeat
				end try
			end tell
			
			false
		end closeFrontAgentTab
		
		
		(*
			Selects an agent tab by its position in the tab strip.
			@tabIndex - 1-based tab index.
			@returns true if the tab was pressed, false if the index is out of range or the tab strip isn't found.
		*)
		on switchToAgentTab(tabIndex)
			set tabGroup to _getAgentTabGroup()
			if tabGroup is missing value then return false
			if tabIndex < 1 or tabIndex > getAgentTabCount() then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					perform action "AXPress" of radio button tabIndex of tabGroup
					return true
				end try
			end tell
			
			false
		end switchToAgentTab
		
		
		on _getAgentTabGroup()
			repeat with nextPanel in _getAgentPanelCandidates()
				set found to my _findTabGroup(contents of nextPanel)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _getAgentTabGroup
		
		
		on _findTabGroup(uiContainer)
			tell application "System Events" to tell process "Cursor"
				try
					if role of uiContainer is "AXTabGroup" and (description of radio button 1 of uiContainer) contains "Chat Editors" then return uiContainer
				end try
				
				try
					set childElements to value of attribute "AXChildren" of uiContainer
				on error
					return missing value
				end try
			end tell
			
			repeat with nextElement in childElements
				set found to my _findTabGroup(contents of nextElement)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _findTabGroup
	end script
end decorate

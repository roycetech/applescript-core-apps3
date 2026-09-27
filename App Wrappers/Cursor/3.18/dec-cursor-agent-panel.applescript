(*
	@Purpose:
		Handler's for manipulating the agent panel.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/dec-cursor-agent-panel'

	@Created: Sat, Sep 12, 2026 at 04:06:55 PM
	@Last Modified: Sat, Sep 12, 2026 at 04:06:55 PM
	
	@Change Logs:
		Fri, Sep 25, 2026, at 01:40:00 PM - Switch agent model via model picker (settings menu > Model submenu)
		Fri, Sep 25, 2026, at 08:00:00 AM - Switch agent mode via mode menu click (sidebar-aware paths)
		Thu, Sep 24, 2026, at 09:46:03 PM - 
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use cliclickLib : script "core/cliclick"

property logger : missing value

property kb : missing value
property cliclick : missing value

property TopLevel : me

property ID_MULTITASK : "60055"
property ID_ASK : "60821"
property ID_AGENT : "60814"
property ID_PLAN : "60880"
property ID_DEBUG : "60079"

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
	       Manual: Show agent panel
       	Manual: Hide agent panel
        	Manual: Focus on agent panel (Broken on multi agent)
		Manual: Switch Agent Mode

		Manual: Switch Agent Model		
		Debug: Find Agent Static Text
		Debug: Find Terminal Text Field
		Debug: Find Agent Button
		Dev: Find HTML Content
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
	
	logger's infof("Is agent panel present: {}", sut's isAgentPanelPresent())
	logger's infof("Is agent prompt input focused: {}", sut's isAgentPanelFocused())
	logger's infof("Has lingering prompt: {}", sut's hasLingeringPrompt())
	logger's debugf("UI prompt present: {}", sut's getPromptUI() is not missing value)
	logger's debugf("HTML Content found: {}", sut's getHtmlContent() is not missing value)
	logger's infof("Current agent mode: {}", sut's getAgentMode())
	logger's infof("Current agent model: {}", sut's getAgentModel())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showAgentPanel()
		
	else if caseIndex is 3 then
		sut's hideAgentPanel()
		
	else if caseIndex is 4 then
		sut's focusOnAgentPanel()
		
	else if caseIndex is 5 then
		set sutAgentMode to "Ask"
		-- set sutAgentMode to "Plan"
		set sutAgentMode to "Agent"
		logger's debugf("sutAgentMode: {}", sutAgentMode)
		
		sut's switchAgentMode(sutAgentMode)
		
	else if caseIndex is 6 then
		(*
			TODO: Fails when Right Sub-Sidebar is present.
		*)
		set sutAgentModel to "Claude Sonnet 5 High"
		-- set sutAgentModel to "Composer 2.5"
		set sutAgentModel to "Claude Opus 5.5 Medium"
		set sutAgentModel to "Composer 2.5"
		logger's debugf("sutAgentModel: {}", sutAgentModel)
		
		sut's switchAgentModel(sutAgentModel)
		
	else if caseIndex is 7 then
		return sut's _findPlanStaticText(sut's getHtmlContent())
		
	else if caseIndex is 8 then
		return sut's _findTextField(sut's getHtmlContent())
		
	else if caseIndex is 9 then
		set uiutilLib to script "core/ui-util"
		set uiUtil to uiutilLib's new()
		uiUtil's findAllButtons(sut's getHtmlContent(), "Cursor", "Agent")
		
	else if caseIndex is 10 then
		-- Use below to dynamically compute when implementatino breaks.
		set uiutilLib to script "core/ui-util"
		set uiUtil to uiutilLib's new()
		set handlerResult to uiUtil's getElectronContentRoot("Cursor", missing value) is not missing value
		log "--- Path above this in the replies"
		logger's infof("Result found? {}", handlerResult)
		
		if handlerResult then
			logger's info("Check repliest for the path")
		end if
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's injectBasic(me)
	set kb to kbLib's new()
	set cliclick to cliclickLib's new()
	
	script CursorAgentPanelDecorator
		property parent : mainScript
		
		on getAgentMode()
			set agentPanel to getAgentPanel()
			if agentPanel is missing value then return missing value
			set composerRoot to getComposerRoot(agentPanel)
			if composerRoot is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					set modeTrigger to group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of composerRoot
					set iconId to id of (value of static text 1 of group 1 of modeTrigger as text) as text
				on error the errorMessage number the errorNumber
					logger's debugf("getAgentMode: {}", errorMessage)
					return missing value
				end try
			end tell
			
			if iconId is TopLevel's ID_AGENT then return "agent"
			if iconId is TopLevel's ID_ASK then return "ask"
			if iconId is TopLevel's ID_MULTITASK then return "multitask"
			if iconId is TopLevel's ID_PLAN then return "plan"
			if iconId is TopLevel's ID_DEBUG then return "debug"
			
			logger's debugf("getAgentMode: unknown icon id {}", iconId)
			missing value
		end getAgentMode
		
		
		on switchAgentModeByKeyboard(agentMode)
			switchAgentMode(agentMode)
		end switchAgentModeByKeyboard
		
		
		on switchAgentMode(agentMode)
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			if not isAgentPanelPresent() then showAgentPanel()
			
			set currentMode to getAgentMode()
			if currentMode is not missing value and currentMode is agentMode then
				logger's debugf("Already in mode: {}", agentMode)
				return true
			end if
			
			set modeLabel to my _modeMenuLabel(agentMode)
			
			set agentPanel to getAgentPanel()
			if agentPanel is missing value then return false
			set composerRoot to getComposerRoot(agentPanel)
			if composerRoot is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
				set modeTrigger to group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of composerRoot
			end tell
			
			leftClick of cliclick at modeTrigger
			
			set menuContainer to missing value
			repeat 20 times
				try
					tell application "System Events" to tell process "Cursor"
						set menuContainer to group 1 of group 1 of group 1 of group 3 of group 2 of group 1 of htmlContent
						if (count of groups of menuContainer) > 0 then exit repeat
					end tell
				end try
				delay 0.1
			end repeat
			if menuContainer is missing value then
				logger's warn("Mode menu did not open")
				return false
			end if
			
			tell application "System Events" to tell process "Cursor"
				set menuRows to groups of menuContainer
			end tell
			repeat with aRow in menuRows
				tell application "System Events" to tell process "Cursor"
					set isMatch to exists (static text modeLabel of aRow)
				end tell
				if isMatch then
					leftClick of cliclick at (contents of aRow)
					return true
				end if
			end repeat
			
			kb's pressKey("escape")
			logger's errorf("Mode not found: {}", modeLabel)
			false
		end switchAgentMode
		
		
		(*
			@returns the model label as shown on the trigger, e.g. "Claude Opus 5.5 Medium".
		*)
		on getAgentModel()
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				textUtil's trim(name of modelTrigger)
			end tell
		end getAgentModel
		
		
		(*
			@modelName - e.g. "Claude Sonnet 5 High". Exact match is preferred, 
				otherwise the first model that starts with the given name is picked.
		*)
		on switchAgentModel(modelName)
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			if not isAgentPanelPresent() then showAgentPanel()
			
			set currentModel to getAgentModel()
			if currentModel is not missing value and my _normalizeModelName(currentModel) is my _normalizeModelName(modelName) then
				logger's debugf("Already using model: {}", modelName)
				return true
			end if
			
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			
			leftClick of cliclick at modelTrigger
			
			-- The page container index shifts while a popup is open.
			set settingsMenu to missing value
			repeat 20 times
				try
					tell application "System Events" to tell process "Cursor"
						set settingsMenu to menu 1 of group 1 of group 1 of group 3 of last group of group 1 of htmlContent
						exit repeat
					end tell
				end try
				delay 0.1
			end repeat
			if settingsMenu is missing value then
				logger's warn("Model settings menu did not open")
				return false
			end if
			
			tell application "System Events" to tell process "Cursor"
				set modelMenuItem to last menu item of last group of settingsMenu
			end tell
			leftClick of cliclick at modelMenuItem
			
			set modelListMenu to missing value
			repeat 20 times
				try
					tell application "System Events" to tell process "Cursor"
						set modelListMenu to menu 1 of group 1 of group 1 of group 1 of group 2 of group 3 of last group of group 1 of htmlContent
						exit repeat
					end tell
				end try
				delay 0.1
			end repeat
			if modelListMenu is missing value then
				logger's warn("Model list menu did not open")
				kb's pressKey("escape")
				return false
			end if
			
			set targetName to my _normalizeModelName(modelName)
			set prefixMatch to missing value
			tell application "System Events" to tell process "Cursor"
				set modelItems to menu items of groups of modelListMenu
			end tell
			repeat with groupItems in modelItems
				repeat with anItem in groupItems
					tell application "System Events" to tell process "Cursor"
						set itemName to my _normalizeModelName(name of anItem)
					end tell
					if itemName is targetName then
						leftClick of cliclick at (contents of anItem)
						return true
					end if
					if prefixMatch is missing value and itemName starts with targetName then set prefixMatch to contents of anItem
				end repeat
			end repeat
			
			if prefixMatch is not missing value then
				leftClick of cliclick at prefixMatch
				return true
			end if
			
			kb's pressKey("escape")
			kb's pressKey("escape")
			logger's errorf("Model not found: {}", modelName)
			false
		end switchAgentModel
		
		
		on _getModelTrigger()
			set agentPanel to getAgentPanel()
			if agentPanel is missing value then return missing value
			set composerRoot to getComposerRoot(agentPanel)
			if composerRoot is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return pop up button 1 of group 1 of group 2 of group 1 of group 2 of group 1 of group 1 of composerRoot
				on error the errorMessage number the errorNumber
					logger's debugf("_getModelTrigger: {}", errorMessage)
				end try
			end tell
			
			missing value
		end _getModelTrigger
		
		
		(* Strips zero-width spaces and the "NEW" badge, then lowercases. *)
		on _normalizeModelName(modelName)
			set normalized to textUtil's replace(modelName as text, character id 8203, "")
			set normalized to textUtil's trim(normalized)
			if normalized ends with " NEW" then set normalized to textUtil's trim(text 1 thru -5 of normalized)
			textUtil's lowerCase(normalized)
		end _normalizeModelName
		
		on isAgentPanelPresent()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			getPromptUI() is not missing value
		end isAgentPanelPresent
		
		
		(*
			@returns a text area.
		*)
		on getPromptUI()
			set interestingGroup to getIterestingGroupUI()
			if interestingGroup is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return text area 1 of group 1 of group 1 of group 1 of group 1 of group 1 of interestingGroup
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
			
			missing value
		end getPromptUI
		
		
		on getHtmlContent()
			if running of application "Cursor" is false then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
				end try
			end tell
			
			missing value
		end getHtmlContent
		
		on showAgentPanel()
			if isAgentPanelPresent() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			
			kb's pressCommandKey("i")
		end showAgentPanel
		
		
		on hideAgentPanel()
			if not isAgentPanelPresent() then return
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
				try
					click menu item "Secondary Side Bar" of menu 1 of menu item "Appearance" of menu 1 of menu bar item "View" of menu bar 1
				on error errorMessage number errorNumber
					logger's errorf("Error hiding agent panel: {}. Error number: {}", {errorMessage, errorNumber})
				end try
			end tell
		end hideAgentPanel
		
		
		on focusOnAgentPanel()
			if not isAgentPanelPresent() then
				showAgentPanel()
				return
			end if
			
			set promptUI to getPromptUI()
			if promptUI is missing value then return
			
			tell application "System Events" to tell process "Cursor"
				set focused of promptUI to true -- This works, so no need for cliclick.
			end tell
			
			-- leftClick of cliclick at promptUI
		end focusOnAgentPanel
		
		
		on isAgentPanelFocused()
			if not isAgentPanelPresent() then return false
			set promptUI to getPromptUI()
			if promptUI is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				focused of promptUI
			end tell
		end isAgentPanelFocused
		
		
		(*
			Warning: Very brittle.
			This UI changes depending on which agent tab is selected, and whether the left sidebar is present.
		*)
		on getIterestingGroupUI()
			set agentPanel to getAgentPanel()
			if agentPanel is missing value then return missing value
			
			getComposerRoot(agentPanel)
		end getIterestingGroupUI
		
		
		on getAgentPanel()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of htmlContent
				on error
					-- left sidebar present
					try
						return group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of htmlContent
					end try
				end try
			end tell
			
			missing value
		end getAgentPanel
		
		
		on getComposerRoot(agentPanel)
			if agentPanel is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return group 3 of group 3 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of agentPanel
				on error
					try
						return group 2 of group 2 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of agentPanel
					end try
				end try
			end tell
			
			missing value
		end getComposerRoot
		
		
		on _modeMenuLabel(agentMode)
			set agentModeLower to textUtil's lowerCase(agentMode)
			if agentModeLower is "ask" then return "Ask"
			if agentModeLower is "plan" then return "Plan"
			if agentModeLower is "agent" then return "Agent"
			if agentModeLower is "debug" then return "Debug"
			if agentModeLower is "multitask" then return "Multitask"
			agentMode
		end _modeMenuLabel
		
		
		
		on hasLingeringPrompt()
			if not isAgentPanelPresent() then return false
			set promptUI to getPromptUI()
			if promptUI is missing value then return false
			
			
			
			tell application "System Events" to tell process "Cursor"
				set lingeringPrompt to textUtil's trim(value of promptUI)
				if lingeringPrompt is not "" then
					logger's debugf("lingeringPrompt: {}", lingeringPrompt)
				end if
			end tell
			lingeringPrompt is not ""
		end hasLingeringPrompt
		
		
		on _findPlanStaticText(uicontainer)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextStaticText in static texts of uicontainer
						set textValue to value of nextStaticText
						if textValue is missing value then set textValue to name of nextStaticText
						if textValue starts with "Plan" then return contents of nextStaticText
					end repeat
				end try
				
				repeat with nextGroup in groups of uicontainer
					set found to my _findPlanStaticText(nextGroup)
					if found is not missing value then return found
				end repeat
			end tell
			
			missing value
		end _findPlanStaticText
		
		
		on _findTextField(uicontainer)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextTextField in text fields of uicontainer
						return nextTextField
					end repeat
				end try
				
				repeat with nextGroup in groups of uicontainer
					set found to my _findTextField(nextGroup)
					if found is not missing value then return found
				end repeat
				
			end tell
			
			missing value
		end _findTextField
	end script
end decorate

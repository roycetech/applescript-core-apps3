(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.18/dec-cursor-agent-panel'

	@Created: Sat, Sep 12, 2026 at 04:06:55 PM
	@Last Modified: Sat, Sep 12, 2026 at 04:06:55 PM
	
	@Change Logs:
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use kbLib : script "core/keyboard"
use cliclickLib : script "core/cliclick"

property logger : missing value

property kb : missing value
property cliclick : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Main
        	Manual: Show agent panel
        	Manual: Hide agent panel
        	Manual: Focus on agent panel
		Dummy
		
		Debug: Find Agent Static Text
		Debug: Find Terminal Text Field
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
	logger's infof("Has lingering prompt: {}", sut's hasLingeringPrompt())
	logger's debugf("UI prompt: {}", sut's getPromptUI() is not missing value)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showAgentPanel()
		
	else if caseIndex is 3 then
		sut's hideAgentPanel()
		
	else if caseIndex is 4 then
		sut's focusOnAgentPanel()
		
	else if caseIndex is 6 then
		return sut's _findPlanStaticText(sut's getHtmlContent())
		
	else if caseIndex is 7 then
		return sut's _findTextField(sut's getHtmlContent())
		
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
		
		on isAgentPanelPresent()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			getPromptUI() is not missing value
		end isAgentPanelPresent
		
		
		(*
			@returns a text area.
		*)
		on getPromptUI()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					-- return static text 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 3 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of htmlContent
					
					return text area 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 3 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of htmlContent
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
			
			kb's pressCommandKey("i")
		end showAgentPanel
		
		
		on hideAgentPanel()
			if not isAgentPanelPresent() then return
			
			tell application "System Events" to tell process "Cursor"
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
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				set agentPromptInput to static text "Plan, Build, / for skills, @ for context" of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 3 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 2 of group 1 of htmlContent
				set focused of agentPromptInput to true
			end tell
			leftClick of cliclick at agentPromptInput
		end focusOnAgentPanel
		
		
		on hasLingeringPrompt()
			if not isAgentPanelPresent() then return false
			set promptUI to getPromptUI()
			if promptUI is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				textUtil's trim(value of promptUI) is not ""
			end tell
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

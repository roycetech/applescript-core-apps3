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
		Sun, Sep 27, 2026, at 09:35:00 AM - Fix Model submenu reveal: find the Model item by label instead of position, hover it (clicking toggles a different quick setting) via a horizontal slide-in so the pointer never crosses the row above (which opened Effort/Context/Thinking instead), verify the revealed list by size before typing into it, and refetch dynamic-name references (model trigger, Model item) fresh each retry instead of reusing a stale one
		Sat, Sep 26, 2026, at 07:05:00 PM - Update getAgentPanel/getComposerRoot paths for Cursor 3.22 layout
		Fri, Sep 25, 2026, at 01:40:00 PM - Switch agent model via model picker (settings menu > Model submenu)
		Fri, Sep 25, 2026, at 08:00:00 AM - Switch agent mode via mode menu click (sidebar-aware paths)
		Thu, Sep 24, 2026, at 09:46:03 PM - 
*)
use scripting additions
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
		set sutAgentMode to "Plan"
		-- set sutAgentMode to "Agent"
		logger's debugf("sutAgentMode: {}", sutAgentMode)
		
		sut's switchAgentMode(sutAgentMode)
		
	else if caseIndex is 6 then
		(*
			TODO: Fails when Right Sub-Sidebar is present.
		*)
		set sutAgentModel to "Claude Sonnet 5"
		set sutAgentModel to "Composer 2.5"
		set sutAgentModel to "Grok 4.6"
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
			
			(*
				The mode dropdown's rows aren't exposed to the accessibility tree at all
				(unlike the model picker, which is a real native menu) -- confirmed by an
				exhaustive live search that found nothing even while the dropdown was open
				on screen. So instead of finding and clicking a row, type the mode name into
				the dropdown's type-ahead filter and confirm with Return.
			*)
			set promptUI to getPromptUI()
			set originalPromptValue to ""
			if promptUI is not missing value then
				tell application "System Events" to tell process "Cursor"
					try
						set originalPromptValue to value of promptUI as text
					end try
				end tell
			end if
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
				set modeTrigger to group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of composerRoot
			end tell
			delay 0.15
			
			repeat 3 times
				leftClick of cliclick at modeTrigger
				delay 0.35
				
				kb's typeText(modeLabel)
				delay 0.2
				
				-- Safety net: if the click missed and the dropdown never opened, these
				-- keystrokes would land in the prompt textarea instead of the (invisible)
				-- dropdown filter. Detect that and clean it up rather than risk hitting
				-- Return and sending it as a message.
				set typedIntoPrompt to false
				if promptUI is not missing value then
					tell application "System Events" to tell process "Cursor"
						try
							set typedIntoPrompt to (value of promptUI as text) is not originalPromptValue
						end try
					end tell
				end if
				
				if typedIntoPrompt then
					tell application "System Events" to tell process "Cursor"
						set focused of promptUI to true
					end tell
					kb's pressCommandKey("a")
					kb's pressKey("delete")
					if originalPromptValue is not "" then kb's typeText(originalPromptValue)
				else
					kb's pressKey("return")
					delay 0.3
					
					set currentMode to getAgentMode()
					if currentMode is not missing value and currentMode is agentMode then return true
					
					kb's pressKey("escape")
				end if
			end repeat
			
			logger's errorf("Mode not found: {}", modeLabel)
			false
		end switchAgentMode
		
		
		(*
			@returns the model label as shown on the trigger, e.g. "Claude Opus 5.5 Medium".
		*)
		on getAgentModel()
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return missing value
			
			(*
				modelTrigger is a live reference chained back through composerRoot/
				agentPanel/htmlContent. Resolving it once in _getModelTrigger() doesn't
				guarantee it's still resolvable here a moment later -- wrap it, matching
				getAgentMode(), instead of letting a transient re-render crash the caller.
			*)
			tell application "System Events" to tell process "Cursor"
				try
					return textUtil's trim(name of modelTrigger)
				on error the errorMessage number the errorNumber
					logger's debugf("getAgentModel: {}", errorMessage)
				end try
			end tell
			
			missing value
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
			if currentModel is not missing value and my _normalizeModelName(currentModel) starts with my _normalizeModelName(modelName) then
				logger's debugf("Already using model: {}", modelName)
				return true
			end if
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			delay 0.15
			
			set targetName to my _stripEffortSuffix(modelName)
			
			(*
				modelTrigger is fetched fresh on every attempt (not once, outside the loop):
				it's a pop up button whose name IS the current model, and AppleScript bakes
				that name into the reference when it crosses into cliclick's handler -- reusing
				a stale one after any re-render throws "Can't get pop up button '<old name>' ...".
			*)
			repeat 3 times
				set modelTrigger to _getModelTrigger()
				if modelTrigger is missing value then
					logger's debug("switchAgentModel: model trigger not found, retrying")
				else
					leftClick of cliclick at modelTrigger given relativex:10
					
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
						logger's debug("switchAgentModel: settings menu did not open, retrying")
					else
						(*
							Locate the Model item by its label, not by position -- picking
							the last group's last item landed on Effort in practice, since
							the group/item count varies by which quick toggles the current
							model exposes (Fast/Context/Effort aren't always the same count).
						*)
						set modelListMenu to missing value
						repeat 3 times
							set modelMenuItem to my _findModelMenuItem(settingsMenu)
							if modelMenuItem is missing value then
								logger's debug("switchAgentModel: Model menu item not found, retrying")
								kb's pressKey("escape")
								delay 0.2
							else
								(*
									This item's submenu isn't a real nested NSMenu (it structurally
									reports zero submenus) -- clicking it acts like a toggle/select
									rather than "open submenu" (confirmed live: it can flip a
									different quick toggle instead of opening Model). Hovering
									reveals it correctly, same as a natural mouseover on a cascading
									menu -- but an instant jump-to-target hover doesn't always land
									(this custom-rendered menu needs a real mouseenter, and System
									Events' own "select" command doesn't trigger it either, confirmed
									live). Sliding in horizontally at the item's own row first
									tested noticeably more reliable live than jumping straight there.
									modelMenuItem is refetched fresh each attempt too: same
									dynamic-name staleness as modelTrigger (its name is
									"Model <current model>").
								*)
								my _hoverModelMenuItem(modelMenuItem)
								
								set candidateMenu to missing value
								repeat 20 times
									try
										tell application "System Events" to tell process "Cursor"
											set candidateMenu to menu 1 of group 1 of group 1 of group 1 of group 2 of group 3 of last group of group 1 of htmlContent
											exit repeat
										end tell
									end try
									delay 0.1
								end repeat
								
								if candidateMenu is missing value then
									-- keep retrying
								else if not my _looksLikeModelList(candidateMenu) then
									logger's debug("switchAgentModel: opened a different quick-toggle list instead of Model, retrying hover")
									kb's pressKey("escape")
									delay 0.2
								else
									set modelListMenu to candidateMenu
									exit repeat
								end if
							end if
						end repeat
						
						if modelListMenu is missing value then
							logger's debug("switchAgentModel: model list menu did not open, retrying")
							kb's pressKey("escape")
						else
							kb's typeText(targetName)
							delay 0.2
							kb's pressKey("return")
							delay 0.5
							
							set currentModel to getAgentModel()
							if currentModel is not missing value and my _normalizeModelName(currentModel) starts with my _normalizeModelName(modelName) then
								-- Defensive: Return doesn't always fully close every level; a
								-- stray leftover here corrupted the NEXT call's detection.
								-- One escape wasn't enough in practice -- confirmed live it can
								-- take 3 to fully clear.
								repeat 3 times
									kb's pressKey("escape")
									delay 0.15
								end repeat
								return true
							end if
							
							kb's pressKey("escape")
							kb's pressKey("escape")
						end if
					end if
				end if
			end repeat
			
			logger's errorf("Model not found: {}", modelName)
			false
		end switchAgentModel
		
		
		(*
			Finds the settings menu item that opens the Model submenu, by label rather
			than position ("last group's last item" was landing on Effort in practice).
		*)
		on _findModelMenuItem(settingsMenu)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextGroup in groups of settingsMenu
						repeat with nextItem in menu items of nextGroup
							set itemName to ""
							try
								set itemName to name of nextItem
							end try
							if itemName starts with "Model " or itemName is "Model" then return contents of nextItem
						end repeat
					end repeat
				end try
			end tell
			
			missing value
		end _findModelMenuItem
		
		
		(*
			Effort/Context/Thinking (whichever quick toggles the current model exposes)
			all cascade via the same fixed path as the Model list -- they're each just
			whatever submenu is currently attached at that slot, and there can be more
			than one wrong target (Sonnet alone has Thinking, Context, and Effort besides
			Model). Rather than naming every wrong list, use size: those toggle lists are
			a handful of items (Effort has 5), while the real Model list had 15+ live.
		*)
		on _looksLikeModelList(candidateMenu)
			tell application "System Events" to tell process "Cursor"
				try
					set totalItems to 0
					repeat with nextGroup in groups of candidateMenu
						set totalItems to totalItems + (count of menu items of nextGroup)
					end repeat
					return totalItems > 8
				on error
					return false
				end try
			end tell
		end _looksLikeModelList
		
		
		(*
			An instant jump-to-target mouse move doesn't reliably trigger this custom
			menu's own hover/mouseenter handling. Sliding in helps -- but landing just
			above first (tried initially) lands ON the item directly above (Effort, for
			models with Thinking/Context/Effort ahead of Model), hovering that first and
			firing exactly the wrong-list bug this is meant to avoid. Approaching
			horizontally instead -- landing to the side at the SAME row, then sliding onto
			the center -- never crosses a different item's row.
		*)
		on _hoverModelMenuItem(theItem)
			tell application "System Events" to tell process "Cursor"
				try
					set {itemX, itemY} to position of theItem
					set {itemW, itemH} to size of theItem
				on error
					return
				end try
			end tell
			
			set targetX to itemX + (itemW div 2)
			set targetY to itemY + (itemH div 2)
			set sideX to itemX - 20
			if sideX < 0 then set sideX to itemX + 5
			
			set cliclickCli to cliclickLib's CLICLICK_CLI
			set sideCommand to cliclickCli & " m:" & sideX & "," & targetY
			set targetCommand to cliclickCli & " m:" & targetX & "," & targetY
			try
				do shell script sideCommand
				delay 0.15
				do shell script targetCommand
			end try
		end _hoverModelMenuItem
		
		
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
		
		
		(* Strips zero-width spaces and the "NEW" badge, drops any effort suffix, then lowercases. *)
		on _normalizeModelName(modelName)
			set normalized to textUtil's replace(modelName as text, character id 8203, "")
			set normalized to textUtil's trim(normalized)
			if normalized ends with " NEW" then set normalized to textUtil's trim(text 1 thru -5 of normalized)
			set normalized to my _stripEffortSuffix(normalized)
			textUtil's lowerCase(normalized)
		end _normalizeModelName
		
		
		(*
			The Model submenu only lists base model names -- effort (Low/Medium/High/
			Extra High/Max) and speed (Fast) are separate controls (their own menu item).
			A caller-supplied name like "Claude Sonnet 5 High" won't match any Model
			submenu item as-is, so strip a trailing effort/speed word for matching and
			for what gets typed into that submenu. Effort itself is left untouched.
		*)
		on _stripEffortSuffix(modelName)
			set trimmedName to textUtil's trim(modelName as text)
			set lowerName to textUtil's lowerCase(trimmedName)
			set effortSuffixes to {" extra high", " medium", " high", " low", " max", " fast"}
			repeat with nextSuffix in effortSuffixes
				set suffixText to nextSuffix as text
				if lowerName ends with suffixText then
					return textUtil's trim(text 1 thru ((length of trimmedName) - (length of suffixText)) of trimmedName)
				end if
			end repeat
			trimmedName
		end _stripEffortSuffix
		
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
			
			set candidatePanel to missing value
			tell application "System Events" to tell process "Cursor"
				try
					set candidatePanel to group 1 of group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
			end tell
			if my _hasComposerChrome(candidatePanel) then return candidatePanel
			
			set candidatePanel to missing value
			tell application "System Events" to tell process "Cursor"
				try
					set candidatePanel to group 1 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
			end tell
			if my _hasComposerChrome(candidatePanel) then return candidatePanel
			
			set candidatePanel to missing value
			tell application "System Events" to tell process "Cursor"
				try
					set candidatePanel to group 1 of group 3 of group 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
			end tell
			if my _hasComposerChrome(candidatePanel) then return candidatePanel
			
			missing value
		end getAgentPanel
		
		
		on _hasComposerChrome(agentPanel)
			if agentPanel is missing value then return false
			set composerRoot to my getComposerRoot(agentPanel)
			if composerRoot is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					return exists (pop up button 1 of group 1 of group 2 of group 1 of group 2 of group 1 of group 1 of composerRoot)
				end try
			end tell
			false
		end _hasComposerChrome
		
		
		on getComposerRoot(agentPanel)
			if agentPanel is missing value then return missing value
			
			tell application "System Events" to tell process "Cursor"
				try
					return group 3 of group 3 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of agentPanel
				on error
					try
						return group 2 of group 2 of group 2 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of agentPanel
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

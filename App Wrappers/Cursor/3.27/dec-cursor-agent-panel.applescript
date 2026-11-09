(*
	@Purpose:
		Handler's for manipulating the agent panel.

	@See:
		ui-structure-notes.md (same folder) -- captured live AX tree structure,
		known-broken paths, and the recipe for re-deriving MODE_TOOLBAR_PATH when
		Cursor's layout shifts again.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-agent-panel'

	@Created: Sat, Sep 12, 2026 at 04:06:55 PM
	@Last Modified: Sat, Sep 12, 2026 at 04:06:55 PM
	
	@Change Logs:
		Sat, Nov 07, 2026, at 10:00:00 AM - AI Fixed isAgentProcessing(): while processing, the composer row loses its voice-chat child instead of showing a "Stop" button, so it now returns true when the composer row resolves but the action button is missing (COMPOSER_ROW_PATH + COMPOSER_ACTION_BUTTON_PATH).
		Fri, Nov 06, 2026, at 10:30:00 AM - AI Added isAgentPanelNarrow() and widenAgentPanelIfNarrow() (drags the panel's left edge until the mode label is visible again); getAgentMode() widens a narrow panel first. Added narrowAgentPanel() (shrinks the panel to the minimum width that isAgentPanelNarrow() still reports false).
		Wed, Nov 04, 2026, at 01:15:00 PM - AI Added isAgentProcessing() (fixed-path read of the composer action button, COMPOSER_ACTION_BUTTON_PATH), getAgentTabTitle(), getAgentTabCount() and closeFrontAgentTab().
		Tue, Nov 03, 2026, at 02:15:00 PM - AI Fixed MODE_TOOLBAR_PATH (broke getAgentMode()/switchAgentMode()): replaced with MODE_TOOLBAR_PATH_CANDIDATES, since positions 18-19 flip based on single vs. multiple agent tabs rather than drifting. Updated ui-structure-notes.md.
		Thu, Oct 29, 2026, at 11:00:00 AM - AI Fixed getAgentMode()/switchAgentMode() for the 3.27 layout (mode is now plain text; toolbar located via hardcoded MODE_TOOLBAR_PATH for speed, needs re-deriving when the layout shifts; returns missing value when the panel is too narrow). Added switchAgentModeByKeyboard(), cycling modes with Cmd+. (~2-3s vs ~5s).
		Tue, Oct 27, 2026, at 10:00:00 AM - AI Cursor 3.27: also look in the "Cursor Agents" window; prompt input is now a text area inside an editor grid; getPromptUI falls back to a direct path from the HTML content so isAgentPanelPresent works again
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

		Manual: Switch Agent Model - Composer
		Manual: Switch Agent Model - Grok
		Debug: Find Agent Static Text
		Debug: Find Terminal Text Field
		Debug: Find Agent Button

		Dev: Find HTML Content
		Manual: Switch Agent Effort - Extra High
		Manual: Switch Agent Effort - High
		Manual: Close Front Agent Tab
		Manual: Widen Agent Panel If Narrow
		
		Manual: Narrow Agent Panel To Minimum
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
	
	tell application "System Events" to tell process "Cursor"
		-- set frontmost to true
	end tell
	
	logger's infof("Is agent processing: {}", sut's isAgentProcessing())
	logger's infof("Is agent panel present: {}", sut's isAgentPanelPresent())
	logger's infof("Is agent prompt input focused: {}", sut's isAgentPanelFocused())
	logger's infof("Has lingering prompt: {}", sut's hasLingeringPrompt())
	logger's infof("Agent tab title: {}", sut's getAgentTabTitle())
	logger's infof("Agent tab count: {}", sut's getAgentTabCount())
	logger's debugf("UI prompt present: {}", sut's getPromptUI() is not missing value)
	logger's debugf("HTML Content found: {}", sut's getHtmlContent() is not missing value)
	logger's infof("Current agent mode(wide-panel only): {}", sut's getAgentMode())
	logger's infof("Current agent model: {}", sut's getAgentModel())
	logger's infof("Current agent effort: {}", sut's getAgentEffort())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showAgentPanel()
		
	else if caseIndex is 3 then
		sut's hideAgentPanel()
		
	else if caseIndex is 4 then
		sut's focusOnAgentPanel()
		
	else if caseIndex is 5 then
		logger's debug(1)
		set sutAgentMode to "Ask"
		-- set sutAgentMode to "Plan"
		set sutAgentMode to "Agent"
		logger's debugf("sutAgentMode: {}", sutAgentMode)
		
		
		
		sut's switchAgentMode(sutAgentMode)
		-- logger's debug(2)
		
	else if caseIndex is 6 then
		(*
			TODO: Fails when Right Sub-Sidebar is present.
		*)
		set sutAgentModel to "Composer 2.5"
		logger's debugf("sutAgentModel: {}", sutAgentModel)
		
		sut's switchAgentModel(sutAgentModel)
		
	else if caseIndex is 7 then
		(*
			TODO: Fails when Right Sub-Sidebar is present.
		*)
		set sutAgentModel to "Grok 4.6"
		logger's debugf("sutAgentModel: {}", sutAgentModel)
		
		sut's switchAgentModel(sutAgentModel)
		
	else if caseIndex is 8 then
		return sut's _findPlanStaticText(sut's getHtmlContent())
		
	else if caseIndex is 9 then
		return sut's _findTextField(sut's getHtmlContent())
		
	else if caseIndex is 10 then
		set uiutilLib to script "core/ui-util"
		set uiUtil to uiutilLib's new()
		uiUtil's findAllButtons(sut's getHtmlContent(), "Cursor", "Agent")
		
	else if caseIndex is 11 then
		-- Use below to dynamically compute when implementatino breaks.
		set uiutilLib to script "core/ui-util"
		set uiUtil to uiutilLib's new()
		set handlerResult to uiUtil's getElectronContentRoot("Cursor", missing value) is not missing value
		log "--- Path above this in the replies"
		logger's infof("Result found? {}", handlerResult)
		
		if handlerResult then
			logger's info("Check repliest for the path")
		end if
		
	else if caseIndex is 12 then
		set sutAgentEffort to "Extra High"
		logger's debugf("sutAgentEffort: {}", sutAgentEffort)
		
		sut's switchAgentEffort(sutAgentEffort)
		
	else if caseIndex is 13 then
		set sutAgentEffort to "High"
		logger's debugf("sutAgentEffort: {}", sutAgentEffort)
		
		sut's switchAgentEffort(sutAgentEffort)
		
	else if caseIndex is 14 then
		logger's infof("Closed: {}", sut's closeFrontAgentTab())
		
	else if caseIndex is 15 then
		logger's infof("Is agent panel narrow: {}", sut's isAgentPanelNarrow())
		logger's infof("Widened: {}", sut's widenAgentPanelIfNarrow())
		logger's infof("Is agent panel narrow now: {}", sut's isAgentPanelNarrow())
		
	else if caseIndex is 16 then
		logger's infof("Narrowed: {}", sut's narrowAgentPanel())
		logger's infof("Is agent panel narrow now: {}", sut's isAgentPanelNarrow())
	end if
	
	activate
	
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
		
		(*
			Hardcoded for speed, not resilience: live group-index paths (from
			getHtmlContent() down to the composer toolbar row) for THIS Cursor
			3.27 build, captured by walking up from the model picker pop up button.
			The mode indicator is item 1 of this row's sibling groups.

			Confirmed live 2026-11-03: positions 18-19 flip between {2, 3} (many
			agent tabs open) and {3, 4} (a single agent tab) -- not drift, a
			genuine layout difference based on tab count -- so both are carried
			as candidates, tried in order, rather than picking one. Will still
			need a new candidate added if Cursor's layout shifts again.
		*)
		property MODE_TOOLBAR_PATH_CANDIDATES : {{1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 2, 3, 1, 1, 2, 1}, {1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 3, 4, 1, 1, 2, 1}}
		
		on _getModeTriggerGroup()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			repeat with candidatePath in MODE_TOOLBAR_PATH_CANDIDATES
				set found to my _resolveModeToolbarPath(htmlContent, contents of candidatePath)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _getModeTriggerGroup
		
		
		(* @returns the element reached by walking indexPath as "group N of ... of rootElement", then its first sibling UI element, or missing value. *)
		on _resolveModeToolbarPath(rootElement, indexPath)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to rootElement
					repeat with nextIndex in indexPath
						set currentElement to group (contents of nextIndex) of currentElement
					end repeat
					return item 1 of (UI elements of currentElement)
				on error
					return missing value
				end try
			end tell
		end _resolveModeToolbarPath
		
		
		(*
			@returns the current mode ("agent", "ask", "plan", "multitask", "debug")
				read from the toolbar's visible mode label. A narrow panel hides that
				label (the icon alone carries no accessible id/description/tooltip), so
				the panel is widened first; missing value if it still can't be read.
				switchAgentMode() and switchAgentModeByKeyboard() read the mode through
				this, so they get the widening too.
		*)
		on getAgentMode()
			widenAgentPanelIfNarrow()
			set modeTriggerGroup to my _getModeTriggerGroup()
			if modeTriggerGroup is missing value then return missing value
			
			set knownModes to {"agent", "ask", "plan", "multitask", "debug"}
			tell application "System Events" to tell process "Cursor"
				try
					set modeGroupElements to entire contents of modeTriggerGroup
					repeat with nextStaticText in modeGroupElements
						if class of nextStaticText is static text then
							set textValue to textUtil's lowerCase(value of nextStaticText as text)
							if knownModes contains textValue then return textValue
						end if
					end repeat
				on error the errorMessage number the errorNumber
					logger's debugf("getAgentMode: {}", errorMessage)
					return missing value
				end try
			end tell
			
			missing value
		end getAgentMode
		
		
		(*
			Alternative to switchAgentMode(): cycles modes with the Cmd+. shortcut
			and reads getAgentMode() back after each press, instead of clicking the
			dropdown and typing the mode name into its filter. Kept as a separate
			option rather than replacing switchAgentMode() -- untested against the
			dropdown approach's edge cases (narrow panel in particular: Cmd+. still
			cycles blind there, since getAgentMode() can't read back the result
			either way, so this just presses once and trusts it, same tradeoff as
			switchAgentMode()'s own narrow-panel fallback).

			Caps at one full cycle (5 presses, one per known mode) so a stuck/
			unreadable mode can't spin forever.
		*)
		on switchAgentModeByKeyboard(agentMode)
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			set promptUI to getPromptUI()
			if promptUI is missing value then
				showAgentPanel()
				set promptUI to getPromptUI()
			end if
			
			set currentMode to getAgentMode()
			if currentMode is not missing value and currentMode is agentMode then
				logger's debugf("Already in mode: {}", agentMode)
				return true
			end if
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			delay 0.15
			
			set knownModeCount to 5 -- agent, ask, plan, multitask, debug
			repeat knownModeCount times
				kb's pressCommandKey(".")
				delay 0.3
				
				set currentMode to getAgentMode()
				if currentMode is not missing value then
					if currentMode is agentMode then return true
				else
					-- Can't read the mode back (narrow panel) -- same limitation as
					-- switchAgentMode(), so trust this one press rather than blindly
					-- cycling further with no way to tell if we've already landed on it.
					logger's debug("switchAgentModeByKeyboard: can't verify mode in narrow panel, trusting the press")
					return true
				end if
			end repeat
			
			logger's errorf("Mode not found via Cmd+. cycling: {}", agentMode)
			false
		end switchAgentModeByKeyboard
		
		
		on switchAgentMode(agentMode)
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			(*
				getPromptUI() resolved once and reused below (for the presence check AND
				originalPromptValue) instead of calling it twice -- it's not cheap (~2s,
				it walks several fallback paths), and isAgentPanelPresent() + a separate
				getPromptUI() call used to each pay that cost independently.
			*)
			set promptUI to getPromptUI()
			if promptUI is missing value then
				showAgentPanel()
				set promptUI to getPromptUI()
			end if
			
			set currentMode to getAgentMode()
			if currentMode is not missing value and currentMode is agentMode then
				logger's debugf("Already in mode: {}", agentMode)
				return true
			end if
			
			set modeLabel to my _modeMenuLabel(agentMode)
			
			set modeTrigger to my _getModeTriggerGroup()
			if modeTrigger is missing value then return false
			
			(*
				The mode dropdown's rows aren't exposed to the accessibility tree at all
				(unlike the model picker, which is a real native menu) -- confirmed by an
				exhaustive live search that found nothing even while the dropdown was open
				on screen. So instead of finding and clicking a row, type the mode name into
				the dropdown's type-ahead filter and confirm with Return.
			*)
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
					if currentMode is not missing value then
						if currentMode is agentMode then return true
						kb's pressKey("escape")
					else
						-- Agent panel is too narrow to read the mode label back (icon-only,
						-- no accessible text/id/tooltip to confirm against). The keystrokes
						-- went into the dropdown's filter, not the prompt, so trust the switch
						-- rather than retrying blindly and reporting a false failure.
						logger's debug("switchAgentMode: can't verify mode in narrow panel, trusting the switch")
						return true
					end if
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
					leftClick of cliclick at modelTrigger given fromLeft:10
					
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
		
		
		(*
			@returns the effort label as shown embedded in the model trigger's name,
				e.g. "Medium" out of "Grok 4.6 Medium Fast". "Fast" is a separate speed
				toggle that can trail the effort word on the same label -- it's stripped
				first so the effort suffix check below lines up against the new end.
				The trigger's name can carry a zero-width space (same issue
				_normalizeModelName works around) that makes "ends with" silently miss
				every suffix, so that's stripped here too before any comparison.
		*)
		on getAgentEffort()
			set modelLabel to getAgentModel()
			if modelLabel is missing value then return missing value
			
			set trimmedLabel to textUtil's replace(modelLabel as text, character id 8203, "")
			set trimmedLabel to textUtil's trim(trimmedLabel)
			set lowerLabel to textUtil's lowerCase(trimmedLabel)
			
			if lowerLabel ends with " fast" then
				set trimmedLabel to textUtil's trim(text 1 thru ((length of trimmedLabel) - 5) of trimmedLabel)
				set lowerLabel to textUtil's lowerCase(trimmedLabel)
			end if
			
			set effortSuffixes to {" extra high", " medium", " high", " low", " max"}
			repeat with nextSuffix in effortSuffixes
				set suffixText to nextSuffix as text
				if lowerLabel ends with suffixText then
					return textUtil's trim(text ((length of trimmedLabel) - (length of suffixText) + 1) thru (length of trimmedLabel) of trimmedLabel)
				end if
			end repeat
			
			missing value
		end getAgentEffort
		
		
		(*
			@effortName - e.g. "High", "Extra High". Switches the effort quick toggle
				exposed alongside Model in the settings menu (only some models expose it).
		*)
		on switchAgentEffort(effortName)
			if running of application "Cursor" is false then return false
			
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false
			
			if not isAgentPanelPresent() then showAgentPanel()
			
			set currentEffort to getAgentEffort()
			if currentEffort is not missing value and textUtil's lowerCase(currentEffort) is textUtil's lowerCase(effortName) then
				logger's debugf("Already using effort: {}", effortName)
				return true
			end if
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			delay 0.15
			
			(*
				Same dynamic-name staleness as switchAgentModel: modelTrigger's name IS
				the current model, so it's fetched fresh on every attempt.
			*)
			repeat 3 times
				set modelTrigger to _getModelTrigger()
				if modelTrigger is missing value then
					logger's debug("switchAgentEffort: model trigger not found, retrying")
				else
					leftClick of cliclick at modelTrigger given fromLeft:10
					
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
						logger's debug("switchAgentEffort: settings menu did not open, retrying")
					else
						set effortMenuItem to my _findEffortMenuItem(settingsMenu)
						if effortMenuItem is missing value then
							logger's debug("switchAgentEffort: Effort menu item not found, retrying")
							kb's pressKey("escape")
						else
							-- Reuse: hover mechanics here are generic (position/size based), not model-specific.
							my _hoverModelMenuItem(effortMenuItem)
							delay 0.3
							
							kb's typeText(effortName)
							delay 0.2
							kb's pressKey("return")
							delay 0.3
							
							kb's pressKey("escape")
							kb's pressKey("escape")
							delay 1
							
							set currentEffort to getAgentEffort()
							if currentEffort is not missing value and textUtil's lowerCase(currentEffort) is textUtil's lowerCase(effortName) then
								return true
							end if
						end if
					end if
				end if
			end repeat
			
			logger's errorf("Effort not found: {}", effortName)
			false
		end switchAgentEffort
		
		
		(*
			Finds the settings menu item that opens the Effort submenu, by label
			(same approach as _findModelMenuItem).
		*)
		on _findEffortMenuItem(settingsMenu)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextGroup in groups of settingsMenu
						repeat with nextItem in menu items of nextGroup
							set itemName to ""
							try
								set itemName to name of nextItem
							end try
							if itemName starts with "Effort " or itemName is "Effort" then return contents of nextItem
						end repeat
					end repeat
				end try
			end tell
			
			missing value
		end _findEffortMenuItem
		
		
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
			if interestingGroup is not missing value then
				tell application "System Events" to tell process "Cursor"
					try
						return text area 1 of group 1 of group 1 of group 1 of group 1 of group 1 of interestingGroup
					on error the errorMessage number the errorNumber
						log errorMessage
					end try
				end tell
			end if
			
			-- Cursor 3.27 layout: the prompt is no longer a text area, only a group holding the placeholder/typed text.
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			-- Fast: known group paths from the HTML content to the editor grid, the layout shifts with the window/sidebar state.
			set knownPaths to {}
			set end of knownPaths to {1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 3, 4, 1, 1, 1, 1, 1}
			set end of knownPaths to {1, 3, 1, 1, 2, 2, 1, 2, 3, 1, 1, 1, 1, 1, 2, 1, 2, 2, 3, 1, 1, 1, 1, 1}
			repeat with nextPath in knownPaths
				set editorGrid to my _groupAtPath(htmlContent, nextPath)
				if editorGrid is not missing value then return my _getEditorInput(editorGrid)
			end repeat
			
			-- Slow (~15s): find the placeholder by its text and use the editor input next to it.
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextElement in (entire contents of htmlContent)
						try
							if role of nextElement is "AXStaticText" and name of nextElement starts with "Plan, Build" then
								return my _getEditorInput(value of attribute "AXParent" of nextElement)
							end if
						end try
					end repeat
				end try
			end tell
			
			-- Cursor 3.27 also hosts the agent prompt in a separate "Cursor Agents" window.
			tell application "System Events" to tell process "Cursor"
				try
					set agentsWebArea to UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of window "Cursor Agents"
					set candidateInput to UI element 1 of UI element 1 of UI element 1 of UI element 5 of UI element 1 of UI element 4 of UI element 2 of UI element 2 of UI element 1 of UI element 1 of agentsWebArea
					set inputSize to size of candidateInput
					if (item 1 of inputSize) > 50 then return candidateInput
				end try
			end tell
			
			missing value
		end getPromptUI
		
		
		on _getEditorInput(editorGrid)
			tell application "System Events" to tell process "Cursor"
				try
					return text area 1 of editorGrid
				end try
			end tell
			
			missing value
		end _getEditorInput
		
		
		on _groupAtPath(rootElement, groupIndexes)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to rootElement
					repeat with nextIndex in groupIndexes
						set currentElement to group (contents of nextIndex) of currentElement
					end repeat
					set elementSize to size of currentElement
					if (item 1 of elementSize) > 50 then return currentElement
				end try
			end tell
			
			missing value
		end _groupAtPath
		
		
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
		
		
		(*
			Drags from the panel's drag handle to targetX along the same y. cliclick's
			plain drag (start and end only, as in core/cliclick's dragFromTo) lands
			anywhere from 0 to 100% of the distance; intermediate moves with a short wait
			between events make it exact (measured 6/6 on Cursor 3.27, 2026-11-06).
		*)
		on _dragAgentPanelHandle(handleX, handleY, targetX)
			set cliclickCli to do shell script "plutil -extract \"cliclick CLI\" raw ~/applescript-core/config-system.plist"
			set dragDistance to targetX - handleX
			set firstStepX to handleX + (dragDistance div 3)
			set secondStepX to handleX + ((dragDistance * 2) div 3)
			
			cliclick's saveCurrentPosition()
			set dragCommand to cliclickCli & " -w 15 dd:" & handleX & "," & handleY
			set dragCommand to dragCommand & " m:" & firstStepX & "," & handleY
			set dragCommand to dragCommand & " m:" & secondStepX & "," & handleY
			set dragCommand to dragCommand & " m:" & targetX & "," & handleY
			set dragCommand to dragCommand & " du:" & targetX & "," & handleY
			do shell script dragCommand
			cliclick's restorePosition()
		end _dragAgentPanelHandle
		
		
		(*
			Measured live on Cursor 3.27 (2026-11-06): the mode label is still shown at
			the narrowest width the user found, a 354px panel (301px prompt), and is gone
			at ~341px. The
			prompt text area is ~53px narrower than the panel and its left edge sits
			~28px right of the panel's drag handle, so thresholds are expressed in
			prompt width. The "wide" target is the default 406px prompt (459px panel).
		*)
		property NARROW_PROMPT_WIDTH : 300
		property WIDE_PROMPT_WIDTH : 406
		property PROMPT_LEFT_TO_PANEL_EDGE : 28
		
		
		(* @returns true when the agent panel is narrower than the width where Cursor hides the mode label. *)
		on isAgentPanelNarrow()
			set promptUI to getPromptUI()
			if promptUI is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				try
					set promptSize to size of promptUI
					return (item 1 of promptSize) < NARROW_PROMPT_WIDTH
				end try
			end tell
			
			false
		end isAgentPanelNarrow
		
		
		(*
			Drags the agent panel's left edge leftwards until it is no longer narrow
			(Cursor must be frontmost for the drag to register).
			@returns true if the panel is not narrow afterwards, false if it could not be widened.
		*)
		on widenAgentPanelIfNarrow()
			if not isAgentPanelNarrow() then return true
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			delay 0.3
			
			repeat 3 times
				set promptUI to getPromptUI()
				if promptUI is missing value then return false
				
				tell application "System Events" to tell process "Cursor"
					set promptPosition to position of promptUI
					set promptSize to size of promptUI
					set promptWidth to item 1 of promptSize
					set windowPosition to position of front window
					set windowSize to size of front window
					set windowHeight to item 2 of windowSize
				end tell
				if promptWidth is greater than or equal to NARROW_PROMPT_WIDTH then return true
				
				set handleX to (item 1 of promptPosition) - PROMPT_LEFT_TO_PANEL_EDGE
				set handleY to (item 2 of windowPosition) + (windowHeight div 2)
				set targetX to handleX - (WIDE_PROMPT_WIDTH - promptWidth)
				
				my _dragAgentPanelHandle(handleX, handleY, targetX)
				
				-- The accessibility tree lags the relayout; wait for the new width before judging the drag, or it gets repeated.
				repeat 10 times
					delay 0.3
					if not isAgentPanelNarrow() then return true
				end repeat
			end repeat
			
			not isAgentPanelNarrow()
		end widenAgentPanelIfNarrow
		
		
		(*
			Drags the agent panel's left edge until the panel is as small as it can get
			while isAgentPanelNarrow() still returns false (prompt width NARROW_PROMPT_WIDTH
			up to NARROW_PROMPT_WIDTH + 6). A drag lands a few pixels off its target, so
			this corrects with further drags, each sized from the width actually read back.
			@returns true if the panel ended up within that range, false otherwise
				(including when the panel isn't visible).
		*)
		on narrowAgentPanel()
			set promptUI to getPromptUI()
			if promptUI is missing value then return false
			
			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell
			delay 0.3
			
			set targetWidth to NARROW_PROMPT_WIDTH + 2
			repeat 5 times
				set promptUI to getPromptUI()
				if promptUI is missing value then return false
				
				tell application "System Events" to tell process "Cursor"
					set promptPosition to position of promptUI
					set promptSize to size of promptUI
					set promptWidth to item 1 of promptSize
					set windowPosition to position of front window
					set windowSize to size of front window
					set windowHeight to item 2 of windowSize
				end tell
				if promptWidth is greater than or equal to NARROW_PROMPT_WIDTH and promptWidth is less than or equal to NARROW_PROMPT_WIDTH + 6 then return true
				
				set handleX to (item 1 of promptPosition) - PROMPT_LEFT_TO_PANEL_EDGE
				set handleY to (item 2 of windowPosition) + (windowHeight div 2)
				set targetX to handleX + (promptWidth - targetWidth)
				
				my _dragAgentPanelHandle(handleX, handleY, targetX)
				
				-- Wait for the width to settle (same reading twice running, and changed) before measuring again.
				set lastWidth to promptWidth
				repeat 10 times
					delay 0.3
					set promptUI to getPromptUI()
					if promptUI is missing value then return false
					tell application "System Events" to tell process "Cursor"
						set promptSize to size of promptUI
					end tell
					set currentWidth to item 1 of promptSize
					if currentWidth is lastWidth and currentWidth is not promptWidth then exit repeat
					set lastWidth to currentWidth
				end repeat
			end repeat
			
			false
		end narrowAgentPanel
		
		
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
		
		
		(*
			@returns true while the selected agent tab is processing. The composer row's 6th child
				holds the "Start voice chat" button when idle; while processing that child is gone
				(the row has 5 children) and any "Stop" button replaces it, so a resolvable row
				without the voice button means processing.
		*)
		property COMPOSER_ROW_PATH : {1, 1, 1, 1, 2, 1, 2, 3, 4, 1, 1, 2, 1}
		property COMPOSER_ACTION_BUTTON_PATH : {6, 1, 1}
		
		on isAgentProcessing()
			repeat with nextPanel in _getAgentPanelCandidates()
				set composerRow to my _getComposerRow(contents of nextPanel)
				if composerRow is not missing value then
					set actionDescription to my _getComposerActionDescription(composerRow)
					if actionDescription is missing value then return true
					return actionDescription starts with "Stop"
				end if
			end repeat
			
			false
		end isAgentProcessing
		
		
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
		
		
		on _getAgentTabGroup()
			repeat with nextPanel in _getAgentPanelCandidates()
				set found to my _findTabGroup(contents of nextPanel)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _getAgentTabGroup
		
		
		(* Same panel paths as getAgentPanel(), without its composer-chrome check, which fails on some windows. *)
		on _getAgentPanelCandidates()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return {}
			
			set candidatePanels to {}
			tell application "System Events" to tell process "Cursor"
				try
					set end of candidatePanels to group 1 of group 3 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
				try
					set end of candidatePanels to group 1 of group 2 of group 2 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
				try
					set end of candidatePanels to group 1 of group 3 of group 1 of group 1 of group 2 of group 2 of group 1 of group 1 of group 3 of group 1 of htmlContent
				end try
			end tell
			candidatePanels
		end _getAgentPanelCandidates
		
		
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
		
		
		(* @returns the composer row (mode, model, effort and action controls) of the agent panel, or missing value. *)
		on _getComposerRow(agentPanel)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to agentPanel
					repeat with nextIndex in COMPOSER_ROW_PATH
						set currentElement to UI element (contents of nextIndex) of currentElement
					end repeat
					return currentElement
				end try
			end tell
			
			missing value
		end _getComposerRow
		
		
		(* @returns the composer action button's description ("Start voice chat" when idle), or missing value when the button is absent. *)
		on _getComposerActionDescription(composerRow)
			tell application "System Events" to tell process "Cursor"
				try
					set currentElement to composerRow
					repeat with nextIndex in COMPOSER_ACTION_BUTTON_PATH
						set currentElement to UI element (contents of nextIndex) of currentElement
					end repeat
					return description of currentElement
				end try
			end tell
			
			missing value
		end _getComposerActionDescription
		
		
		on _findPlanStaticText(uiContainer)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextStaticText in static texts of uiContainer
						set textValue to value of nextStaticText
						if textValue is missing value then set textValue to name of nextStaticText
						if textValue starts with "Plan" then return contents of nextStaticText
					end repeat
				end try
				
				repeat with nextGroup in groups of uiContainer
					set found to my _findPlanStaticText(nextGroup)
					if found is not missing value then return found
				end repeat
			end tell
			
			missing value
		end _findPlanStaticText
		
		
		on _findTextField(uiContainer)
			tell application "System Events" to tell process "Cursor"
				try
					repeat with nextTextField in text fields of uiContainer
						return nextTextField
					end repeat
				end try
				
				repeat with nextGroup in groups of uiContainer
					set found to my _findTextField(nextGroup)
					if found is not missing value then return found
				end repeat
				
			end tell
			
			missing value
		end _findTextField
	end script
end decorate

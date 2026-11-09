(*
	@Purpose:
		Wrapper to help automate the Claude app window.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Claude/4.4212/claude'

	@Created: Mon, Nov 02, 2026, at 01:27:40 PM
	@Last Modified: Mon, Nov 02, 2026, at 01:27:40 PM
	
	@Change Logs:
		Wed, Nov 04, 2026, at 12:00:00 AM - AI Documented a known gap in #getMode(): a brand-new Code session with no project folder attached yet still reads as "Chat" via the folder-attached proxy. Re-confirmed live (AXSelected/AXFocused/AXValue, AXDOMClassList diff, AXSelectedRows) that the Mode toggle exposes no readable checked state, so this can't be fixed directly - no behavior change.
		Tue, Nov 03, 2026, at 01:30:00 PM - AI Fixed #getProjectFolderName()'s hardcoded index path (drifted, threw "Invalid index", broke #getMode()); replaced with #FOLDER_PATH_CANDIDATES. Added #switchToCowork()/#switchToChat() as aliases of #switchToChatMode().
		Tue, Nov 03, 2026, at 01:15:00 PM - AI Added #toggleMode() to flip between Chat and Code mode.
		Tue, Nov 03, 2026, at 01:00:00 PM - AI Added #getMode()/#isCodeMode()/#isChatMode() and #switchToCodeMode()/#switchToChatMode() for the sidebar "Chat and Cowork"/"Code" toggle. Detection reuses getProjectFolderName()'s proxy since the radio buttons expose no checked state.
		Mon, Nov 02, 2026, at 02:45:00 PM - AI Found position 5 and 19 (of ~26) in the hardcoded paths vary independently rather than together - a 4th, previously-unseen combination showed up after switching to a different session window. Expanded #PROMPT_PATH_CANDIDATES/#MODEL_TRIGGER_PATH_CANDIDATES to the full 2x2 matrix of both positions instead of patching one combination at a time. Also found that deriving/testing paths against this very conversation's own window while a Bash command runs in the background can fail mid-scan on the live "Background tasks" elapsed-time counter - not a real layout change, just a moving target; documented in ui-structure-notes.md.
		Mon, Nov 02, 2026, at 02:30:00 PM - AI #getModel()/#getPromptUI() weren't resolving with the sidebar hidden - the candidate paths were only captured with the sidebar shown, and hiding it shifts 2 of the ~26 indices (sidebar presence changes sibling counts, same as the known-drifting indices). Added a sidebar-hidden variant to #PROMPT_PATH_CANDIDATES and #MODEL_TRIGGER_PATH_CANDIDATES; verified both shown and hidden now resolve.
		Mon, Nov 02, 2026, at 02:15:00 PM - AI Fixed #getPromptUI()/#_getModelTrigger() for this app build: the fixed "item 1 of AXChildren" chain inherited from Claude 1.4 no longer reaches them (sibling order differs at some levels on this build). Replaced with #PROMPT_PATH_CANDIDATES/#MODEL_TRIGGER_PATH_CANDIDATES - a short list of full hardcoded index paths, tried in order via #_resolveFirstMatchingPath(), per the project's explicit choice of speed over reliability (resolves in ~0s vs. several seconds for a tree search; no fallback search when all candidates fail - re-derive and add a new candidate instead). #_getMainContent()/#MAIN_CONTENT_PATH (a 3-level stable anchor + small bounded search) is kept for #switchModel()'s dropdown-menu scan, which still needs a live scoped region rather than a single fixed target. See ui-structure-notes.md for how the candidates were captured and the re-derivation recipe.
		Mon, Nov 02, 2026, at 01:40:00 PM - AI Fixed spotCheck() calling undefined #getCurrentProjectPath() (leftover from the Cursor/Sublime wrapper template, never defined here); added #sendInstruction() to type text into the prompt and submit it with Return, with its own spot-test case.
		Mon, Nov 02, 2026, at 01:27:40 PM - AI Cloned from Claude 1.4 as a starting point for version 4.4212. 
		Fri, Oct 16, 2026, at 10:03:00 AM - Added #newSessionInFolder() to click the sidebar "+" next to a project folder.
		Fri, Sep 25, 2026, at 03:40:00 PM - Added #getModel() and #switchModel() to detect/change the active model.
		Fri, Sep 25, 2026, at 03:20:06 PM - Initial working implementation created by Claude.
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use decoratorLib : script "core/decorator"

use cliclickLib : script "core/cliclick"
use kbLib : script "core/keyboard"


property logger : missing value

property cliclick : missing value
property kb : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Sidebar - Show
		Manual: Sidebar - Hide
		Manual: Focus Prompt		
		Manual: Switch Model

		Manual: New Session in Folder
		Manual: Send Instruction
		Manual: Switch To Code Mode
		Manual: Switch To Chat Mode
		Manual: Toggle Mode
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
	logger's infof("Project folder name: {}", sut's getProjectFolderName())
	logger's infof("Current mode: {}", sut's getMode())
	
	set htmlContent to sut's getHtmlContent()
	(* 
	tell application "System Events" to tell process "Claude"
		return entire contents of htmlContent
	end tell
	*)
	logger's infof("HTML Content found: {}", htmlContent is not missing value)
	logger's infof("Current model: {}", sut's getModel()) -- Slow, takes about 5s.
	logger's infof("Has sidebar: {}", sut's hasSidebar())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's showSidebar()
		
	else if caseIndex is 3 then
		sut's hideSidebar()
		
	else if caseIndex is 4 then
		sut's focusPromptInput()
		
	else if caseIndex is 5 then
		
		set sutModelName to "Opus 5.5"
		set sutModelName to "Sonnet 5"
		-- set sutModelName to "Haiku 4.5"
		logger's debugf("sutModelName: {}", sutModelName)
		
		sut's switchModel(sutModelName)
		
	else if caseIndex is 6 then
		set sutFolderName to "newplexuss"
		logger's debugf("sutFolderName: {}", sutFolderName)
		
		logger's infof("New session triggered: {}", sut's newSessionInFolder(sutFolderName))
		
	else if caseIndex is 7 then
		set sutInstruction to "What is 2 + 2?"
		logger's debugf("sutInstruction: {}", sutInstruction)
		
		logger's infof("Instruction sent: {}", sut's sendInstruction(sutInstruction))
		
	else if caseIndex is 8 then
		logger's infof("Switched to Code mode: {}", sut's switchToCodeMode())
		
	else if caseIndex is 9 then
		logger's infof("Switched to Chat mode: {}", sut's switchToChatMode())
		
	else if caseIndex is 10 then
		sut's toggleMode()
		logger's infof("Toggled mode, now: {}", sut's getMode())
		
	else
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	set kb to kbLib's new()
	
	script ClaudeInstance
		(*
			Moves the text caret into the message compose field ("Prompt"
			text area) so the user can start typing immediately.

			NOTE: The plain AppleScript `click` command (AXPress) does NOT
			move focus into Claude's ProseMirror-based prompt editor - it
			returns successfully but the field stays unfocused. Setting the
			`focused` attribute directly does work and is the fastest option,
			so it's tried first. cliclick (a real synthetic mouse click) is
			kept as a fallback in case that ever stops working.

			Human Review: May not be needed. Seems like the prompt input always receives keyboard input.
		*)
		on focusPromptInput()
			if running of application "Claude" is false then return
			
			set promptUI to getPromptUI()
			if promptUI is missing value then return
			
			tell application "System Events" to tell process "Claude"
				set frontmost to true
				
				try
					set focused of promptUI to true
					if focused of promptUI then return
				end try
			end tell
			
			leftClick of cliclick at promptUI
		end focusPromptInput
		
		
		(*
			Types @instructionText into the prompt compose field and submits
			it by pressing Return.

			@returns true if the prompt field was found and the instruction
				was sent, false otherwise.
		*)
		on sendInstruction(instructionText)
			if running of application "Claude" is false then return false
			
			focusPromptInput()
			
			set promptUI to getPromptUI()
			if promptUI is missing value then
				logger's errorf("sendInstruction: Prompt input not found for: {}", instructionText)
				return false
			end if
			
			kb's typeText(instructionText)
			kb's pressKey("return")
			true
		end sendInstruction
		
		
		(*
			Full UI-element-index paths from getHtmlContent() straight to the
			"Prompt" compose text area, captured live on 2026-11-02. Tried in
			order; each is a single compound specifier walk (no AXChildren
			scanning), so even trying all candidates costs ~0s - the project's
			stated preference is speed over reliability here, so this
			deliberately does NOT fall back to a tree search when every
			candidate fails. See ui-structure-notes.md for how these were
			captured, how often they've been seen to drift, and the recipe to
			add a new candidate when they all stop matching.
		*)
		property PROMPT_PATH_CANDIDATES : {{1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 7, 1, 1, 1, 1, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 7, 1, 1, 1, 1, 1}}
		
		(*
			@returns the message compose text area (accessibility description
			"Prompt"), or missing value when it can't be found (e.g. no
			window, the UI changed, or no candidate in PROMPT_PATH_CANDIDATES
			matches).
		*)
		on getPromptUI()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			_resolveFirstMatchingPath(htmlContent, PROMPT_PATH_CANDIDATES)
		end getPromptUI
		
		
		(* @returns the element reached by walking indexPath as "UI element N of ... of rootElement", or missing value. *)
		on _resolveIndexPath(rootElement, indexPath)
			tell application "System Events" to tell process "Claude"
				try
					set currentElement to rootElement
					repeat with nextIndex in indexPath
						set currentElement to UI element (contents of nextIndex) of currentElement
					end repeat
					return currentElement
				on error
					return missing value
				end try
			end tell
		end _resolveIndexPath
		
		
		(* @returns the element reached by the first path in candidatePaths that resolves, or missing value. *)
		on _resolveFirstMatchingPath(rootElement, candidatePaths)
			repeat with candidatePath in candidatePaths
				set found to my _resolveIndexPath(rootElement, contents of candidatePath)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _resolveFirstMatchingPath
		
		
		(*
			NOTE: Deliberately does NOT check the "Show/Hide Sidebar" menu
			item's title. AXMenuItem titles are cached and only get refreshed
			once the menu is actually popped open, so checking it without
			opening the menu first can report stale state (e.g. right after
			the user toggles the sidebar from the in-app button rather than
			the menu). Reading the live toggle button inside the sidebar
			itself avoids that staleness.
		*)
		on getSidebarUI()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					return group 1 of group 1 of group 1 of group 1 of group 1 of htmlContent
				end try
			end tell
			
			missing value
		end getSidebarUI
		
		
		on hasSidebar()
			set sidebarUI to getSidebarUI()
			if sidebarUI is missing value then return false
			
			tell application "System Events" to tell process "Claude"
				try
					return description of button 1 of sidebarUI is "Hide sidebar"
				end try
			end tell
			
			false
		end hasSidebar
		
		
		on showSidebar()
			if running of application "Claude" is false then return
			if hasSidebar() then return
			
			logger's debug("Showing sidebar via menu...")
			tell application "System Events" to tell process "Claude"
				try
					click menu item "Show Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showSidebar
		
		
		on hideSidebar()
			if running of application "Claude" is false then return
			if not hasSidebar() then return
			
			logger's debug("Hiding sidebar via menu...")
			tell application "System Events" to tell process "Claude"
				try
					click menu item "Hide Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideSidebar
		
		
		(*
			Clicks the "+" next to a sidebar project folder to start a new
			session in that folder. The button's accessibility description is
			"New session in <folderName>".

			Matching is case- and whitespace-insensitive, so "new plexuss"
			matches the folder labeled "newplexuss". If there is no exact
			match, a unique prefix match is used.

			@returns true if the plus was found and clicked, false otherwise.
		*)
		on newSessionInFolder(folderName)
			if running of application "Claude" is false then return false
			
			showSidebar()
			
			set plusButton to _findNewSessionButton(folderName)
			if plusButton is missing value then
				logger's errorf("New session button not found for folder: {}", folderName)
				return false
			end if
			
			tell application "Claude" to activate
			tell application "System Events" to tell process "Claude"
				set frontmost to true
			end tell
			
			leftClick of cliclick at plusButton
			true
		end newSessionInFolder
		
		
		(* @returns the sidebar "+" button for @folderName, or missing value. *)
		on _findNewSessionButton(folderName)
			set sidebarUI to getSidebarUI()
			if sidebarUI is missing value then return missing value
			
			set targetName to my _normalizeFolderName(folderName)
			if targetName is "" then return missing value
			
			script MatchState
				property exactMatch : missing value
				property prefixMatch : missing value
				property prefixMatchCount : 0
			end script
			
			my _scanNewSessionButtons(sidebarUI, targetName, MatchState)
			
			if MatchState's exactMatch is not missing value then return MatchState's exactMatch
			if MatchState's prefixMatchCount is 1 then return MatchState's prefixMatch
			
			missing value
		end _findNewSessionButton
		
		
		on _scanNewSessionButtons(uielement, targetName, MatchState)
			tell application "System Events" to tell process "Claude"
				try
					set elementDesc to description of uielement
				on error
					set elementDesc to missing value
				end try
				
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					set kids to {}
				end try
			end tell
			
			if elementDesc is not missing value and elementDesc starts with "New session in " then
				set folderPart to my _normalizeFolderName(textUtil's stringAfter(elementDesc, "New session in "))
				if folderPart is targetName then
					set exactMatch of MatchState to uielement
				else if folderPart starts with targetName then
					set prefixMatch of MatchState to uielement
					set prefixMatchCount of MatchState to (prefixMatchCount of MatchState) + 1
				end if
			end if
			
			repeat with nextKid in kids
				my _scanNewSessionButtons(contents of nextKid, targetName, MatchState)
			end repeat
		end _scanNewSessionButtons
		
		
		(* Trims, lowercases, and strips spaces so "new plexuss" matches "newplexuss". *)
		on _normalizeFolderName(folderName)
			textUtil's replace(textUtil's lowerCase(textUtil's trim(folderName as text)), " ", "")
		end _normalizeFolderName
		
		
		(*
			@returns the model name currently selected in the message compose
			toolbar (e.g. "Sonnet 5"), or missing value when it can't be
			determined.
		*)
		on getModel()
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return missing value
			
			try
				with timeout of 10 seconds
					tell application "System Events" to tell process "Claude"
						set triggerDesc to description of modelTrigger
					end tell
				end timeout
			on error
				return missing value
			end try
			
			textUtil's trim(textUtil's stringAfter(triggerDesc, "Model:"))
		end getModel
		
		
		(*
			Switches the active model to the one matching @modelName (e.g.
			"Sonnet 5", "Opus 5.5", "Haiku 4.5"). Exact match (case/whitespace
			insensitive) is preferred, otherwise the first model whose name
			starts with @modelName is picked - this tolerates names like
			"Fable 5.1" for the menu item labeled "Fable 5.1 Requires usage
			credits".

			@returns true if the model is now active (including when it was
				already active), false when it could not be found/switched.

			NOTE: The model picker's dropdown is a native AXMenu, but it only
			renders when triggered by a real synthetic mouse click (cliclick).
			The plain `click`/`AXPress` action and the `AXShowMenu`
			accessibility action do NOT open it - they are silently ignored.
			Once open, its AXMenuItems are only reliably discoverable via
			`entire contents of mainContent` - direct/attribute-based
			AXChildren queries on the button or its ancestors keep reporting
			stale (pre-click) data.
			
			Human Review: Very slow at 8s.
		*)
		on switchModel(modelName)
			if running of application "Claude" is false then return false
			
			set targetName to my _normalizeModelName(modelName)
			
			set currentModel to getModel()
			if currentModel is not missing value and my _normalizeModelName(currentModel) is targetName then
				logger's debugf("Already using model: {}", modelName)
				return true
			end if
			
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return false
			
			set mainContent to _getMainContent()
			if mainContent is missing value then return false
			
			tell application "Claude" to activate
			delay 0.2
			tell application "System Events" to tell process "Claude"
				set frontmost to true
				try
					key code 53 -- close any stray/leftover menu first
				end try
			end tell
			delay 0.2
			
			leftClick of cliclick at modelTrigger
			
			set targetItem to missing value
			repeat 20 times
				set targetItem to my _findMenuItem(mainContent, targetName)
				if targetItem is not missing value then exit repeat
				delay 0.1
			end repeat
			
			if targetItem is missing value then
				tell application "System Events" to tell process "Claude"
					try
						key code 53
					end try
				end tell
				logger's errorf("Model not found: {}", modelName)
				return false
			end if
			
			leftClick of cliclick at targetItem
			true
		end switchModel
		
		
		(*
			Full UI-element-index paths from getHtmlContent() straight to the
			model pop-up button (description starts with "Model:"), captured
			live on 2026-11-02 - same approach and caveats as
			PROMPT_PATH_CANDIDATES above.
		*)
		property MODEL_TRIGGER_PATH_CANDIDATES : {{1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 8, 1}, {1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 8, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 8, 1}}
		
		(* @returns the model pop up button (description "Model: <name>"), or missing value. *)
		on _getModelTrigger()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			_resolveFirstMatchingPath(htmlContent, MODEL_TRIGGER_PATH_CANDIDATES)
		end _getModelTrigger
		
		
		(* Trims and lowercases, for case/whitespace insensitive comparisons. *)
		on _normalizeModelName(modelName)
			textUtil's lowerCase(textUtil's trim(modelName as text))
		end _normalizeModelName
		
		
		(*
			Searches @root's entire descendant tree for an AXMenuItem whose
			(normalized) name equals @normalizedTargetName, falling back to
			the first one that starts with it. @root is expected to already
			have its model dropdown open.
		*)
		on _findMenuItem(root, normalizedTargetName)
			tell application "System Events" to tell process "Claude"
				set allElements to {}
				try
					set allElements to entire contents of root
				end try
			end tell
			
			set prefixMatch to missing value
			repeat with nextElement in allElements
				tell application "System Events" to tell process "Claude"
					set elementRole to "?"
					try
						set elementRole to role of nextElement
					end try
				end tell
				if elementRole is "AXMenuItem" then
					tell application "System Events" to tell process "Claude"
						set itemName to my _normalizeModelName(name of nextElement)
					end tell
					if itemName is normalizedTargetName then return contents of nextElement
					if prefixMatch is missing value and itemName starts with normalizedTargetName then set prefixMatch to contents of nextElement
				end if
			end repeat
			
			prefixMatch
		end _findMenuItem
		
		
		(*
			Group-index path from getHtmlContent() down to a stable anchor
			a few levels above the "main" landmark region, captured live
			against this app build on 2026-11-02 - see ui-structure-notes.md
			in this folder for the recipe to re-derive it.

			Deliberately stops short of "main" itself: the remaining 1-2
			levels were found to NOT hold still (see _getMainContent()), so
			only the verified-stable prefix is hardcoded here.
		*)
		property MAIN_CONTENT_PATH : {1, 1, 1}
		
		(*
			@returns the "main" landmark region (skips the sidebar), or
			missing value. Shared by the model handlers above and by
			getPromptUI().

			Walks the fixed MAIN_CONTENT_PATH to a stable anchor (skipping
			the sidebar entirely - the expensive part), then does a small
			bounded search from there for role description "main". That last
			leg can't be hardcoded: a sibling near "main" was observed to
			reflow every few seconds even with no user interaction (a live
			status/typing region, most likely), shifting its index - a fixed
			chain all the way down broke within minutes of being captured.
		*)
		on _getMainContent()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set currentElement to htmlContent
					repeat with nextIndex in MAIN_CONTENT_PATH
						set currentElement to group (contents of nextIndex) of currentElement
					end repeat
				on error
					return missing value
				end try
			end tell
			
			_findDescendantByRoleDescription(currentElement, "main")
		end _getMainContent
		
		
		(* @returns the first descendant (depth-first) whose role description matches, or missing value. Scope this to a small anchor, never to htmlContent directly - it recurses into every descendant. *)
		on _findDescendantByRoleDescription(uielement, targetRoleDescription)
			tell application "System Events" to tell process "Claude"
				try
					if (role description of uielement) is targetRoleDescription then return uielement
				end try
				
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					return missing value
				end try
			end tell
			
			repeat with nextKid in kids
				set found to my _findDescendantByRoleDescription(contents of nextKid, targetRoleDescription)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _findDescendantByRoleDescription
		
		
		(*
			Mode toggle ("Chat and Cowork" vs "Code") lives in the sidebar as
			an AXRadioGroup described "Mode", with two AXRadioButton children
			described "Chat and Cowork" and "Code" (verified live 2026-11-03).

			@returns the AXRadioButton whose description is @modeDescription,
				or missing value. Scoped to the sidebar (small subtree), so a
				recursive scan is cheap here - unlike the main content tree.
		*)
		on _getModeRadioButton(modeDescription)
			set sidebarUI to getSidebarUI()
			if sidebarUI is missing value then return missing value
			
			_findRadioButtonByDescription(sidebarUI, modeDescription)
		end _getModeRadioButton
		
		
		(* @returns the first descendant AXRadioButton whose description matches targetDescription, or missing value. *)
		on _findRadioButtonByDescription(uielement, targetDescription)
			tell application "System Events" to tell process "Claude"
				try
					if (role of uielement) is "AXRadioButton" and (description of uielement) is targetDescription then return uielement
				end try
				
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					return missing value
				end try
			end tell
			
			repeat with nextKid in kids
				set found to my _findRadioButtonByDescription(contents of nextKid, targetDescription)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _findRadioButtonByDescription
		
		
		(*
			@returns "Code" or "Chat" for the sidebar Mode toggle's current
			state, or missing value when the app isn't running.

			NOTE: Same proxy getProjectFolderName() already relies on - the
			Mode radio buttons don't expose a readable AXChecked/AXSelected/
			AXValue (confirmed live: both stay false/empty no matter which is
			active; also checked AXDOMClassList, which is byte-identical
			between the two buttons, and the radio group's AXSelectedRows,
			which is always empty), so this infers the mode from whether a
			project folder is attached instead of reading the toggle
			directly.

			KNOWN GAP: on a brand-new session where the Code radio has just
			been selected but no project folder has been picked yet, this
			still reads as "Chat" - the folder-attached proxy can't
			distinguish that from true Chat mode. Only reliable once a
			folder is attached (e.g. an existing Code session).
		*)
		on getMode()
			if running of application "Claude" is false then return missing value
			
			if getProjectFolderName() is missing value then return "Chat"
			"Code"
		end getMode
		
		
		on isCodeMode()
			getMode() is "Code"
		end isCodeMode
		
		
		on isChatMode()
			getMode() is "Chat"
		end isChatMode
		
		
		(*
			@returns missing value - always. When Mode is "Chat and Cowork",
			the "New chat" screen shows a further "Chat"/"Cowork" sub-toggle
			(also an AXRadioButton pair), but it exposes no checked state at
			all (confirmed live 2026-11-03: AXChecked/AXSelected/AXValue are
			all empty/false for both, and AXDOMClassList is byte-identical
			between them). Unlike getMode(), there is no secondary proxy
			either - clicking each and diffing every static text on screen
			showed no visible difference. Not currently possible to detect.
		*)
		on getChatCoworkSubMode()
			missing value
		end getChatCoworkSubMode
		
		
		(*
			Clicks the sidebar Mode radio button described @modeDescription
			("Code" or "Chat and Cowork").

			@returns true if the button was found and clicked, false
				otherwise. Does NOT check/short-circuit on the current mode
				first - getMode()'s folder-popup proxy can't distinguish
				"already in Code mode" from "Code mode, no folder attached",
				so callers that care should check getMode() themselves.
		*)
		on _switchMode(modeDescription)
			if running of application "Claude" is false then return false
			
			showSidebar()
			
			set modeButton to _getModeRadioButton(modeDescription)
			if modeButton is missing value then
				logger's errorf("Mode radio button not found: {}", modeDescription)
				return false
			end if
			
			tell application "Claude" to activate
			tell application "System Events" to tell process "Claude"
				set frontmost to true
				-- delay 0.2
			end tell
			
			doubleLeftClick of cliclick at modeButton
			true
		end _switchMode
		
		
		on switchToCodeMode()
			_switchMode("Code")
		end switchToCodeMode
		
		
		on switchToChatMode()
			_switchMode("Chat and Cowork")
		end switchToChatMode
		
		
		(* Alias of switchToChatMode() - there is only one "Chat and Cowork" radio button, no separate Cowork option. *)
		on switchToCowork()
			switchToChatMode()
		end switchToCowork
		
		
		(* Alias of switchToChatMode(). *)
		on switchToChat()
			switchToChatMode()
		end switchToChat
		
		
		(* Switches to Code mode if currently in Chat mode, or to Chat mode if currently in Code mode. *)
		on toggleMode()
			if isCodeMode() then
				switchToChatMode()
			else
				switchToCodeMode()
			end if
		end toggleMode
		
		
		(*
			Returns the working directory pop-up button's folder name from the
			message compose toolbar, or missing value when no folder is attached
			(shown as "No folder"), which is effectively the "Chat" state.

			NOTE: Claude's sidebar has a "Mode" radio group toggling between
			"Chat and Cowork" and "Code", but its radio buttons don't expose a
			checked/selected state via the Accessibility API (no AXChecked,
			AXSelected is always false, AXValue is always empty), so that
			toggle can't be queried directly. The folder pop-up itself is a
			reliable proxy: it only ever shows a real folder name when a
			project/repo is attached to the current code session, and reads
			"No folder" otherwise.
		*)
		(*
			Full UI-element-index paths from getHtmlContent() straight to the
			working-directory pop-up button, same approach and caveats as
			PROMPT_PATH_CANDIDATES above - re-derived 2026-11-03 after the
			original single fixed "pop up button 2 of group 1 of ..." chain
			drifted and started throwing "Invalid index".
		*)
		property FOLDER_PATH_CANDIDATES : {{1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 3, 1}, {1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 1, 1, 2, 3, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 3, 1}, {1, 1, 1, 2, 3, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 1, 1, 2, 3, 1}}
		
		on getProjectFolderName()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			set folderPopup to _resolveFirstMatchingPath(htmlContent, FOLDER_PATH_CANDIDATES)
			if folderPopup is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set folderName to name of folderPopup
					if folderName is "No folder" then return missing value
					return folderName
				end try
			end tell
			
			missing value
		end getProjectFolderName
		
		
		on getHtmlContent()
			if running of application "Claude" is false then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					return UI element 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
				end try
			end tell
			
			missing value
		end getHtmlContent
	end script
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("ClaudeInstance")
end new


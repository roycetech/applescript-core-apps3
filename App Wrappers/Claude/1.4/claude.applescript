(*
	@Purpose:
		Wrapper to help automate the Claude app window.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Claude/1.4/claude'

	@Created: Fri, Aug 28, 2026 at 01:45:02 PM
	@Last Modified: July 24, 2023 10:56 AM
	
	@Change Logs:
		Fri, Sep 25, 2026, at 03:40:00 PM - Added #getModel() and #switchModel() to detect/change the active model.
		Fri, Sep 25, 2026, at 03:20:06 PM - Initial working implementation created by Claude.
*)

use loggerFactory : script "core/logger-factory"

use decoratorLib : script "core/decorator"

use cliclickLib : script "core/cliclick"

use textUtil : script "core/string"

property logger : missing value

property cliclick : missing value

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
	
	set htmlContent to sut's getHtmlContent()
	(* 
	tell application "System Events" to tell process "Claude"
		return entire contents of htmlContent
	end tell
	*)
	logger's infof("HTML Content found: {}", htmlContent is not missing value)
	logger's infof("Current model: {}", sut's getModel()) -- Slow, takes about 5s.
	logger's infof("Has sidebar: {}", sut's hasSidebar())
	logger's infof("Integration: Claude Project Path: {}", sut's getCurrentProjectPath())
	
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
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set cliclick to cliclickLib's new()
	
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
			@returns the message compose text area (accessibility description
			"Prompt"), or missing value when it can't be found (e.g. no
			window, or the UI changed).

			NOTE: Deliberately walks the tree using the "AXChildren" attribute
			instead of the usual `text areas of`/`groups of` bulk queries.
			For Claude's WebKit-rendered content those bulk queries
			unreliably report 0 elements (a caching quirk), while indexed/
			attribute-based access (e.g. "group 1 of x", "AXChildren") always
			returns live data.

			Scoped to the "main" region (role description "main") to skip
			over the sidebar's chat history list, which can contain hundreds
			of nested items and would otherwise make the search very slow.
		*)
		on getPromptUI()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set kids1 to value of attribute "AXChildren" of htmlContent
					set g1 to contents of item 1 of kids1
					set kids2 to value of attribute "AXChildren" of g1
					set g2 to contents of item 1 of kids2
					set kids3 to value of attribute "AXChildren" of g2
					set g3 to contents of item 1 of kids3
					set kids4 to value of attribute "AXChildren" of g3
					set frameRoot to contents of item 1 of kids4
				on error
					return missing value
				end try
			end tell
			
			set mainContent to _findChildWithRole(frameRoot, "main")
			if mainContent is missing value then return missing value
			
			_findElementByDescription(mainContent, "Prompt")
		end getPromptUI
		
		
		(* @returns the first direct child whose role description matches, or missing value. *)
		on _findChildWithRole(uielement, targetRole)
			tell application "System Events" to tell process "Claude"
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					return missing value
				end try
			end tell
			
			repeat with nextKid in kids
				set kidElement to contents of nextKid
				tell application "System Events" to tell process "Claude"
					try
						set kidRole to role description of kidElement
					on error
						set kidRole to missing value
					end try
				end tell
				if kidRole is targetRole then return kidElement
			end repeat
			
			missing value
		end _findChildWithRole
		
		
		(* @returns the first descendant (depth-first) whose accessibility description matches, or missing value. *)
		on _findElementByDescription(uielement, targetDescription)
			tell application "System Events" to tell process "Claude"
				try
					if (description of uielement) is targetDescription then return uielement
				end try
				
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					return missing value
				end try
			end tell
			
			repeat with nextKid in kids
				set found to my _findElementByDescription(contents of nextKid, targetDescription)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _findElementByDescription
		
		
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
			
			tell application "System Events" to tell process "Claude"
				try
					click menu item "Show Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end showSidebar
		
		
		on hideSidebar()
			if running of application "Claude" is false then return
			if not hasSidebar() then return
			
			tell application "System Events" to tell process "Claude"
				try
					click menu item "Hide Sidebar" of menu 1 of menu bar item "View" of menu bar 1
				end try
			end tell
		end hideSidebar
		
		
		(*
			@returns the model name currently selected in the message compose
			toolbar (e.g. "Sonnet 5"), or missing value when it can't be
			determined.
		*)
		on getModel()
			set modelTrigger to _getModelTrigger()
			if modelTrigger is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set triggerDesc to description of modelTrigger
				on error
					return missing value
				end try
			end tell
			
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
		
		
		(* @returns the model pop up button (description "Model: <name>"), or missing value. *)
		on _getModelTrigger()
			set mainContent to _getMainContent()
			if mainContent is missing value then return missing value
			
			_findElementByDescriptionPrefix(mainContent, "Model:")
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
			@returns the "main" landmark region (skips the sidebar), or
			missing value. Shared by the model handlers above.
		*)
		on _getMainContent()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set kids1 to value of attribute "AXChildren" of htmlContent
					set g1 to contents of item 1 of kids1
					set kids2 to value of attribute "AXChildren" of g1
					set g2 to contents of item 1 of kids2
					set kids3 to value of attribute "AXChildren" of g2
					set g3 to contents of item 1 of kids3
					set kids4 to value of attribute "AXChildren" of g3
					set frameRoot to contents of item 1 of kids4
				on error
					return missing value
				end try
			end tell
			
			_findChildWithRole(frameRoot, "main")
		end _getMainContent
		
		
		(* @returns the first descendant (depth-first) whose accessibility description starts with @targetPrefix, or missing value. *)
		on _findElementByDescriptionPrefix(uielement, targetPrefix)
			tell application "System Events" to tell process "Claude"
				try
					if (description of uielement) starts with targetPrefix then return uielement
				end try
				
				try
					set kids to value of attribute "AXChildren" of uielement
				on error
					return missing value
				end try
			end tell
			
			repeat with nextKid in kids
				set found to my _findElementByDescriptionPrefix(contents of nextKid, targetPrefix)
				if found is not missing value then return found
			end repeat
			
			missing value
		end _findElementByDescriptionPrefix
		
		
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
		on getProjectFolderName()
			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return missing value
			
			tell application "System Events" to tell process "Claude"
				try
					set folderName to name of pop up button 2 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 2 of group 1 of group 1 of group 1 of group 1 of htmlContent
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


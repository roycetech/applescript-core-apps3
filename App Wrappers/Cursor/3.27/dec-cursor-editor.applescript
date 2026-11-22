(*
	@Purpose:
		Handlers for the code editor (the Monaco text area of the active editor group).

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Cursor/3.27/dec-cursor-editor'

	@Created: Sat, Nov 21, 2026, at 10:00:00 AM
	@Last Modified: Sat, Nov 21, 2026, at 10:00:00 AM

	@Change Logs:
		Sat, Nov 21, 2026, at 10:00:00 AM - AI Added focusEditor() and isEditorFocused(), resolving the editor's text area from a fixed index path. See "## Editor" in ui-structure-notes.md.
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
		Manual: Focus Editor
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

	logger's infof("Is editor focused: {}", sut's isEditorFocused())

	if caseIndex is 1 then

	else if caseIndex is 2 then
		sut's focusEditor()
		logger's infof("Is editor focused after: {}", sut's isEditorFocused())

	end if

	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)

	script CursorEditorDecorator
		property parent : mainScript

		(*
			Index paths ("UI element N", outermost first) from getHtmlContent() to the
			editor's text area, captured live against Cursor 3.27 on 2026-11-21. The
			text area only exists while a file is open in the editor. See "## Editor"
			in ui-structure-notes.md for how to re-derive it. Add a new candidate when
			the layout shifts.
		*)
		property EDITOR_PATH_CANDIDATES : {{1, 3, 1, 1, 2, 2, 1, 2, 2, 1, 2, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1}}


		(* Focuses the active editor's text area, so typing and shortcuts go to the code. *)
		on focusEditor()
			if running of application "Cursor" is false then return

			tell application "System Events" to tell process "Cursor"
				set frontmost to true
			end tell

			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return

			set editorTextArea to my _findEditorTextArea(htmlContent)
			if editorTextArea is missing value then return

			tell application "System Events" to tell process "Cursor"
				set focused of editorTextArea to true
			end tell
		end focusEditor


		on isEditorFocused()
			if running of application "Cursor" is false then return false

			set htmlContent to getHtmlContent()
			if htmlContent is missing value then return false

			set editorTextArea to my _findEditorTextArea(htmlContent)
			if editorTextArea is missing value then return false

			tell application "System Events" to tell process "Cursor"
				focused of editorTextArea
			end tell
		end isEditorFocused


		on _findEditorTextArea(uiContainer)
			tell application "System Events" to tell process "Cursor"
				repeat with nextCandidatePath in EDITOR_PATH_CANDIDATES
					try
						set nextElement to uiContainer
						repeat with nextIndex in contents of nextCandidatePath
							set nextElement to UI element (contents of nextIndex) of nextElement
						end repeat
						if class of nextElement is text area then return nextElement
					end try
				end repeat
			end tell
			missing value
		end _findEditorTextArea
	end script
end decorate

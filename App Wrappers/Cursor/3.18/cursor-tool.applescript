(*
	Find every text field/area, static text, and button under Cursor's
	front window HTML content.
*)
use scripting additions

tell application "System Events" to tell process "Cursor"
	set htmlContent to UI element 1 of group 1 of group 1 of group 1 of group 1 of group 1 of group 1 of front window
end tell

(* 
set foundFields to _findAllTextFields(htmlContent)
_logUiElements("text fields/areas", foundFields)
*)

set foundStaticTexts to _findAllStaticTexts(htmlContent)
_logUiElements("static texts", foundStaticTexts)
return foundStaticTexts

(* 
set foundButtons to _findAllButtons(htmlContent)
_logUiElements("buttons", foundButtons)
*)

-- return {foundFields, foundStaticTexts, foundButtons}


on _logUiElements(labelText, uiElements)
	log "Found " & (count of uiElements) & " " & labelText
	repeat with nextElement in uiElements
		tell application "System Events"
			try
				set elementClass to class of nextElement as text
			on error
				set elementClass to "?"
			end try
			try
				set elementDesc to description of nextElement
			on error
				set elementDesc to ""
			end try
			try
				set elementName to name of nextElement
			on error
				set elementName to ""
			end try
			try
				set elementValue to value of nextElement
			on error
				set elementValue to ""
			end try
			log elementClass & " | " & elementDesc & " | " & elementName & " | " & elementValue
		end tell
	end repeat
end _logUiElements


(*
	Collects all nested text fields and text areas. Recurses into groups,
	scroll areas, and splitter groups — the containers Electron apps use
	beyond a simple group tree.
*)
on _findAllTextFields(uicontainer)
	set collected to {}
	
	tell application "System Events" to tell process "Cursor"
		try
			repeat with nextTextField in text fields of uicontainer
				set end of collected to contents of nextTextField
			end repeat
		end try
		
		try
			repeat with nextTextArea in text areas of uicontainer
				set end of collected to contents of nextTextArea
			end repeat
		end try
	end tell
	
	_collectFromChildContainers(uicontainer, collected, "_findAllTextFields")
end _findAllTextFields


on _findAllStaticTexts(uicontainer)
	set collected to {}
	
	tell application "System Events" to tell process "Cursor"
		try
			repeat with nextStaticText in static texts of uicontainer
				set end of collected to contents of nextStaticText
			end repeat
		end try
	end tell
	
	_collectFromChildContainers(uicontainer, collected, "_findAllStaticTexts")
end _findAllStaticTexts


on _findAllButtons(uicontainer)
	set collected to {}
	
	tell application "System Events" to tell process "Cursor"
		try
			repeat with nextButton in buttons of uicontainer
				set end of collected to contents of nextButton
			end repeat
		end try
		
		try
			repeat with nextRadio in radio buttons of uicontainer
				set end of collected to contents of nextRadio
			end repeat
		end try
		
		try
			repeat with nextCheckbox in checkboxes of uicontainer
				set end of collected to contents of nextCheckbox
			end repeat
		end try
	end tell
	
	_collectFromChildContainers(uicontainer, collected, "_findAllButtons")
end _findAllButtons


on _collectFromChildContainers(uicontainer, collected, finderName)
	tell application "System Events" to tell process "Cursor"
		try
			repeat with nextGroup in groups of uicontainer
				set collected to collected & my _runFinder(finderName, contents of nextGroup)
			end repeat
		end try
		
		try
			repeat with nextScroll in scroll areas of uicontainer
				set collected to collected & my _runFinder(finderName, contents of nextScroll)
			end repeat
		end try
		
		try
			repeat with nextSplitter in splitter groups of uicontainer
				set collected to collected & my _runFinder(finderName, contents of nextSplitter)
			end repeat
		end try
	end tell
	
	collected
end _collectFromChildContainers


on _runFinder(finderName, uicontainer)
	if finderName is "_findAllTextFields" then
		return _findAllTextFields(uicontainer)
	else if finderName is "_findAllStaticTexts" then
		return _findAllStaticTexts(uicontainer)
	else if finderName is "_findAllButtons" then
		return _findAllButtons(uicontainer)
	end if
	
	{}
end _runFinder

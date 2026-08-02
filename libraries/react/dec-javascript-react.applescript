(*
	@Purpose:
		Decorator that adds React-aware form helpers onto a JavaScript-capable
		browser tab (or any instance exposing executeJavaScriptUnchecked).

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh libraries/react/dec-javascript-react

	@Created: Sat, Jun 27, 2026 at 11:46:08 AM
	@Last Modified: Sat, Aug 1, 2026 at 8:28:00 PM

	@Change Logs:
		Sat, Aug 1, 2026 - Port generic React form helpers from dec-app1-react.
*)
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		NOOP
		Manual: Select Drop Down
		Manual: Click at Radio with Label
		Manual: Set Input by Selector
		Manual: Set TextArea by Selector

		Dummy
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	set browserLib to script "core/safari"
	set browserInst to browserLib's new()
	set browserTab to browserInst's getFrontTab()
	set sut to decorate(browserTab)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		sut's reactSelectDropDown("degree", 3)
		
	else if caseIndex is 3 then
		sut's reactClickAtRadioWithLabel("2 Year")
		
	else if caseIndex is 4 then
		sut's reactSetInputBySelector("#firstname", "Firstname test")
		
	else if caseIndex is 5 then
		sut's reactSetTextAreaBySelector("#textarea", "Textarea test")
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*
	@javascriptInstance - tab or script exposing executeJavaScriptUnchecked.
*)
on decorate(javascriptInstance)
	loggerFactory's inject(me)
	
	script JavascriptReactDecorator
		property parent : javascriptInstance
		
		(*
			@elementId - the HTML element ID.
			@valueNormalized - quoted value for strings, plain for numbers.
		*)
		on reactSelectDropDown(elementId, valueNormalized)
			set escapedId to my escapeJsString(elementId)
			set javascriptText to "
				(function() {
					const el = document.getElementById('" & escapedId & "');
					if (!el) {
						console.error('Could not find select with id:', '" & escapedId & "');
						return;
					}
					const setter = Object.getOwnPropertyDescriptor(
						window.HTMLSelectElement.prototype,
						'value'
					).set;
					setter.call(el, " & valueNormalized & ");
					el.dispatchEvent(new Event('change', { bubbles: true }));
				})();
			"
			executeJavaScriptUnchecked(javascriptText)
			delay 0.5
		end reactSelectDropDown
		
		
		(*
			@radioLabel - partial text match against the closest li textContent.
		*)
		on reactClickAtRadioWithLabel(radioLabel)
			set escapedLabel to my escapeJsString(radioLabel)
			set javascriptText to "
				(function() {
					const el = Array.from(document.querySelectorAll('input[type=\"radio\"]'))
						.find(r => r.closest('li')?.textContent.includes('" & escapedLabel & "'));
					if (!el) {
						console.error('Could not find radio with label:', '" & escapedLabel & "');
						return;
					}
					el.click();
				})();
			"
			executeJavaScriptUnchecked(javascriptText)
			delay 0.5
		end reactClickAtRadioWithLabel
		
		
		(*
			@inputSelector - CSS selector for the text input.
			@textValue - plain text to set.
		*)
		on reactSetInputBySelector(inputSelector, textValue)
			set escapedSelector to my escapeJsString(inputSelector)
			set escapedValue to my escapeJsString(textValue)
			set javascriptText to "
				(function() {
					const inputElement = document.querySelector('" & escapedSelector & "');
					if (!inputElement) {
						console.error('Could not find element with selector:', '" & escapedSelector & "');
						return;
					}
					const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
						window.HTMLInputElement.prototype,
						'value'
					).set;
					nativeInputValueSetter.call(inputElement, '" & escapedValue & "');
					inputElement.dispatchEvent(new Event('input', { bubbles: true }));
				})();
			"
			executeJavaScriptUnchecked(javascriptText)
			delay 0.5
		end reactSetInputBySelector
		
		
		(*
			@textAreaSelector - CSS selector for the textarea.
			@textValue - plain text to set.
		*)
		on reactSetTextAreaBySelector(textAreaSelector, textValue)
			set escapedSelector to my escapeJsString(textAreaSelector)
			set escapedValue to my escapeJsString(textValue)
			set javascriptText to "
				(function() {
					const textAreaElement = document.querySelector('" & escapedSelector & "');
					if (!textAreaElement) {
						console.error('Could not find element with selector:', '" & escapedSelector & "');
						return;
					}
					const nativeTextAreaValueSetter = Object.getOwnPropertyDescriptor(
						window.HTMLTextAreaElement.prototype,
						'value'
					).set;
					nativeTextAreaValueSetter.call(textAreaElement, '" & escapedValue & "');
					textAreaElement.dispatchEvent(new Event('input', { bubbles: true }));
				})();
			"
			executeJavaScriptUnchecked(javascriptText)
			delay 0.5
		end reactSetTextAreaBySelector
		
		
		on escapeJsString(sourceText)
			set escaped to sourceText
			set escaped to textUtil's replace(escaped, "\\", "\\\\")
			set escaped to textUtil's replace(escaped, "'", "\\'")
			set escaped to textUtil's replace(escaped, return, "\\n")
			set escaped to textUtil's replace(escaped, linefeed, "\\n")
			escaped
		end escapeJsString
		
	end script
end decorate

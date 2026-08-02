(*
	@Purpose:
		TODO

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh libraries/react/dec-javascript-react

	@Created: Sat, Jun 27, 2026 at 11:46:08 AM
	@Last Modified: Sat, Jun 27, 2026 at 11:46:08 AM
	
	@Change Logs:
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
	set sutLib to script "core/javascript"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		
	else if caseIndex is 3 then
		
	else
		
	end if
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(javascriptInstance)
	loggerFactory's inject(me)
	
	script JavascriptReactDecorator
		property parent : javascriptInstance
		
		on reactSelectDropdownByValue()
			javascriptInstance's executeJavaScriptUnchecked("
				function setReactSelect(id, value) {
					const el = document.getElementById(id);
					const setter = Object.getOwnPropertyDescriptor(
						window.HTMLSelectElement.prototype,
						'value'
					).set;
					setter.call(el, value);
					el.dispatchEvent(new Event('change', { bubbles: true }));
				}
			")
		end reactSelectDropdownByValue
	end script
end decorate

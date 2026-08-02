(*
	Usage:
		See spotCheck.

	Copied and retrofitted from safari-javascript.

	Testing Template:
		use microsoftEdgeLib : script "core/microsoft-edge"
		property microsoftEdge : microsoftEdgeLib's new()

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Microsoft Edge/140.0/microsoft-edge-javascript'

	@Created:
		Tue, Sep 09, 2025 at 08:23:54 AM

	@Change Logs: 
		Tue, Apr 28, 2026, at 11:48:20 AM - Fix missing active tab reference in #runScriptDirect
 *)

use scripting additions

use std : script "core/std"

use loggerFactory : script "core/logger-factory"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's injectBasic(me)
	logger's start()
	
	(* Tests are based on current apple.com website, very likely to change in the future. *)
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		Manual: AWS Login, IAM Radio Option
		Manual: Link Text Visible
		Manual: Selector Exists
		Checked By ID
		Retrieve Value
	")
	
	set spotScript to script "core/spot-test"
	set spotClass to spotScript's new()
	set spot to spotClass's new(me, cases)
	set {caseIndex, caseDesc} to spot's start()
	if caseIndex is 0 then
		logger's finish()
		return
	end if
	
	
	set microsoftEdgeLib to script "core/microsoft-edge"
	set microsoftEdge to microsoftEdgeLib's new()
	set microsoftEdgeTab to microsoftEdge's getFrontTab()
	set microsoftEdgeTab to decorate(microsoftEdgeTab)
	
	tell microsoftEdgeTab
		set its findRunMax to 3
		set its findRetrySleep to 1
	end tell
	microsoftEdgeTab's focus()
	microsoftEdgeTab's waitForPageLoad()
	
	if caseIndex is 1 then
		-- logger's infof("Selector Exists: {}",
		log microsoftEdgeTab's selectorExists("#iam_user_radio_button")
		log microsoftEdgeTab's selectorExists("#account")
		-- )
		
	else if caseIndex is 2 then
		set jsResult to microsoftEdgeTab's linkTextVisible("Learn more")
		assertThat of std given condition:jsResult is true, messageOnFail:"Failed spot check"
		set jsFalseResult to safariTab's linkTextVisible("Learn nothing")
		assertThat of std given condition:jsFalseResult is false, messageOnFail:"Failed spot check"
		logger's info("Passed")
		
	else if caseIndex is 3 then
		assertThat of std given condition:microsoftEdgeTab's selectorExists(".alert-danger") is false, messageOnFail:"Failed spot check"
		
		assertThat of std given condition:microsoftEdgeTab's selectorExists(".unit-wrapper") is true, messageOnFail:"Failed spot check"
		logger's info("Passed.")
		
	else if caseIndex is 4 then
		log sutTab's getCheckedById("activate_account_choice")
		
	else if caseIndex is 5 then
		log sutTab's getValue(".version-dd") -- cffiddle.org
	end if
	
	(*
	powered's waitForSelector("#as-search-input")
	powered's setValueById("as-search-input", "hello")
	*)
	
	spot's finish()
	logger's finish()
end spotCheck


-- Start of actual handlers ================

on decorate(microsoftEdgeTab)
	loggerFactory's injectBasic(me)
	
	script MicrosoftEdgeJavaScriptDecorator
		property parent : microsoftEdgeTab
		
		(*
			Cross-browser JavaScript execution contract:
			executeJavaScript          - side effects, errors swallowed
			evaluateJavaScript         - returns result to AppleScript
			executeJavaScriptUnchecked - raw passthrough, no error handling
			runScript* names are legacy aliases.

			Created because _runScript is bugged but it is widely used and I
			don't want to break the other uses. TODO: Unit Tests.
		*)
		(*
			@Deprecation, use executeJavaScriptUnchecked().
		*)
		on runScript(scriptText)
			executeJavaScriptUnchecked(scriptText)
		end runScript

		(*
			@Deprecation, use evaluateJavaScript().
		*)
		on runScriptPlain(scriptText)
			evaluateJavaScript(scriptText)
		end runScriptPlain

		(*
			@Deprecation, use executeJavaScriptUnchecked(). Targets the front window.
		*)
		on runScriptDirect(scriptText)
			tell application "Microsoft Edge" to tell front window
				tell active tab
					execute javascript scriptText
				end tell
			end tell
		end runScriptDirect

		on executeJavaScript(javascriptSource)
			if javascriptSource does not end with ";" then set javascriptSource to javascriptSource & ";"
			tell application "Microsoft Edge" to tell window 1
				tell active tab
					execute javascript ("try {" & javascriptSource & "} catch(e) { e.message; }")
				end tell
			end tell
		end executeJavaScript

		(*
			@returns result of the javascript.
		*)
		on _runScript(scriptText)
			set montereyFix to "var jsresult = (" & scriptText & ");if (typeof(jsresult) === 'boolean') { jsresult ? 'true' : 'false'} else jsresult;"
			set runScriptResult to evaluateJavaScript(montereyFix)
			if runScriptResult is equal to "true" then return true
			if runScriptResult is equal to "false" then return false
			
			runScriptResult
		end _runScript

		on evaluateJavaScript(javascriptSource)
			if javascriptSource does not end with ";" then set javascriptSource to javascriptSource & ";"
			tell application "Microsoft Edge" to tell window 1
				tell active tab
					return execute javascript ("try {" & javascriptSource & "} catch(e) { e.message; }")
				end tell
			end tell
		end evaluateJavaScript

		on executeJavaScriptUnchecked(javascriptSource)
			tell application "Microsoft Edge"
				
			end tell
			tell application "Microsoft Edge" to tell window 1
				tell active tab
					execute javascript javascriptSource
				end tell
			end tell
		end executeJavaScriptUnchecked
	end script
end decorate

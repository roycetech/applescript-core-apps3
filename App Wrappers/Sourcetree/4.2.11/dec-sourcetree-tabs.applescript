(*
	@Purpose:
		Repository tab bar helpers for Sourcetree.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Sourcetree/4.2.11/dec-sourcetree-tabs'

	@Created: Fri, Nov 20, 2026 at 12:15:24 PM
	@Last Modified: Fri, Nov 20, 2026 at 12:45:00 PM
	
	@Change Logs:
		Fri, Nov 20, 2026, at 12:45:00 PM - AI Added #switchTabByRepositoryName() and #getTabTitles(); strip " (Git)" from titles; click tabs as repositoryName & " (Git)".
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
		INFO:
		Manual: Switch Tab by Repository Name
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
	
	activate application "Sourcetree"
	set sutLib to script "core/sourcetree"
	set sut to sutLib's new()
	set sut to decorate(sut)
	
	logger's infof("Tab titles: {}", textUtil's join(sut's getTabTitles(), ", "))
	logger's infof("Current repository name: {}", sut's getCurrentRepositoryName())
	
	if caseIndex is 1 then
		
	else if caseIndex is 2 then
		set sutRepositoryName to "applescript-core"
		-- set sutRepositoryName to "applescript-hub"
		logger's debugf("sutRepositoryName: {}", sutRepositoryName)
		
		logger's infof("Switched: {}", sut's switchTabByRepositoryName(sutRepositoryName))
		logger's infof("Current repository name: {}", sut's getCurrentRepositoryName())
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	
	script SourcetreeTabsDecorator
		property parent : mainScript
		
		(* @returns repository names from the tab bar, without the " (Git)" suffix. *)
		on getTabTitles()
			if running of application "Sourcetree" is false then return {}
			
			set rawTabTitles to {}
			tell application "System Events" to tell process "Sourcetree"
				try
					set rawTabTitles to title of radio buttons of tab group 1 of window 1
				end try
			end tell
			
			set repositoryNames to {}
			repeat with nextTabTitle in rawTabTitles
				set end of repositoryNames to textUtil's stringBefore(contents of nextTabTitle, " (Git)")
			end repeat
			repositoryNames
		end getTabTitles
		
		
		(*
			Clicks the repository tab whose title is repositoryName with a " (Git)" suffix.
			@returns true if the tab was found and clicked.
		*)
		on switchTabByRepositoryName(repositoryName)
			if running of application "Sourcetree" is false then return false 
			if repositoryName is missing value then return false
			
			set expectedTabTitle to repositoryName
			if expectedTabTitle does not end with " (Git)" then set expectedTabTitle to expectedTabTitle & " (Git)"
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click (first radio button of tab group 1 of window 1 whose title is expectedTabTitle)
					return true
				end try
			end tell
			
			false
		end switchTabByRepositoryName
	end script
end decorate

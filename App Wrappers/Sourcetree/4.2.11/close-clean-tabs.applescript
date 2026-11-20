(*
	@Purpose:
		Close Sourcetree repository tabs whose working tree has no pending changes.
		Tab names come from the UI, repository paths are resolved by name under
		repositoriesRootPath, and "git status --porcelain" decides clean vs dirty.

	@Project:
		applescript-core-apps3

	@Usage:
		1. Run with isDryRun true and read the report.
		2. If no tabs are listed, run the discovery handler (dumpTabCandidates) and
		   adjust tabRoles.
		3. Set isDryRun to false to actually close the clean tabs.

	@Notes:
		UNTESTED against Sourcetree 4.2.11. The tab bar's accessibility roles and
		the tab-title-equals-folder-name assumption are guesses.
		Dirty means any output from git status, untracked files included.
		Tabs whose path can't be resolved, or where git fails, are left open.
*)
use scripting additions

use loggerFactory : script "core/logger-factory"

property logger : missing value

property isDryRun : true
property shouldKeepLastTab : true
property repositoriesRootPath : (POSIX path of (path to home folder)) & "Projects"
property searchMaxDepth : 5
property tabRoles : {"AXRadioButton", "AXTabButton", "AXTab"}

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then main()

on main()
	loggerFactory's inject(me)
	logger's start()
	
	if running of application "Sourcetree" is false then
		logger's info("Sourcetree is not running")
		logger's finish()
		return
	end if
	
	set tabNames to _listTabNames()
	logger's infof("Tab count: {}", count of tabNames)
	
	set cleanTabNames to {}
	repeat with nextTabName in tabNames
		set repositoryPath to _findRepositoryPath(contents of nextTabName)
		if repositoryPath is "" then
			logger's infof("SKIP (path not found): {}", nextTabName)
		else if _hasPendingChanges(repositoryPath) then
			logger's infof("KEEP (pending changes): {}", nextTabName)
		else
			logger's infof("CLEAN: {} ({})", {nextTabName, repositoryPath})
			set end of cleanTabNames to contents of nextTabName
		end if
	end repeat
	
	if shouldKeepLastTab and (count of cleanTabNames) is equal to (count of tabNames) and (count of cleanTabNames) is greater than 0 then
		logger's infof("All tabs are clean, keeping: {}", last item of cleanTabNames)
		set cleanTabNames to items 1 thru -2 of cleanTabNames
	end if
	
	if isDryRun then
		logger's infof("Dry run: would close {} tab(s)", count of cleanTabNames)
	else
		repeat with nextCleanTabName in cleanTabNames
			_closeTabByName(contents of nextCleanTabName)
		end repeat
		logger's infof("Closed {} tab(s)", count of cleanTabNames)
	end if
	
	logger's finish()
end main


(* Prints every element's role/name in window 1 so tabRoles can be corrected. *)
on dumpTabCandidates()
	tell application "System Events" to tell process "Sourcetree"
		repeat with nextElement in (entire contents of window 1)
			try
				log (role of nextElement) & " | " & (name of nextElement) & " | " & (description of nextElement)
			end try
		end repeat
	end tell
end dumpTabCandidates


on _tabElements()
	set tabElementList to {}
	tell application "System Events" to tell process "Sourcetree"
		repeat with nextElement in (entire contents of window 1)
			try
				if (role of nextElement) is in my tabRoles then
					set elementName to name of nextElement
					if elementName is not missing value and elementName is not "" then set end of tabElementList to {elementName, contents of nextElement}
				end if
			end try
		end repeat
	end tell
	return tabElementList
end _tabElements


on _listTabNames()
	set tabNames to {}
	repeat with nextTabEntry in _tabElements()
		set end of tabNames to item 1 of nextTabEntry
	end repeat
	return tabNames
end _listTabNames


on _findRepositoryPath(repositoryName)
	set findCommand to "/usr/bin/find " & quoted form of repositoriesRootPath & " -maxdepth " & searchMaxDepth & " -type d -name " & quoted form of repositoryName & " -exec test -e {}/.git \\; -print -quit 2>/dev/null"
	try
		return do shell script findCommand
	on error
		return ""
	end try
end _findRepositoryPath


on _hasPendingChanges(repositoryPath)
	try
		set statusOutput to do shell script "/usr/bin/git -C " & quoted form of repositoryPath & " status --porcelain | /usr/bin/head -1"
		return statusOutput is not ""
	on error
		return true -- unknown: leave the tab open
	end try
end _hasPendingChanges


on _closeTabByName(wantedTabName)
	-- Re-resolve each time: closing a tab shifts the others.
	repeat with nextTabEntry in _tabElements()
		if (item 1 of nextTabEntry) is wantedTabName then
			tell application "System Events" to tell process "Sourcetree"
				click (item 2 of nextTabEntry)
				delay 0.3
				keystroke "w" using command down
			end tell
			delay 0.3
			return true
		end if
	end repeat
	return false
end _closeTabByName

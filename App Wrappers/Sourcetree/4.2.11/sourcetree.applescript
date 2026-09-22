(*
	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Sourcetree/4.2.11/sourcetree'

	@Change Logs:
		Fri, Sep 18, 2026, at 08:30:00 AM - Refactored commit handlers into dec-sourcetree-commit
		Fri, Sep 18, 2026, at 08:28:00 AM - spotCheck: single integration INFO case only
		Fri, Sep 18, 2026, at 08:27:00 AM - Moved file spot cases to dec-sourcetree-file
		Fri, Sep 18, 2026, at 08:22:00 AM - Refactored file handlers into dec-sourcetree-file
		Fri, Sep 18, 2026, at 08:14:00 AM - Added #isLastStagedFileSelected
		Fri, Mar 27, 2026, at 02:33:04 PM - Added #getCurrentRepositoryName
		Thu, Mar 26, 2026, at 11:07:03 AM - Added #toggleWhitespace.
		Thu, Feb 26, 2026, at 05:35:40 PM - Added #getSelectedFilePath()
			Re-tested all spot cases (1-18)

	@Created: Monday, November 25, 2024 at 3:32:55 PM
	@Last Modified: 2026-03-27 14:33:12
*)
use unic : script "core/unicodes"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use decoratorLib : script "core/decorator"

property logger : missing value

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		INFO:
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
	
	set sut to new()
	activate application "Sourcetree"
	
	logger's infof("Integration: Current repository name: {}", sut's getCurrentRepositoryName())
	logger's infof("Integration: Commit message input focused: {}", sut's isCommitMessageFocused())
	logger's infof("Integration: Push changes immediately: {}", sut's isPushChangesImmediately())
	logger's infof("Integration: Is whitespace visible: {}", sut's isWhitespaceVisible())
	logger's infof("Integration: Last staged file selected: {}", sut's isLastStagedFileSelected())
	logger's infof("Integration: Selected file path: {}", sut's getSelectedFilePath())
	
	if caseIndex is 1 then
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on new()
	loggerFactory's inject(me)
	set decSourcetreeFile to script "core/dec-sourcetree-file"
	set decSourcetreeCommit to script "core/dec-sourcetree-commit"
	
	script SourcetreeInstance
		
		on getCurrentRepositoryName()
			if running of application "Sourcetree" is false then return missing value
			
			tell application "System Events" to tell process "Sourcetree"
				return textUtil's stringBefore(name of front window, space)
			end tell
		end getCurrentRepositoryName
		
		(*
			@ menuItemTitle
				Flat list (single column)
				Flat list (multiple columns)
				Tree view
				No staging
				Fluid staging
				Split view staging
		*)
		on triggerSecondMenu(menuItemTitle)
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				set secondMenuButton to menu button 2 of my _toolbarGroup()
				click secondMenuButton
				click menu item menuItemTitle of menu 1 of secondMenuButton
			end tell
			
		end triggerSecondMenu
		
		
		on isWhitespaceVisible()
			"impossible"
		end isWhitespaceVisible
		
		on toggleWhitespace()
			tell application "System Events" to tell process "Sourcetree"
				set menuButton to menu button 3 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of window 1
				click menuButton
				set whiteSpaceShown to unic's MENU_CHECK is equal to value of attribute "AXMenuItemMarkChar" of menu item 3 of menu 1 of menuButton
			end tell
			
			if whiteSpaceShown then
				tell application "System Events" to tell process "Sourcetree"
					set whitespaceMenu to menu button 3 of my _toolbarGroup()
					click menu item "Ignore whitespace" of menu 1 of menuButton
				end tell
				
			else
				tell application "System Events" to tell process "Sourcetree"
					click menu item "Show whitespace" of menu 1 of menuButton
				end tell
				
			end if
		end toggleWhitespace
		
		
		on setIgnoreWhitespace()
			tell application "System Events" to tell process "Sourcetree"
				set whitespaceMenu to menu button 3 of my _toolbarGroup()
				click whitespaceMenu
				
				click menu item "Ignore whitespace" of menu 1 of whitespaceMenu
			end tell
		end setIgnoreWhitespace
		
		
		on setShowWhitespace()
			tell application "System Events" to tell process "Sourcetree"
				set whitespaceMenu to menu button 3 of my _toolbarGroup()
				click whitespaceMenu
				click menu item "Show whitespace" of menu 1 of whitespaceMenu
			end tell
		end setShowWhitespace
		
		on scrollPageDown()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				click (first button of scroll bar 1 of my _diffScrollArea() whose description is "increment page button")
			end tell
		end scrollPageDown
		
		on scrollPageUp()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				click (first button of scroll bar 1 of my _diffScrollArea() whose description is "decrement page button")
			end tell
		end scrollPageUp
		
		on triggerMenuShowOnly()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 1 of my _toolbarGroup()
				end try
			end tell
		end triggerMenuShowOnly
		
		
		(* UI refs *)
		on _toolbarGroup()
			tell application "System Events" to tell process "Sourcetree"
				-- return group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
				return group 1 of splitter group 1 of splitter group 1 of splitter group 1 of window 1
			end tell
		end _toolbarGroup
		
		on _diffScrollArea()
			tell application "System Events" to tell process "Sourcetree"
				return scroll area 2 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _diffScrollArea
		
		on stageFirstHunk()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click button "Stage hunk" of group 2 of group 1 of my _diffScrollArea()
				end try
			end tell
		end stageFirstHunk
	end script
	
	decSourcetreeFile's decorate(result)
	decSourcetreeCommit's decorate(result)
	
	set decorator to decoratorLib's new(result)
	decorator's decorateByName("SourcetreeInstance")
end new

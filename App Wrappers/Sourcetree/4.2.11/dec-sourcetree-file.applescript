(*
	@Purpose:
		File list selection, staging, and path helpers for Sourcetree.

	@Project:
		applescript-core-apps3

	@Build:
		./scripts/build-lib.sh 'App Wrappers/Sourcetree/4.2.11/dec-sourcetree-file'

	@Created: Fri, Sep 18, 2026 at 08:22:00 AM
	@Last Modified: Fri, Sep 18, 2026 at 08:22:00 AM
	
	@Change Logs:
		Fri, Sep 18, 2026, at 08:27:00 AM - Moved file spot cases from sourcetree.applescript
*)
use loggerFactory : script "core/logger-factory"

use clipLib : script "core/clipboard"
use cliclickLib : script "core/cliclick"

property logger : missing value

property clip : missing value
property cliclick : missing value

property LABEL_STAGED_FILES : "Staged files"

property LABEL_UNSTAGED_FILES : "Unstaged files"

property TopLevel : me

if {"Script Editor", "Script Debugger", "osascript"} contains the name of current application then spotCheck()

on spotCheck()
	loggerFactory's inject(me)
	logger's start()
	
	set listUtil to script "core/list"
	set cases to listUtil's splitAndTrimParagraphs("
		INFO:
		Manual: Trigger Menu Files View
		Manual: Trigger Files View Sub menu (Single Column)
		Manual: Select first unstage file
		Manual: Select first file
		
		Manual: Select next file
		Manual: Select previous file
		Manual: Stage Selected File
		Manual: Select File - second
		Manual: Reveal selected file
		
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
	
	logger's infof("Last staged file selected: {}", sut's isLastStagedFileSelected())
	logger's debugf("Has Last staged file row: {}", sut's _getLastStagedFileRow() is not missing value)
	
	if caseIndex is 1 then
		logger's infof("Selected file path: {}", sut's getSelectedFilePath())
		
	else if caseIndex is 2 then
		sut's triggerMenuFilesView()
		
	else if caseIndex is 3 then
		sut's triggerMenuFilesView()
		delay 0.2
		
		set sutSubmenuKeyword to "single column"
		-- set sutSubmenuKeyword to "multiple columns"
		-- set sutSubmenuKeyword to "Tree view"
		logger's debugf("sutSubmenuKeyword: {}", sutSubmenuKeyword)
		
		sut's selectFilesViewSubMenu(sutSubmenuKeyword)
		
	else if caseIndex is 4 then
		sut's selectFirstUnstagedFile()
		
	else if caseIndex is 5 then
		sut's selectFirstFile()
		
	else if caseIndex is 6 then
		sut's selectNextFile()
		
	else if caseIndex is 7 then
		sut's selectPreviousFile()
		
	else if caseIndex is 8 then
		sut's stageSelectedFile()
		
	else if caseIndex is 9 then
		sut's selectFile(2)
		
	else if caseIndex is 10 then
		sut's revealSelectedFile()
		
	end if
	
	activate
	
	spot's finish()
	logger's finish()
end spotCheck


(*  *)
on decorate(mainScript)
	loggerFactory's inject(me)
	set clip to clipLib's new()
	set cliclick to cliclickLib's new()
	
	script SourcetreeFileDecorator
		property parent : mainScript
		
		(*
			WARNING: Triggers menu pop up.
		*)
		on getSelectedFilePath()
			tell application "System Events" to tell process "Sourcetree"
				set targetRow to missing value
				try
					set targetRow to first row of my _filesTable() whose selected is true
				end try
				if targetRow is missing value then
					logger's info("Target row could not be found")
					return missing value
					
				end if
			end tell
			
			(* Path inlined: this script runs in clip's context and cannot call _filesTable(). *)
			script CopyPathScript
				tell application "System Events" to tell process "Sourcetree"
					set menuUi to table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
					perform action 1 of menuUi
					delay 0.1
					click menu item "Copy Path To Clipboard" of menu 1 of menuUi
				end tell
			end script
			
			set filePath to clip's extract(CopyPathScript)
		end getSelectedFilePath
		
		
		(* Requires flat view. See #selectFilesViewSubMenu *)
		on isLastStagedFileSelected()
			if running of application "Sourcetree" is false then return false
			
			tell application "System Events" to tell process "Sourcetree"
				set lastStagedRow to my _getLastStagedFileRow()
				if lastStagedRow is missing value then return false
				
				try
					return selected of lastStagedRow is true
				end try
			end tell
			
			false
		end isLastStagedFileSelected
		
		
		on triggerMenuFilesView()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click menu button 2 of parent's _toolbarGroup()
				end try
			end tell
		end triggerMenuFilesView
		
		
		on selectFilesViewSubMenu(titleKeyword)
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					click (first menu item of menu 1 of menu button 2 of parent's _toolbarGroup() whose title contains titleKeyword)
				on error the errorMessage number the errorNumber
					log errorMessage
				end try
			end tell
		end selectFilesViewSubMenu
		
		
		on revealSelectedFile()
			set fileRows to _getFileRowsUI()
			if fileRows is missing value then return
			
			set showInFinderButton to missing value
			tell application "System Events" to tell process "Sourcetree"
				try
					first item of fileRows whose selected is true
					set ellipsisButton to button 1 of last UI element of result
					click ellipsisButton
					delay 0.5
					-- click button "Show in Finder" of pop over 1 of ellipsisButton
					set showInFinderButton to button "Show in Finder" of pop over 1 of ellipsisButton
				end try
			end tell
			if showInFinderButton is not missing value then
				leftClick of cliclick at showInFinderButton
			end if
		end revealSelectedFile
		
		
		on _filesTable()
			tell application "System Events" to tell process "Sourcetree"
				return table 1 of scroll area 1 of splitter group 1 of group 1 of splitter group 1 of splitter group 1 of splitter group 1 of front window
			end tell
		end _filesTable
		
		on _getFileRowsUI()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					return rows of my _filesTable()
				end try
			end tell
			
			missing value
		end _getFileRowsUI
		
		
		on _getLastStagedFileRow()
			if running of application "Sourcetree" is false then return missing value
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				on error
					return missing value
				end try
				
				set stagedSectionFound to false
				set lastStagedRow to missing value
				repeat with nextRow in targetRows
					set nextFilename to missing value
					try
						set nextFilename to value of static text 1 of UI element 1 of nextRow as text
					end try
					-- logger's debugf("nextFilename: {}", nextFilename)
					
					if not stagedSectionFound then
						if nextFilename is equal to TopLevel's LABEL_STAGED_FILES then
							set stagedSectionFound to true
						end if
						
					else
						if nextFilename is equal to TopLevel's LABEL_UNSTAGED_FILES then
							exit repeat
						end if
						set lastStagedRow to nextRow
					end if
				end repeat
				return lastStagedRow
				
			end tell
		end _getLastStagedFileRow
		
		
		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectFirstUnstagedFile()
			if running of application "Sourcetree" is false then return
			
			set unstagedLabelFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try
				
				repeat with nextRow in targetRows
					try
						if not unstagedLabelFound then
							if value of static text 1 of UI element 1 of nextRow is equal to my LABEL_UNSTAGED_FILES then
								set unstagedLabelFound to true
							end if
							
						else
							set selected of nextRow to true
							exit repeat
						end if
					end try
				end repeat
			end tell
		end selectFirstUnstagedFile
		
		
		on selectFile(fileIndex)
			if running of application "Sourcetree" is false then return
			if fileIndex is less than 1 then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try
				
				set selected of item (fileIndex + 1) of targetRows to true
			end tell
		end selectFile
		
		
		on selectFirstFile()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try
				
				set selected of second item of targetRows to true
			end tell
		end selectFirstFile
		
		
		(* Requires flat view. See #selectFilesViewSubMenu *)
		on selectLastFile()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try
				
				set selected of last item of targetRows to true
			end tell
		end selectLastFile
		
		
		on selectNextFile()
			if running of application "Sourcetree" is false then return
			
			set selectedFound to false
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
				end try
				
				if selected of last item of targetRows is true then
					return
				end if
				
				log 1
				repeat with nextRow in targetRows
					try
						if not selectedFound then
							if selected of nextRow then
								set selectedFound to true
								log selectedFound
							end if
							
						else
							log "Selecting first row after the selected row"
							set selected of nextRow to true
							exit repeat
						end if
					end try
				end repeat
			end tell
		end selectNextFile
		
		on selectPreviousFile()
			if running of application "Sourcetree" is false then return
			
			set selectedFound to false
			tell application "System Events" to tell process "Sourcetree"
				
				try
					set targetRows to rows of my _filesTable()
					set selectedRow to first item of targetRows whose selected is true
				on error the errorMessage number the errorNumber
					log errorMessage
					
					return
				end try
				log number of items in targetRows
				
				log selectedRow
				if selectedRow is not missing value then
					set selectedIndex to the value of attribute "AXIndex" of selectedRow
					log "seleced index: " & selectedIndex
					
				end if
				
				try
					set previousIsNotALabel to not (exists static text 1 of UI element 1 of item selectedIndex of targetRows)
					if previousIsNotALabel then
						log "selecting previous..."
						set selected of item selectedIndex of targetRows to true
					end if
				end try
			end tell
		end selectPreviousFile
		
		on stageSelectedFile()
			if running of application "Sourcetree" is false then return
			
			tell application "System Events" to tell process "Sourcetree"
				try
					set targetRows to rows of my _filesTable()
					set selectedRow to first item of targetRows whose selected is true
					click checkbox 1 of UI element 1 of selectedRow
				on error the errorMessage number the errorNumber
				end try
			end tell
		end stageSelectedFile
		
	end script
end decorate

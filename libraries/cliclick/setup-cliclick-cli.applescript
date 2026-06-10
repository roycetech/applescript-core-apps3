#!/usr/bin/osascript

(* Browse the CLI into config so it can be referenced by user scripts. *)

property PLIST_KEY : "cliclick CLI"
property PLIST_PATH : "~/applescript-core/config-system.plist"

set existingCli to missing value
try
	set existingCli to do shell script "plutil -extract '" & PLIST_KEY & "' raw " & PLIST_PATH
end try

if existingCli is not missing value and existingCli is not "" then return

try
	set chosenCli to choose file with prompt "Please select the cliclick CLI:" default location POSIX file "/usr/local/bin/cliclick"
on error the errorMessage
	if errorMessage is "User canceled." then return
	set chosenCli to choose file with prompt "Please select the cliclick CLI:" default location POSIX file "/opt/homebrew/bin/cliclick"
end try

do shell script "plutil -replace '" & PLIST_KEY & "' -string \"" & (POSIX path of chosenCli) & "\" " & PLIST_PATH

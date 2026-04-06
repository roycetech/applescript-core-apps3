(*
	Wrapper for Script Debugger app v8.0.5.
	
	Implementation was cloned from script-editor.applescript.
	
	@Assumptions:
		Script Debugger app will only have 1 window at any given time.
			New Script - at the start.
			Normal case - a script is open.
		
	@Facts:
		Cannot get the id of the app window.

	@Build:
		make build-lib SOURCE='App Wrappers/Script Debugger/v8.0.x/script-debugger'
		
	@Create ON: June 24, 2023 2:21 PM
	
	@Known Issues:
		errOSAInternalTableOverflow as of June 28, 2023 1:25 PM. 
		
*)

use scripting additions

use listUtil : script "core/list"
use textUtil : script "core/string"

use loggerFactory : script "core/logger-factory"

use retryLib : script "core/retry"
use configLib : script "core/config"


property logger : missing value

property retry : missing value
property configSystem : missing value


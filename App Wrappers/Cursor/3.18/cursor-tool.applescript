(*
	Find every text field/area, static text, and button under an app's
	front window. Change appName to target Cursor, Claude, zoom.us, etc.
*)
use scripting additions

use uiutilLib : script "core/ui-util"

set appName to "Claude"
set appName to "Cursor"
set uiUtil to uiutilLib's new()

set rootUI to uiUtil's getElectronContentRoot(appName, missing value)

set foundFields to uiUtil's findAllTextFields(rootUI, appName)
uiUtil's logUiElements("text fields/areas", foundFields)
return foundFields

(*
set foundStaticTexts to uiUtil's findAllStaticTexts(rootUI, appName)
uiUtil's logUiElements("static texts", foundStaticTexts)
return foundStaticTexts
*)

(*
set foundButtons to uiUtil's findAllButtons(rootUI, appName)
uiUtil's logUiElements("buttons", foundButtons)
return foundButtons
*)

:: EXAMPLE:
::powershell -noexit -file "AssembleScript.ps1" "alpha" "1.2.3" "./NuspecTemplates" "../"
:: PARAMETERS:
:: "alpha" - version type (Enum: major, minor, patch, alpha)
:: "1.2.3-rc" - set version number manually to "1.2.3-rc". Use valid Semantic Versioning number
:: "./NuspecTemplates" - path to folder containing nuspec templates
:: "../" - output package folder
:: "1.0.0" - suply current version number when it can not be recieved automaticly (through GIT command). Should be used only for SVN projects

powershell -noexit -file "AssembleScript.ps1" "alpha" "" "NuspecTemplates/" "" "1.0.0"

PAUSE
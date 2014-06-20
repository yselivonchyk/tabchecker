::powershell -noexit -file "AssembleScript.ps1" "alpha" "1.2.3" "./NuspecTemplates" "../"
:: "alpha" - version type
:: "1.2.3" - set version number manually to "1.2.3"
:: "./NuspecTemplates" - path to folder containing nuspec templates
:: "../" - output package folder

powershell -noexit -file "AssembleScript.ps1" "minor"
PAUSE
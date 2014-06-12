Param(
  [string]$versionType,
  [string]$manualVersion
)

$nugetExe = "./NuGet.exe"
$tempNuspecFile = "temp.nuspec"

Function GetNextVersionNumber($currentVersion, $versionType, $branch){
	Write-Host $currentVersion
	Write-Host $versionType
	Write-Host $branch		
	return "1.0.0"
}


If([System.String]::IsNullOrEmpty($manualVersion)){
	$gitCommit = &"git" "rev-list" "HEAD" "--count"
	$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"
	$gitTags = &"git" "tag"
	Write-Host $gitCommit
	Write-Host $gitBranch
	Write-Host $gitTags
	
	
	
	$version = GetNextVersionNumber "1.0.0" $versionType $gitBranch	
}
Else{
	$version = $manualVersion	
}

(Get-Content "Template.nuspec") | 
Foreach-Object {$_ -replace "{version}", $version} | 
Set-Content $tempNuspecFile

&$nugetExe "pack" $tempNuspecFile

EXIT

#reserved for future use
$gitCommit = &"git" "rev-list" "HEAD" "--count"
$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"
&$nugetExe "pack" $nuspecPath #"-OutputDirectory" $currentPackageDir
#&$nugetExe "push" MIP.AutoMoq.1.6.1.1.nupkg br3dZd! -s http://nuget.leoburnett.de
Param(
  [string]$versionType,
  [string]$manualVersion
)

$nugetExe = "./NuGet.exe"
$templateNuspecFile = "NuspecTemplates/Sample.nuspec"
$templateNuspecFiles = "NuspecTemplates/"
$tempNuspecFile = "Sample.nuspec"
$defaultVersion = "1.0.0"

Function GetLatestVersionNumber(){
	$gitTags = &"git" "tag"
	If(-not $gitTags){
		Write-Host "No existing version defined. Returning default." -foregroundcolor red
		Write-Host $defaultVersion
		Write-Host "Press any key to continue."
		$donotwriteittovar = [Console]::ReadKey()
		return $defaultVersion
	}
	
	Write-Host "Tags:" $gitTags
	$latest = $gitTags[0]
	Foreach($tag in $gitTags.GetEnumerator()){		
	    if($latest.CompareTo($tag) -lt 0){
            $latest = $tag;
		}
    }
	return $latest
}

Function CreateTagForCommit($tagName){
	&"git" "tag" $tagName
	&"git" "push" "origin" $tagName
}

Function GetNextVersionNumber($currentVersion, $versionType, $branch){
	If($branch -ne "master" -and $versionType -ne "alpha"){
		Write-Host "It is not allowed to create release version/package from development branches. Adjust this script to do so." -foregroundcolor red
		EXIT
	}
	#Write-Host "currentVersion: " + $currentVersion
	
	#restore previous version parts
	[int[]] $versionParts =  
	[int32]::Parse($currentVersion.Split(".")[0]), # major
	[int32]::Parse($currentVersion.Split(".")[1]), # minor
	[int32]::Parse($currentVersion.Split(".")[2]), # patch
	(&"git" "rev-list" "HEAD" "--count") # build. Is relevant only for master branch	

	
	switch -wildcard ($versionType) 
    { 
        "major" {
			Write-Host "creating major version"
			$versionParts[0]++
			$versionParts[1] = 0
			$versionParts[2] = 0		
		} 
        "minor"  {
			Write-Host "creating minor version"
			$versionParts[1]++
			$versionParts[2] = 0		
		} 
        "patch"  {
			Write-Host "creating patch version"
			$versionParts[2]++		
		} 
        "build"  {
			Write-Host "creating build version"
		} 
        "alpha"  {
			Write-Host "creating alpha version"
			$versionParts[2]++
			$versionParts[3] = 0 
		} 
        default {
			Write-Host  "Unknown build type"
			EXIT
		}
	}		
		
	$versionString = "" + $versionParts[0] + "." + $versionParts[1] + "." + $versionParts[2] + "." + $versionParts[3]
	
	if($versionType -eq "alpha"){
		$versionString += "-alpha" + ('{0:yyyyMMddHHmmss}' -f (Get-Date).ToUniversalTime())
	}
	return $versionString
}

#------------------
#Main
#------------------

#build the project first
&"./Build.cmd"
&"./CleanUpFiles.cmd"

#check if git repo exits
$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"
If(-not $gitBranch){
	Write-Host "Git branch info could not be found. Either your code is not associated with git repository or git console tools are not installed." -foregroundcolor red
	EXIT
}
Write-Host "Current branch is" $gitBranch	
#Get version number
If([System.String]::IsNullOrEmpty($manualVersion)){		
	
	$latestVersion = GetLatestVersionNumber	
	Write-Host "Latest version is" $latestVersion	
	$version = GetNextVersionNumber $latestVersion $versionType $gitBranch	
}
Else{
	$version = $manualVersion	
}

#Pack package

Get-ChildItem $templateNuspecFiles -Filter *.nuspec | `
Foreach-Object{
	$nuspecName = $_.Name	
	(Get-Content $_.FullName) | 
	Foreach-Object {$_ -replace "{version}", $version} | 
	Set-Content $nuspecName
	&$nugetExe "pack" $nuspecName	
}

## single nuspec file
#(Get-Content $templateNuspecFile) | 
#Foreach-Object {$_ -replace "{version}", $version} | 
#Set-Content $tempNuspecFile
#&$nugetExe "pack" $tempNuspecFile

#Mark commit with a tag
if($versionType -ne "alpha"){
	CreateTagForCommit($version)
}

EXIT
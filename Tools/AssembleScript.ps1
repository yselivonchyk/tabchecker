Param(
  [string]$versionType,
  [string]$manualVersion,
  [string]$nuspecTemplatesFolder,
  [string]$packageOutputFolder,
  [string]$defaultVersion = "1.0.0"
)

if([System.String]::IsNullOrEmpty($packageOutputFolder)){
	$packageOutputFolder =  [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
}
if([System.String]::IsNullOrEmpty($nuspecTemplatesFolder)){
	$nuspecTemplatesFolder =  "NuspecTemplates/"
}

Write-Host 'Version Type:' $versionType
Write-Host 'Set version manualy:' $manualVersion
Write-Host 'Nuspec source folder:'$nuspecTemplatesFolder
Write-Host 'Package output folder:' $packageOutputFolder

$nugetExe = $MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) + "./NuGet.exe"
$templateNuspecFile = "NuspecTemplates/Sample.nuspec"
#$tempNuspecFile = "Sample.nuspec"

Function GetLatestVersionNumber(){
	$gitTags = &"git" "tag"
	If(-not $gitTags){
		Write-Host "No existing version defined. Returning default." -foregroundcolor yellow
		Write-Host "default version:" $defaultVersion
		#Write-Host "Press any key to continue."
		#$donotwriteittovar = [Console]::ReadKey()
		return $defaultVersion
	}
	
	Write-Host "Tags:" $gitTags
	$latest = $defaultVersion
	Foreach($tag in $gitTags.GetEnumerator()){
		Write-Host $tag ($tag -match '^\d+.\d+.\d+')
	    if($latest.CompareTo($tag) -lt 0 -and $tag -match '^\d+.\d+.\d+'){
            $latest = $tag;
		}
    }
	return $latest
}

Function CreateTagForCommit($tagName){
	&"git" "tag" $tagName
	&"git" "push" "origin" $tagName
}

Function IncrementBuildNumber($versionParts, $versionType){
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
			#$versionParts[3] = 0 
		} 
		"current"  {
			Write-Host "Caution. You are creating a package with package number that already exists. Do not commit package with" -foregroundcolor red
		}
        default {
			Write-Host  "Unknown build type" -foregroundcolor red
			EXIT
		}
	}
}

Function GetNextVersionNumberGIT($currentVersion, $versionType, $branch){
	If($branch -ne "master" -and $versionType -ne "alpha"){
		Write-Host "It is not allowed to create release version/package from development branches. Adjust this script to do so." -foregroundcolor red
		EXIT
	}
	#Write-Host "currentVersion: " + $currentVersion
	
	#restore previous version parts
	[int[]] $versionParts =  
	[int32]::Parse($currentVersion.Split(".")[0]), # major
	[int32]::Parse($currentVersion.Split(".")[1]), # minor
	[int32]::Parse($currentVersion.Split(".")[2]) # patch
	
	IncrementBuildNumber $versionParts $versionType		
	
	$versionString = "" + '{0}.{1}.{2}' -f $versionParts[0], $versionParts[1], $versionParts[2]
	
	if($versionType -eq "alpha"){
		$versionString += "-alpha" + ('{0:yyyyMMddHHmmss}' -f (Get-Date).ToUniversalTime())
	}
	return $versionString
}

Function GetNextVersionNumberSVN($currentVersion, $versionType, $branch){
	$svnInfo = &"svn" "info"
	Write-Host "SVN INFO: " $svnInfo

	Foreach($svnLine in $svnInfo.GetEnumerator()){
		If($svnLine.Contains("Revision")){				
			 $buildNumber = $svnLine.Split(" ")[1]
			 Write-Host "Current build number:" $buildNumber -foregroundcolor yellow
		}
    }	

	#restore previous version parts
	[int[]] $versionParts =  
	[int32]::Parse($currentVersion.Split(".")[0]), # major
	[int32]::Parse($currentVersion.Split(".")[1]), # minor
	[int32]::Parse($currentVersion.Split(".")[2]) # patch
	
	IncrementBuildNumber $versionParts $versionType
		
	$versionString = "" + '{0}.{1}.{2}.{3}' -f $versionParts[0], $versionParts[1], $versionParts[2], $buildNumber
	
	if($versionType -eq "alpha"){
		$versionString += "-alpha" + ('{0:yyyyMMddHHmmss}' -f (Get-Date).ToUniversalTime())
	}
	return $versionString
}

#------------------
#Main
#------------------

# Clean up existing nuspec files in the script folder
$scriptFolder = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Remove-Item ($scriptFolder + '\*') -include *.nuspec
# Move existing packages in output folder
$packageHistory = Join-Path -path $packageOutputFolder -childpath 'PackageHistory'
Write-host '111' $packageHistory
if(!(Test-Path -Path $packageHistory)){
    New-Item -ItemType directory -Path $packageHistory
}
Move-Item ($packageOutputFolder + '\*.nupkg') $packageHistory -force

#check if git repo exists
$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"
If(-not $gitBranch){
	Write-Host "Git branch info could not be found. Either your code is not associated with git repository or git console tools are not installed." -foregroundcolor red
	#$manualVersion = GetNextVersionNumber '1.0.0' 'alpha' 'no_branch'
	#EXIT
}
Write-Host "Current branch is" $gitBranch	
#Get version number
If([System.String]::IsNullOrEmpty($manualVersion)){
	$latestVersion = GetLatestVersionNumber	
	Write-Host "Latest version is" $latestVersion
	If($gitBranch){
		$version = GetNextVersionNumberGIT $latestVersion $versionType $gitBranch
	}	
	Else{
		$version = GetNextVersionNumberSVN $latestVersion $versionType
	}
	Write-Host "Version string:" $version  -foregroundcolor yellow	
}
Else{
	$version = $manualVersion	
}

#Pack package. Transform each nuspec file beforehand
Get-ChildItem $nuspecTemplatesFolder -Filter *.nuspec | `
Foreach-Object{
	$nuspecName = $_.Name	
	(Get-Content $_.FullName) | 
	Foreach-Object {$_ -replace "{version}", $version} | 
	Set-Content (Join-Path -path $scriptFolder -childpath $nuspecName)
	If([System.String]::IsNullOrEmpty($packageOutputFolder)){	
		&$nugetExe "pack" (Join-Path -path $scriptFolder -childpath $nuspecName)
	}
	Else{
		&$nugetExe "pack" (Join-Path -path $scriptFolder -childpath $nuspecName) '-OutputDirectory' $packageOutputFolder
	}	
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
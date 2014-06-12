Param(
  [string]$versionType,
  [string]$manualVersion
)

$nugetExe = "./NuGet.exe"
$tempNuspecFile = "temp.nuspec"
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
	Write-Host "HEHEHEHOHOHO"
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
		$versionString += "-alpha" + (Get-Date -format yyyyMMddHHmmss)
	}
	return $versionString
}

#------------------
#Main
#------------------

#Get version number
If([System.String]::IsNullOrEmpty($manualVersion)){
	$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"	
	Write-Host "Current branch is" $gitBranch	
	$latestVersion = GetLatestVersionNumber	
	Write-Host "Latest version is" $latestVersion	
	$version = GetNextVersionNumber $latestVersion $versionType $gitBranch	
}
Else{
	$version = $manualVersion	
}

#Pack package
(Get-Content "Template.nuspec") | 
Foreach-Object {$_ -replace "{version}", $version} | 
Set-Content $tempNuspecFile
&$nugetExe "pack" $tempNuspecFile

#Mark commit with a tag
if($versionType -ne "alpha"){
	CreateTagForCommit($version)
}


EXIT

#reserved for future use
$gitCommit = &"git" "rev-list" "HEAD" "--count"
$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"
&$nugetExe "pack" $nuspecPath #"-OutputDirectory" $currentPackageDir
#&$nugetExe "push" MIP.AutoMoq.1.6.1.1.nupkg br3dZd! -s http://nuget.leoburnett.de
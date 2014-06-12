$packageDirectory = "bin\NugetPackages"
$libDirectory = "bin\Debug"
$nugetExe = ".\NuGet.exe"

#reserved for future use
$gitCommit = &"git" "rev-list" "HEAD" "--count"
$gitBranch = &"git" "symbolic-ref" "--short" "HEAD"

$nugetPackages = @{}

$nugetPackages.Add("Full",
@("MIP.BLL.Core.dll","MIP.BLL.Infrastructure.dll","MIP.Common.dll","MIP.Core.dll","MIP.Data.Services.Common.dll","MIP.Data.Services.dll","MIP.DataAccess.dll","MIP.Domain.Administration.dll","MIP.Domain.Mappings.Administration.dll","MIP.Domain.Market.dll","MIP.Infrastructure.dll","MIP.MessageBus.dll","MIP.RemoteLogging.dll","MIP.Security.STS.dll","MIP.ServiceModel.dll","MIP.Services.Windows.dll","MIP.Unity.dll","MIP.Web.dll"))

#$nugetPackages.Add('Another',@("MIP.Web.dll", "MIP.Security.STS.dll"))

$nuspecTemplate = 
'<?xml version="1.0" ?> 
  <package>
    <metadata>
    <id>{id}</id> 
    <version>{version}</version> 
    <title>{title}</title> 
    <authors>LB</authors> 
    <owners>LB</owners> 
    <requireLicenseAcceptance>false</requireLicenseAcceptance> 
    <description>{title}</description> 
    <releaseNotes></releaseNotes> 
    <copyright>Copyright 2014</copyright> 
  </metadata>
</package>'

$packageDirectory = "bin\NugetPackages"
$libDirectory = "bin\Debug"

$RootDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$PackageDir = $RootDir + "\" + $packageDirectory

Write-Host "Cleaning package folder..."
Remove-Item $PackageDir -recurse

Write-Host "Creating root package folder.."
New-Item -ItemType directory -Path $PackageDir

Write-Host "Forming packages..."
ForEach ($package in $nugetPackages.GetEnumerator()){
	$packageId = "MIP.Core_" + $package.Key;
	Write-Host "Combining package		" $packageId	
	
	$currentPackageDir = $PackageDir + "\" + $package.Key
	New-Item -ItemType directory -Path $currentPackageDir
	New-Item -ItemType directory -Path $currentPackageDir\lib
	New-Item -ItemType file -Path $currentPackageDir\$packageId.nuspec
	
	$nuspec = $nuspecTemplate -replace "{id}", $packageId
	$nuspec = $nuspec -replace "{title}", ("MIP.Core subset " + $package.Key)
	$nuspec = $nuspec -replace "{version}", "1.1.5.3-alpha10"
	$nuspec = $nuspec -replace "{description}", ("MIP.Core subset " + $package.Key)
	
	$nuspecPath = $currentPackageDir + "\" + $packageId + ".nuspec"
	$nuspec >> $nuspecPath
	
	ForEach ($lib in $package.Value.GetEnumerator()){
		Copy-Item $RootDir\$libDirectory\$lib $currentPackageDir\lib\		
	}
	
	&$nugetExe "pack" $nuspecPath #"-OutputDirectory" $currentPackageDir
	#&$nugetExe "push" MIP.AutoMoq.1.6.1.1.nupkg br3dZd! -s http://nuget.leoburnett.de
}
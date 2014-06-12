SET buildMode=Release
IF NOT "%1"=="" SET buildMode=%1

C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe /verbosity:m /nologo ..\TabChecker.UI\TabChecker.UI.sln /t:Clean /p:Configuration=%buildMode%;TargetFrameworkVersion=v4.5
C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe /verbosity:m /nologo ..\TabChecker.UI\TabChecker.UI.sln /t:Rebuild /p:Configuration=%buildMode%;TargetFrameworkVersion=v4.5
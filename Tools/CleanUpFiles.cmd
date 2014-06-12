if not exist "PackageHistory" mkdir "PackageHistory"
move "*.nupkg"  ".\PackageHistory"
del "*.nuspec"
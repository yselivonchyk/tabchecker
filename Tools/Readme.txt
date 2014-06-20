This folder contains templates for creation of Nuget packages and pushing them to Nuget server.
Newly crated Nuget packages version would follow SemVer specification if package is inside git repository. 
Please, read instructions below.

How to use with a new project:
1. Copy all files and folders to a subfolder inside your project
2. Modify .nuspec file inside NuspecTemplates folder so it would target proper libraries and files.
3. Add more .nuspec files if you would like to pack several packages at once.
4. Modify .gitignore file to ignore .nuspec and .nuget files. (Manually add .nuspec files from templates folder).
5. Modify "Build.cmd" to have your project rebuild each time you assemble a package.
6. Modify "PushNugetLocaly.cmd" if you want to use local Nuget source.
7. Make sure that you have "Git command line integration". This option can be chosen during GIT installation.

Core functions description:
1. Create one or many Nuget packages using corresponding "Pack*" scripts. 
One package will be created for each "*.nuspec" template from the NuspecTemplates folder. 
Created packages and corresponding nuspec files will reside in the script folder.
Previously created packages will be moved to PackageHistory folder.
1.1 PackPrerelease.cmd scripts creates new ALPHA version that is guaranteed to have version greater then any already existing script.
1.2 PackPatch.cmd, PackMinor.cmd, PackMajor.cmd create a new package with incremented Major, Minor or Patch version subpart and other sub-parts changed in correspondence to SemVer specification.
Also if package is placed inside Git repository and Git command line integration is present script will try to  "git tag" existing repository so all other team members will be aware of new version being released. 
1.3 AssembleScript can be called from console manually. In case of manual call developer can specify any proper version manually.
Example of console command:  powershell -noexit -file "AssembleScript.ps1" "alpha" "1.2.3-manual12345"
2. Push Nuget packages to nuget repository.
2.1 PushNuget.cmd pushes Nuget packages present in the script folder to leoburnet Nuget repository
2.2 PushNugetLocaly.cmd copies Nuget packages to local Nuget source. Feel free to set proper path to you own local repository. 
# Set framework version
$dotnet_version = (dotnet --version)
if ($dotnet_version -match "^(\d+\.\d+)") {
    $framework_version = $Matches[1]
} else {
    Write-Error "Could not determine .NET version.  Using default 8.0."
    $framework_version = "8.0"
}

# Update Renode_NET.sln (replace Debug with Release)
(Get-Content "Renode_NET.sln") | ForEach-Object { $_ -replace "(ReleaseHeadless\|Any CPU\..+ = )Debug", '$1Release' } | Set-Content "Renode_NET.sln"

# Update System.Drawing.Common to 5.0.3
$csprojFiles = Get-ChildItem -Path "$env:SRC_DIR" -Filter "*\.csproj" -Recurse | Where-Object {$_.FullName -match "termsharp(\\|/)TermSharp_NET\.csproj|termsharp(\\|/)xwt(\\|/)Xwt\..+"}
foreach ($file in $csprojFiles) {
    (Get-Content $file.FullName) | ForEach-Object { $_ -replace "<PackageReference Include=`"System\.Drawing\.Common`" Version=`"5\..*`" />", "<PackageReference Include=`"System.Drawing.Common`" Version=`"5.0.3`" />" } | Set-Content $file.FullName
}

# Remove excessive warnings .csproj files (TargetFramework and NoWarn)
$csprojFiles = Get-ChildItem -Path "$env:SRC_DIR" -Filter "*.csproj" -Recurse | Where-Object {$_.FullName -match "(lib|src|tests)"}
foreach ($file in $csprojFiles) {
    $csprojContent = (Get-Content $file.FullName)
    $csprojContent = $csprojContent -replace "(<PropertyGroup>)", "`$1`n`t`t<NoWarn>CS0168;CS0219;CS8981;SYSLIB0050;SYSLIB0051</NoWarn>"
    Set-Content -Path $file.FullName -Value $csprojContent
}

# Install renode-cores .so where they are looked for
New-Item -ItemType Directory -Path "$Env:SRC_DIR\src\Infrastructure\src\Emulator\Cores\bin\Release\lib" -Force
Copy-Item -Path "$Env:BUILD_PREFIX\Library\lib\renode-cores\*" -Destination "$Env:SRC_DIR\src\Infrastructure\src\Emulator\Cores\bin\Release\lib" -Force

# Remove C cores not built in this recipe
Remove-Item -Path "$Env:SRC_DIR\src\Infrastructure\src\Emulator\Cores\translate*.cproj" -Force

# Build with dotnet
New-Item -ItemType Directory -Path "$Env:PREFIX\Library\lib" -Force
& $Env:RECIPE_DIR\helpers\renode_build_with_dotnet.ps1 $framework_version

# Install procedure
New-Item -ItemType Directory -Path "$Env:PREFIX\libexec\$Env:PKG_NAME" -Force
Copy-Item -Path "output\bin\Release\net$framework_version\*" -Destination "$Env:PREFIX\libexec\$Env:PKG_NAME" -Recurse -Force

New-Item -ItemType Directory -Path "$Env:PREFIX\opt\$Env:PKG_NAME\scripts", "$Env:PREFIX\opt\$Env:PKG_NAME\platforms", "$Env:PREFIX\opt\$Env:PKG_NAME\tests", "$Env:PREFIX\opt\$Env:PKG_NAME\tools", "$Env:PREFIX\opt\$Env:PKG_NAME\licenses" -Force

Copy-Item -Path ".renode-root" -Destination "$Env:PREFIX\opt\$Env:PKG_NAME" -Force
Copy-Item -Path "scripts\*" -Destination "$Env:PREFIX\opt\$Env:PKG_NAME\scripts" -Recurse -Force
Copy-Item -Path "platforms\*" -Destination "$Env:PREFIX\opt\$Env:PKG_NAME\platforms" -Recurse -Force
Copy-Item -Path "tests\*" -Destination "$Env:PREFIX\opt\$Env:PKG_NAME\tests" -Recurse -Force
Copy-Item -Path "tools\metrics_analyzer", "tools\execution_tracer", "tools\gdb_compare", "tools\sel4_extensions" -Destination "$Env:PREFIX\opt\$Env:PKG_NAME\tools" -Recurse -Force

Copy-Item "lib\resources\styles\robot.css" "$Env:PREFIX\opt\$Env:PKG_NAME\tests" -Force

& tools\packaging\common_copy_licenses.ps1 "$Env:PREFIX\opt\$Env:PKG_NAME\licenses" linux
Copy-Item -Path "$Env:PREFIX\opt\$Env:PKG_NAME\licenses" -Destination "license-files" -Recurse -Force

# Update robot_tests_provider.py (replace path to robot.css)
(Get-Content "$Env:PREFIX\opt\$Env:PKG_NAME\tests\robot_tests_provider.py") | ForEach-Object { $_ -replace "os\.path\.join\(this_path, '\.\./lib/resources/styles/robot\.css'\)", "os.path.join(this_path,'robot.css')" } | Set-Content "$Env:PREFIX\opt\$Env:PKG_NAME\tests\robot_tests_provider.py"

# Create renode.cmd
New-Item -ItemType File -Path "$Env:PREFIX\bin\renode.cmd" -Force
@"
@echo off
call %DOTNET_ROOT%\dotnet exec %CONDA_PREFIX%\libexec\renode-cli\Renode.dll %*
"@ | Out-File -FilePath "$Env:PREFIX\bin\renode.cmd" -Encoding ascii
# No chmod +x needed in PowerShell

# Create renode-test.cmd
New-Item -ItemType File -Path "$Env:PREFIX\bin\renode-test.cmd" -Force
@"
@echo off
setlocal enabledelayedexpansion
set "STTY_CONFIG=%stty -g 2^>nul%"
python3 "%CONDA_PREFIX%\opt\renode-cli\tests\run_tests.py" --robot-framework-remote-server-full-directory "%CONDA_PREFIX%\libexec\renode-cli" %*
set "RESULT_CODE=%ERRORLEVEL%"
if not "%STTY_CONFIG%"=="" stty "%STTY_CONFIG%"
exit /b %RESULT_CODE%
"@ | Out-File -FilePath "$Env:PREFIX\bin\renode-test.cmd" -Encoding ascii
# No chmod +x needed in PowerShell


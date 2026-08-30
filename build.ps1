param(
    [string]$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\A Dance of Fire and Ice",
    [string]$GameManagedDir = "",
    [string]$UmmDir = "",
    [string]$WorkbenchDir = "",
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($GameManagedDir)) {
    $GameManagedDir = Join-Path $GameDir "A Dance of Fire and Ice_Data\Managed"
}

if ([string]::IsNullOrWhiteSpace($UmmDir)) {
    $ummCandidates = @(
        (Join-Path $GameManagedDir "UnityModManager"),
        (Join-Path $GameDir "UnityModManager"),
        $GameManagedDir
    )
    $UmmDir = $ummCandidates | Where-Object {
        Test-Path (Join-Path $_ "UnityModManager.dll")
    } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($UmmDir)) {
    throw "UnityModManager.dll not found. Pass -UmmDir."
}

if ([string]::IsNullOrWhiteSpace($WorkbenchDir)) {
    $parent = Split-Path $PSScriptRoot -Parent
    $workbenchCandidates = @(
        (Join-Path $GameDir "Mods\ADOFAIWorkbench"),
        (Join-Path $parent "ADOFAIWorkbench\src\bin\$Configuration")
    )
    $WorkbenchDir = $workbenchCandidates | Where-Object {
        Test-Path (Join-Path $_ "ADOFAIWorkbench.dll")
    } | Select-Object -First 1
}
if ([string]::IsNullOrWhiteSpace($WorkbenchDir)) {
    throw "ADOFAIWorkbench.dll not found. Install/build ADOFAIWorkbench or pass -WorkbenchDir."
}

$required = @(
    (Join-Path $GameManagedDir "Assembly-CSharp.dll"),
    (Join-Path $GameManagedDir "UnityEngine.CoreModule.dll"),
    (Join-Path $UmmDir "UnityModManager.dll"),
    (Join-Path $WorkbenchDir "ADOFAIWorkbench.dll")
)
foreach ($path in $required) {
    if (-not (Test-Path $path -PathType Leaf)) {
        throw "Required reference not found: $path"
    }
}

$msbuild = (Get-Command msbuild.exe -ErrorAction SilentlyContinue).Path
if (-not $msbuild) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild `
            -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
    }
}
if (-not $msbuild) {
    throw "MSBuild.exe not found. Install Visual Studio Build Tools (.NET desktop build tools)."
}

$project = Join-Path $PSScriptRoot "src\ADOFAITileMeasure.csproj"
Write-Host "Building ADOFAITileMeasure ($Configuration)"
Write-Host "Managed   : $GameManagedDir"
Write-Host "UMM       : $UmmDir"
Write-Host "Workbench : $WorkbenchDir"

& $msbuild $project /t:Rebuild /m /nologo /verbosity:minimal `
    /p:Configuration=$Configuration `
    /p:Platform=AnyCPU `
    /p:GameManagedDir="$GameManagedDir" `
    /p:UmmDir="$UmmDir" `
    /p:WorkbenchDir="$WorkbenchDir"
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

$binDir = Join-Path $PSScriptRoot "src\bin\$Configuration"
$dll = Join-Path $binDir "ADOFAITileMeasure.dll"
$pdb = Join-Path $binDir "ADOFAITileMeasure.pdb"
if (-not (Test-Path $dll -PathType Leaf)) {
    throw "Expected DLL was not produced: $dll"
}

$infoPath = Join-Path $PSScriptRoot "Info.json"
$info = Get-Content $infoPath -Raw | ConvertFrom-Json
$version = [string]$info.Version
if ([string]::IsNullOrWhiteSpace($version)) {
    throw "Info.json does not contain a valid Version."
}

$out = Join-Path $PSScriptRoot "release\ADOFAITileMeasure"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $out | Out-Null
Copy-Item $dll $out
if (Test-Path $pdb -PathType Leaf) { Copy-Item $pdb $out }
Copy-Item $infoPath $out

$zip = Join-Path $PSScriptRoot ("ADOFAITileMeasure-v{0}.zip" -f $version)
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $out "*") -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Built: $zip"

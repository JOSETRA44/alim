# Descarga los binarios nativos de TDLib para ALIM.
#
# Windows : tdjson.dll (+ OpenSSL/zlib) desde el paquete NuGet
#           tdlib.native.win-x64 (proyecto ForNeVeR/tdlib.native) -> windows/tdlib/
# Android : libtdjson.so por ABI desde up9cloud/android-libtdjson
#           -> android/app/src/main/jniLibs/<abi>/   (best-effort)
#
# Ambos destinos estan en .gitignore: los binarios nunca se commitean.
# Uso:  pwsh scripts/setup_tdlib.ps1 [-SkipAndroid]

param(
    [switch]$SkipAndroid
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

# --- Windows: tdjson.dll --------------------------------------------------

$winDir = Join-Path $repoRoot 'windows\tdlib'
if (Test-Path (Join-Path $winDir 'tdjson.dll')) {
    Write-Host "[win] tdjson.dll ya existe en windows/tdlib - nada que hacer"
} else {
    Write-Host "[win] consultando versiones de tdlib.native.win-x64 en NuGet..."
    $index = Invoke-RestMethod 'https://api.nuget.org/v3-flatcontainer/tdlib.native.win-x64/index.json'
    $version = $index.versions | Select-Object -Last 1
    Write-Host "[win] descargando tdlib.native.win-x64 $version ..."
    $tmp = Join-Path ([IO.Path]::GetTempPath()) "tdlib_native_$version"
    $nupkg = "$tmp.nupkg"
    Invoke-WebRequest "https://api.nuget.org/v3-flatcontainer/tdlib.native.win-x64/$version/tdlib.native.win-x64.$version.nupkg" -OutFile $nupkg
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Expand-Archive $nupkg -DestinationPath $tmp
    $native = Get-ChildItem -Recurse (Join-Path $tmp 'runtimes') -Filter '*.dll' |
        Where-Object { $_.FullName -match 'win-x64' }
    if (-not $native) { throw "El paquete NuGet no contiene dlls win-x64" }
    New-Item -ItemType Directory -Force $winDir | Out-Null
    $native | ForEach-Object { Copy-Item $_.FullName $winDir -Force }
    Set-Content (Join-Path $winDir 'VERSION.txt') "tdlib.native.win-x64 $version"
    Remove-Item $nupkg -Force
    Remove-Item -Recurse -Force $tmp
    Write-Host "[win] listo: $((Get-ChildItem $winDir -Filter '*.dll').Name -join ', ')"
}

# --- Android: libtdjson.so (best-effort) -----------------------------------

if ($SkipAndroid) {
    Write-Host "[android] omitido (-SkipAndroid)"
    exit 0
}

try {
    $jniRoot = Join-Path $repoRoot 'android\app\src\main\jniLibs'
    if (Test-Path (Join-Path $jniRoot 'arm64-v8a\libtdjson.so')) {
        Write-Host "[android] libtdjson.so ya existe - nada que hacer"
        exit 0
    }
    Write-Host "[android] consultando release de up9cloud/android-libtdjson..."
    $release = Invoke-RestMethod 'https://api.github.com/repos/up9cloud/android-libtdjson/releases/latest'
    # El release publica un unico jniLibs.tar.gz con la estructura
    # <abi>/libtdjson.so ya lista para android/app/src/main/jniLibs.
    $asset = $release.assets | Where-Object { $_.name -eq 'jniLibs.tar.gz' } | Select-Object -First 1
    if (-not $asset) { throw "el release $($release.tag_name) no contiene jniLibs.tar.gz" }
    Write-Host "[android] descargando $($asset.name) ($($release.tag_name), $([math]::Round($asset.size/1MB)) MB)..."
    $tarball = Join-Path ([IO.Path]::GetTempPath()) 'alim_jniLibs.tar.gz'
    Invoke-WebRequest $asset.browser_download_url -OutFile $tarball
    New-Item -ItemType Directory -Force $jniRoot | Out-Null
    tar -xzf $tarball -C $jniRoot
    Remove-Item $tarball -Force
    # El tarball puede envolver el contenido en un directorio jniLibs/.
    $nested = Join-Path $jniRoot 'jniLibs'
    if (Test-Path $nested) {
        Get-ChildItem $nested | Move-Item -Destination $jniRoot -Force
        Remove-Item $nested -Recurse -Force
    }
    $abis = (Get-ChildItem $jniRoot -Directory).Name -join ', '
    Write-Host "[android] ABIs instalados: $abis"
    Set-Content (Join-Path $jniRoot 'VERSION.txt') "up9cloud/android-libtdjson $($release.tag_name)"
} catch {
    Write-Warning "[android] no se pudieron descargar los .so: $_"
    Write-Warning "[android] la app Android funcionara con el motor mock hasta ejecutar de nuevo este script"
}

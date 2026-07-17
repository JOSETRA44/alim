# Aprovisiona OpenSSL (dev) para el build de Windows.
#
# Por qué hace falta: el motor Supabase cifra su base local con SQLCipher, y
# el plugin `sqlcipher_flutter_libs` enlaza contra OpenSSL en Windows
# (`find_package(OpenSSL)` en su CMakeLists). A diferencia de Android, no trae
# los binarios: hay que darle cabeceras + librerías de enlace del sistema.
#
# Las DLLs de OpenSSL que ya acompañan a TDLib (windows/tdlib/) NO sirven aquí:
# son solo runtime, sin headers ni .lib.
#
# Uso:  pwsh scripts/setup_openssl.ps1
# Luego: flutter build windows

$ErrorActionPreference = 'Stop'

$vcpkgRoot = if ($env:VCPKG_ROOT) { $env:VCPKG_ROOT } else { 'C:\vcpkg' }
$vcpkgExe = Join-Path $vcpkgRoot 'vcpkg.exe'

if (-not (Test-Path $vcpkgExe)) {
    Write-Error @"
No se encontró vcpkg en '$vcpkgRoot'.
Instálalo con:
    git clone https://github.com/microsoft/vcpkg C:\vcpkg
    C:\vcpkg\bootstrap-vcpkg.bat
O define VCPKG_ROOT si ya lo tienes en otra ruta.
"@
}

$includeDir = Join-Path $vcpkgRoot 'installed\x64-windows\include\openssl'
if (Test-Path $includeDir) {
    Write-Host "OpenSSL ya está instalado en $vcpkgRoot. Nada que hacer." -ForegroundColor Green
    exit 0
}

Write-Host "Instalando openssl:x64-windows (tarda varios minutos)..." -ForegroundColor Cyan
& $vcpkgExe install openssl:x64-windows
if ($LASTEXITCODE -ne 0) { Write-Error "vcpkg falló con código $LASTEXITCODE" }

Write-Host "OpenSSL listo. Ya puedes ejecutar: flutter build windows" -ForegroundColor Green

# build.ps1 - Build script for Luna Chat Windows MSIX package
# Place this script in the root of the Luna Chat project (v4/luna_chat)

param (
    [string]$Configuration = "Release",
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$buildDir = Join-Path $projectRoot ".build"
$buildOutputDir = Join-Path $buildDir "output"
$msixConfigPath = Join-Path $projectRoot "msix_config.yaml"
$certPath = Join-Path $projectRoot "test_certificate.pfx"
$certPassword = "YourSecurePassword123!"

# Create build directories if they don't exist
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildOutputDir | Out-Null

function Write-Header {
    param([string]$message)
    Write-Host "`n=== $message ===" -ForegroundColor Cyan
}

try {
    # Step 1: Build Flutter Windows App
    if (-not $SkipBuild) {
        Write-Header "Building Flutter Windows App"
        Set-Location $projectRoot
        
        # Clean previous build
        flutter clean
        
        # Get dependencies
        flutter pub get
        
        # Build Windows app
        flutter build windows --$Configuration
    }

    # Step 2: Create MSIX Package
    Write-Header "Creating MSIX Package"
    Set-Location $projectRoot
    
    # Install msix package if not already installed
    if (-not (Test-Path ".dart_tool/package_config.json")) {
        dart pub get
    }
    if (-not (dart pub global list | Select-String "msix")) {
        dart pub global activate msix
    }

    # Create msix_config.yaml
    @"
msix_config:
  display_name: "Luna Chat"
  publisher_display_name: "Luna Inference"
  identity_name: "com.lunainference.lunachat"
  msix_version: "1.0.0.0"
  certificate_path: "$(Split-Path -Leaf $certPath)"
  certificate_password: "$certPassword"
  publisher: "CN=LunaInference"
  logo_path: "windows/runner/resources/app_icon.ico"
  capabilities: "internetClient,privateNetworkClientServer"
  architecture: "x64"
  generate_during_build: false
"@ | Out-File -FilePath $msixConfigPath -Encoding utf8

    # Create self-signed certificate
    Write-Host "Creating self-signed certificate..."
    $cert = New-SelfSignedCertificate `
        -Type Custom `
        -Subject "CN=LunaInference" `
        -KeyUsage DigitalSignature `
        -FriendlyName "LunaInference" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -KeyLength 2048 `
        -KeyAlgorithm RSA

    # Export certificate
    $securePassword = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
    $cert | Export-PfxCertificate -FilePath $certPath -Password $securePassword

    # Import certificate to trusted store
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
        [System.Security.Cryptography.X509Certificates.StoreName]::TrustedPeople,
        [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
    )
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    try {
        $store.Add($cert)
        Write-Host "✅ Certificate added to TrustedPeople store"
    } catch {
        Write-Host "⚠️  Warning: Could not add certificate to TrustedPeople store: $_"
    } finally {
        $store.Close()
    }

    # Create MSIX package
    Write-Host "Creating MSIX package..."
    $env:FLUTTER_ROOT = (Get-Command flutter).Source | Split-Path -Parent | Split-Path -Parent
    dart run msix:create

    # Copy MSIX to build output directory
    $msixFile = Get-ChildItem -Path "build/windows/x64/runner/Release/*.msix" -Recurse | Select-Object -First 1
    if (-not $msixFile) {
        $msixFile = Get-ChildItem -Path "build/windows/runner/Release/*.msix" -Recurse | Select-Object -First 1
    }
    if ($msixFile) {
        Copy-Item -Path $msixFile.FullName -Destination $buildOutputDir
        Write-Host "✅ MSIX package created at: $(Join-Path $buildOutputDir $msixFile.Name)"
    } else {
        Write-Error "❌ Failed to find generated MSIX package"
    }

    Write-Host "`n🎉 Build completed successfully!" -ForegroundColor Green
    Write-Host "Output files are in: $buildOutputDir" -ForegroundColor Green
    if ($msixFile) {
        Write-Host "MSIX Package: $(Join-Path $buildOutputDir $msixFile.Name)" -ForegroundColor Green
    }

} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
} finally {
    # Clean up sensitive files
    Set-Location $projectRoot
    if (Test-Path $certPath) {
        Remove-Item $certPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $msixConfigPath) {
        Remove-Item $msixConfigPath -Force -ErrorAction SilentlyContinue
    }
}

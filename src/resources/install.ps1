$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -Object 'Setting up...' -ForegroundColor Cyan

if (-not (Get-Command -Name spicetify -ErrorAction SilentlyContinue)) {
  Write-Host -Object 'Spicetify not found. Installing it for you...' -ForegroundColor Yellow
  $Parameters = @{
    Uri             = 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1'
    UseBasicParsing = $true
  }
  Invoke-WebRequest @Parameters | Invoke-Expression
}

spicetify path userdata | Out-Null
$spiceUserDataPath = (spicetify path userdata)
if (-not (Test-Path -Path $spiceUserDataPath -PathType Container)) {
  $spiceUserDataPath = "$env:APPDATA\spicetify"
}
$marketAppPath = "$spiceUserDataPath\CustomApps\marketplace"
$marketThemePath = "$spiceUserDataPath\Themes\marketplace"
$isThemeInstalled = $(
  spicetify path -s | Out-Null
  -not $LASTEXITCODE
)

Write-Host -Object 'Removing and creating Marketplace folders...' -ForegroundColor Cyan
Remove-Item -Path $marketAppPath, $marketThemePath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $marketAppPath, $marketThemePath -ItemType Directory -Force | Out-Null

Write-Host 'Downloading Marketplace...' -ForegroundColor Cyan
$marketArchivePath = "$marketAppPath\marketplace.zip"
$unpackedFolderPath = "$marketAppPath\spicetify-marketplace-dist"
$Parameters = @{
  Uri             = 'https://github.com/spicetify/spicetify-marketplace/releases/latest/download/spicetify-marketplace.zip'
  UseBasicParsing = $true
  OutFile         = $marketArchivePath
}
Invoke-WebRequest @Parameters

Write-Host -Object 'Unzipping and installing...' -ForegroundColor Cyan
Expand-Archive -Path $marketArchivePath -DestinationPath $marketAppPath -Force
Move-Item -Path "$unpackedFolderPath\*" -Destination $marketAppPath -Force
Remove-Item -Path $marketArchivePath, $unpackedFolderPath -Force
spicetify config custom_apps spicetify-marketplace- -q
spicetify config custom_apps marketplace
spicetify config inject_css 1 replace_colors 1

Write-Host -Object 'Downloading placeholder theme...' -ForegroundColor Cyan
$Parameters = @{
  Uri             = 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/color.ini'
  UseBasicParsing = $true
  OutFile         = "$marketThemePath\color.ini"
}
Invoke-WebRequest @Parameters

Write-Host -Object 'Applying...' -ForegroundColor Cyan
if (-not $isThemeInstalled) {
  spicetify config current_theme marketplace
}
spicetify backup
spicetify apply

Write-Host -Object 'Done!' -ForegroundColor Green
Write-Host -Object 'If nothing has happened, check the messages above for errors'

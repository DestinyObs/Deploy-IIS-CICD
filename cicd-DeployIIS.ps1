param(
    [string]$RepoUrl = "https://github.com/softwaregurukulamdevops/SGbookportal.git",
    [string]$ClonePath = "C:\SGbookportal",
    [string]$SitePath = "C:\inetpub\wwwroot\sgbookportal",
    [string]$SiteName = "SGBookPortal",
    [string]$PoolName = "SGBookPortalPool",
    [int]$Port = 5000
)

# Ensure IIS is installed once (optional for automation)
if (-not (Get-WindowsFeature Web-Server).Installed) {
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
}

# Git clone or pull
if (-not (Test-Path $ClonePath)) {
    git clone $RepoUrl $ClonePath
} else {
    Set-Location $ClonePath
    git reset --hard
    git pull origin main
}

# Create web root
New-Item -Path $SitePath -ItemType Directory -Force | Out-Null

# Publish app
dotnet publish "$ClonePath\BookPortel\BookPortel.csproj" -c Release -o $SitePath

# Set permissions
icacls $SitePath /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null

# Configure IIS
Import-Module WebAdministration

if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) {
    Remove-Website -Name $SiteName
}

if (-not (Test-Path "IIS:\AppPools\$PoolName")) {
    New-WebAppPool -Name $PoolName
    Set-ItemProperty "IIS:\AppPools\$PoolName" -Name managedRuntimeVersion -Value ""
}

New-Website -Name $SiteName -Port $Port -PhysicalPath $SitePath -ApplicationPool $PoolName
Start-Website -Name $SiteName

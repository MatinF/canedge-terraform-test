# PowerShell script to build and push the Synapse Table Mapper Docker image to GitHub Container Registry
# Usage: .\deploy-docker-image.ps1

# Function to show usage
function Show-Usage {
    Write-Host "Deploy Docker Image to GitHub Container Registry" -ForegroundColor Cyan
    Write-Host "This script builds and pushes the Synapse Table Mapper Docker image to GitHub Container Registry." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "1. Docker Desktop for Windows must be installed and running."
    Write-Host "2. You need a GitHub Personal Access Token with write:packages and read:packages permissions."
    Write-Host ""
}

function Update-TerraformVariable {
    param (
        [string]$ImageUrl
    )
    
    $varFilePath = Join-Path (Get-Location) "variables.tf"
    $content = Get-Content -Path $varFilePath -Raw
    
    # Find the container_image variable definition and update it
    $pattern = '(variable\s+"container_image"\s+\{\s+description\s+=\s+".*"\s+type\s+=\s+".*"\s+default\s+=\s+").*(")'
    $replacement = "`${1}$ImageUrl`${2}"
    
    $newContent = $content -replace $pattern, $replacement
    Set-Content -Path $varFilePath -Value $newContent
    
    Write-Host "Updated container_image variable in variables.tf to: $ImageUrl" -ForegroundColor Green
}

# Show usage information
Show-Usage

# Check if Docker is available
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed or not in your PATH. Please install Docker Desktop for Windows." -ForegroundColor Red
    exit 1
}

# Change to the docker directory
$dockerPath = Join-Path (Get-Location) "docker"
if (-not (Test-Path $dockerPath)) {
    Write-Host "Error: Docker directory not found at $dockerPath" -ForegroundColor Red
    exit 1
}
Set-Location $dockerPath

# Get GitHub username and token
$githubUsername = Read-Host "Enter your GitHub username"
$githubPAT = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubPAT)
$PAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Define image tag
$imageTag = "ghcr.io/$githubUsername/canedge-synapse-map-tables:latest"

# Build the Docker image
Write-Host "Building Docker image: $imageTag..." -ForegroundColor Cyan
docker build -t $imageTag .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker build failed." -ForegroundColor Red
    exit 1
}

# Login to GitHub Container Registry
Write-Host "Logging in to GitHub Container Registry..." -ForegroundColor Cyan
$loginProcess = Start-Process -FilePath "docker" -ArgumentList "login", "ghcr.io", "-u", $githubUsername, "--password-stdin" -NoNewWindow -PassThru -RedirectStandardInput
[System.IO.File]::WriteAllText("/proc/$($loginProcess.Id)/fd/0", $PAT)
$loginProcess.WaitForExit()

if ($LASTEXITCODE -ne 0) {
    Write-Host "Alternative login method..." -ForegroundColor Yellow
    echo $PAT | docker login ghcr.io -u $githubUsername --password-stdin

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to log in to GitHub Container Registry." -ForegroundColor Red
        exit 1
    }
}

# Push the Docker image
Write-Host "Pushing Docker image to GitHub Container Registry..." -ForegroundColor Cyan
docker push $imageTag

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to push Docker image." -ForegroundColor Red
    exit 1
}

# Return to the container_app_job directory
Set-Location ..

# Update the Terraform variable
Update-TerraformVariable -ImageUrl $imageTag

Write-Host ""
Write-Host "Docker image deployed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Make sure to set the package visibility to public in GitHub:"
Write-Host "   - Go to https://github.com/$githubUsername?tab=packages"
Write-Host "   - Select 'canedge-synapse-map-tables'"
Write-Host "   - Click 'Package settings'"
Write-Host "   - Under 'Danger Zone', change the visibility to 'Public'"
Write-Host ""
Write-Host "2. Run the Terraform deployment with ./deploy_synapse.sh"

# Clean up sensitive data
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
Remove-Variable -Name PAT, BSTR, githubPAT

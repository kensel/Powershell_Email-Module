FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Install PowerShell 7
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        apt-transport-https \
        && \
    wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends powershell && \
    rm -rf /var/lib/apt/lists/* packages-microsoft-prod.deb

WORKDIR /src

# Copy only what's needed for the build
COPY src/EmailLibraryCore/EmailLibrary/EmailLibrary.csproj \
     src/EmailLibraryCore/EmailLibrary/EmailLibrary.cs \
     src/EmailLibraryCore/EmailLibrary/Builders.cs \
     src/EmailLibraryCore/EmailLibrary/

# Restore NuGet packages
RUN dotnet restore src/EmailLibraryCore/EmailLibrary/EmailLibrary.csproj

# Build Release
RUN dotnet build src/EmailLibraryCore/EmailLibrary/EmailLibrary.csproj \
    --configuration Release --no-restore

# --- Package the module ---
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS package

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        apt-transport-https \
        && \
    wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends powershell && \
    rm -rf /var/lib/apt/lists/* packages-microsoft-prod.deb

WORKDIR /module

# Copy built assemblies from build stage
COPY --from=build /src/src/EmailLibraryCore/EmailLibrary/bin/Release/net8.0/*.dll ./lib/net8.0/

# Copy PowerShell module files
COPY src/EmailModule/EmailModule.psm1 ./
COPY src/EmailModule/EmailModule.Libraries.ps1 ./

# Generate module manifest for PowerShell 7
RUN pwsh -NoLogo -NoProfile -Command 'New-ModuleManifest -Path /module/EmailModule.psd1 -RootModule EmailModule.psm1 -ModuleVersion "0.0.0" -CompatiblePSEditions @("Core") -Author "EmailModule" -Description "PowerShell Email Module built from Docker"'

# --- Test ---
COPY test/sample.eml /tmp/test.eml

# Copy test scripts
COPY test/test-get-mime.ps1 /tmp/test-get-mime.ps1

RUN pwsh -NoLogo -NoProfile -File /tmp/test-get-mime.ps1

# Show module info as a smoke test
COPY test/smoke-test.ps1 /tmp/smoke-test.ps1

RUN pwsh -NoLogo -NoProfile -File /tmp/smoke-test.ps1

# Default: print module help
CMD pwsh -NoLogo -NoProfile -Command 'Import-Module /module/EmailModule.psm1 -Force; Write-Output "EmailModule loaded. Cmdlets: Send-Email, Get-MimeMessage"; Get-Help Get-MimeMessage -Examples'

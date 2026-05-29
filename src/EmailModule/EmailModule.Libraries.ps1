# EmailModule.Libraries.ps1
if ($PSEdition -eq 'Core') {
    Get-ChildItem -Path (Join-Path $PSScriptRoot 'lib/net8.0') -Filter *.dll |
    ForEach-Object {
        try {
            Add-Type -Path $_.FullName -ErrorAction Stop
        } catch {
            Write-Warning "Could not load assembly: $($_.FullName)"
        }
    }
} else {
    $exclude = @(
        'System.Formats.Asn1.dll',
        'Microsoft.Bcl.AsyncInterfaces.dll',
        'Microsoft.Extensions.DependencyInjection.Abstractions.dll',
        'Microsoft.Extensions.Hosting.Abstractions.dll',
        'Microsoft.Extensions.Logging.Abstractions.dll',
        'Microsoft.Extensions.Primitives.dll',
        'System.Diagnostics.DiagnosticSource.dll',
        'System.Text.Encodings.Web.dll',
        'Microsoft.Extensions.WebEncoders.dll'
    )
    Get-ChildItem -Path (Join-Path $PSScriptRoot 'lib/net472') -Filter *.dll |
    Where-Object  { $_.Name -notin $exclude } |
    ForEach-Object {
        $Name = $_.FullName
        try {
            Add-Type -Path $_.FullName -ErrorAction Stop
        } catch {
            Write-Warning "Could not load assembly: $Name. $_"
        }
    }
}


function Get-Banner {
    Write-Output "    ____           _ __  __  ___        __     __    "
    Write-Output "   / __/_ _  ___ _(_/ / /  |/  /__  ___/ /_ __/ /__  "
    Write-Output "  / _//  ' \/ _ '/ / / / /|_/ / _ \/ _  / // / / -_) "
    Write-Output " /___/_/_/_/\_,_/_/_/ /_/  /_/\___/\_,_/\_,_/_/\__/  "
    Write-Output ""
Write-Output "Cmdlets available:" -NoNewline
Write-Output " Send-Email, Get-MimeMessage"
Write-Output "Get help:" -NoNewline
Write-Output " Get-Help Send-Email or Get-Help Get-MimeMessage"
}

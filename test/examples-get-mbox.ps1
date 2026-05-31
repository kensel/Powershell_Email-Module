# Comprehensive examples demonstrating Get-MboxMessage capabilities
# This script shows real-world usage patterns

param(
    [string]$MboxFilePath = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\sample.mbox"
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$modulePath = Join-Path $repoRoot "src\EmailModule"

Import-Module $modulePath -Force

Write-Output "========================================"
Write-Output "Get-MboxMessage Comprehensive Examples"
Write-Output "========================================"
Write-Output ""

if (!(Test-Path $MboxFilePath)) {
    Write-Error "MBOX file not found: $MboxFilePath"
    exit 1
}

# Example 1: Basic iteration and display
Write-Output "Example 1: Basic Message Listing"
Write-Output "---"
Get-MboxMessage -Path $MboxFilePath | ForEach-Object {
    Write-Output "From:    $($_.From)"
    Write-Output "To:      $($_.To)"
    Write-Output "Subject: $($_.Subject)"
    Write-Output "Date:    $($_.Date)"
    Write-Output "---"
}

Write-Output ""
Write-Output "Example 2: Message Count"
Write-Output "---"
$totalMessages = @(Get-MboxMessage -Path $MboxFilePath).Count
Write-Output "Total messages in MBOX file: $totalMessages"

Write-Output ""
Write-Output "Example 3: Sender Analysis"
Write-Output "---"
$senderStats = Get-MboxMessage -Path $MboxFilePath | 
    Group-Object -Property From | 
    Select-Object Name, @{Name="MessageCount"; Expression={$_.Count}} |
    Sort-Object -Property MessageCount -Descending

Write-Output "Messages by sender:"
$senderStats | ForEach-Object {
    Write-Output "  $($_.Name): $($_.MessageCount) messages"
}

Write-Output ""
Write-Output "Example 4: With Body Hashes"
Write-Output "---"
Get-MboxMessage -Path $MboxFilePath -BodyHash SHA256 | 
    Select-Object Subject, @{Name="BodyHash"; Expression={$_.BodyHash ?? "N/A"}} | 
    ForEach-Object {
        Write-Output "Subject: $($_.Subject)"
        Write-Output "Hash:    $($_.BodyHash)"
        Write-Output ""
    }

Write-Output "Example 5: Content Analysis"
Write-Output "---"
$stats = Get-MboxMessage -Path $MboxFilePath | 
    Select-Object @{Name="HasText"; Expression={$_.BodyText -ne $null}}, 
                   @{Name="HasHtml"; Expression={$_.BodyHtml -ne $null}},
                   @{Name="HasAttachments"; Expression={$_.Attachments -ne $null}}

Write-Output "Content Statistics:"
Write-Output "  Messages with plain text: $(($stats | Where-Object HasText | Measure-Object).Count)"
Write-Output "  Messages with HTML: $(($stats | Where-Object HasHtml | Measure-Object).Count)"
Write-Output "  Messages with attachments: $(($stats | Where-Object HasAttachments | Measure-Object).Count)"

Write-Output ""
Write-Output "Example 6: Export to PSCustomObject Array"
Write-Output "---"
$allMessages = Get-MboxMessage -Path $MboxFilePath | 
    Select-Object MessageId, Subject, From, To, Date, BodyHash

Write-Output "Exported $($allMessages.Count) messages as custom objects"
Write-Output "First message:"
$allMessages | Select-Object -First 1 | Format-List

Write-Output "Example 7: Find Messages by Criteria"
Write-Output "---"
$withAttachments = Get-MboxMessage -Path $MboxFilePath | 
    Where-Object { $_.Attachments -ne $null }

Write-Output "Messages with attachments: $($withAttachments.Count)"

Write-Output ""
Write-Output "All examples completed successfully! ✓"

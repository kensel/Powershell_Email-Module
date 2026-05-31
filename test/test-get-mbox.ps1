# Test script for Get-MboxMessage cmdlet
param($ModulePath)

# Determine module path based on script location
if (!$ModulePath) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = Split-Path -Parent $scriptDir
    $ModulePath = Join-Path $repoRoot "src\EmailModule"
}

# Import the module
Import-Module $ModulePath -Force

# Test file location
$testMboxFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "sample.mbox"

Write-Output "Testing Get-MboxMessage cmdlet..."
Write-Output "Module path: $ModulePath"
Write-Output "Test MBOX file: $testMboxFile"
Write-Output ""

if (!(Test-Path $testMboxFile)) {
    Write-Error "Test MBOX file not found: $testMboxFile"
    exit 1
}

# Test 1: Basic get-mbox message
Write-Output "Test 1: Basic Get-MboxMessage"
try {
    $messages = Get-MboxMessage -Path $testMboxFile
    $count = ($messages | Measure-Object).Count
    Write-Output "✓ Successfully loaded $count messages from MBOX file"
    
    foreach ($msg in $messages) {
        Write-Output "  - From: $($msg.From)"
        Write-Output "    Subject: $($msg.Subject)"
        Write-Output "    Date: $($msg.Date)"
    }
} catch {
    Write-Error "✗ Test 1 failed: $_"
    exit 1
}

# Test 2: Get-MboxMessage with hash
Write-Output ""
Write-Output "Test 2: Get-MboxMessage with BodyHash"
try {
    $messages = Get-MboxMessage -Path $testMboxFile -BodyHash SHA256
    $count = ($messages | Measure-Object).Count
    Write-Output "✓ Successfully loaded $count messages with body hash"
    
    $firstMsg = $messages | Select-Object -First 1
    if ($firstMsg.BodyHash) {
        Write-Output "  - First message BodyHash: $($firstMsg.BodyHash)"
    }
} catch {
    Write-Error "✗ Test 2 failed: $_"
    exit 1
}

# Test 3: Piping messages
Write-Output ""
Write-Output "Test 3: Piping and filtering messages"
try {
    $filtered = Get-MboxMessage -Path $testMboxFile | Where-Object { $_.Subject -like "*Test*" }
    $count = ($filtered | Measure-Object).Count
    Write-Output "✓ Successfully filtered messages, found $count matches"
} catch {
    Write-Error "✗ Test 3 failed: $_"
    exit 1
}

# Test 4: Message property access
Write-Output ""
Write-Output "Test 4: Accessing message properties"
try {
    $msg = Get-MboxMessage -Path $testMboxFile | Select-Object -First 1
    Write-Output "✓ Message object created with properties:"
    Write-Output "  - MessageId: $($msg.MessageId)"
    Write-Output "  - Subject: $($msg.Subject)"
    Write-Output "  - From: $($msg.From)"
    Write-Output "  - To: $($msg.To)"
    Write-Output "  - Date: $($msg.Date)"
    Write-Output "  - BodyText length: $($msg.BodyText.Length)"
    Write-Output "  - BodyHtml length: $($msg.BodyHtml.Length)"
} catch {
    Write-Error "✗ Test 4 failed: $_"
    exit 1
}

Write-Output ""
Write-Output "All tests passed! ✓"

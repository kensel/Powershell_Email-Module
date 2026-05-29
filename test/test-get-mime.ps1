$ErrorActionPreference = "Stop"
Import-Module /module/EmailModule.psm1 -Force
Write-Output "=== Test: Basic Parsing ==="
$m = Get-MimeMessage -Path /tmp/test.eml
if ($m.Subject -ne "Test Email Subject") { throw "FAIL: Subject expected 'Test Email Subject' but got $($m.Subject)" }
if (-not $m.From.Contains("sender@example.com")) { throw "FAIL: From missing sender@example.com" }
if (-not $m.To.Contains("recipient@example.com")) { throw "FAIL: To missing recipient@example.com" }
if (-not $m.BodyText.Contains("plain text body")) { throw "FAIL: BodyText missing expected content" }
if (-not $m.BodyHtml.Contains("HTML")) { throw "FAIL: BodyHtml missing expected content" }
if ($m.MessageId -ne "test-message-id@example.com") { throw "FAIL: MessageId mismatch" }
if (-not $m.Attachments.Contains("test-attachment.txt")) { throw "FAIL: Attachments missing test-attachment.txt" }
Write-Output "PASS"
Write-Output ""
Write-Output "=== Test: Body Hash (SHA256) ==="
$m2 = Get-MimeMessage -Path /tmp/test.eml -BodyHash SHA256
if (-not $m2.BodyHash) { throw "FAIL: BodyHash should not be empty" }
if ($m2.BodyHash -notmatch "^BodyHtml=SHA256=[a-f0-9]{64}$") { throw "FAIL: BodyHash format mismatch: $($m2.BodyHash)" }
Write-Output "PASS: $($m2.BodyHash)"
Write-Output ""
Write-Output "=== Test: Body Hash (MD5) ==="
$m3 = Get-MimeMessage -Path /tmp/test.eml -BodyHash MD5
if ($m3.BodyHash -notmatch "^BodyHtml=MD5=[a-f0-9]{32}$") { throw "FAIL: MD5 BodyHash format mismatch: $($m3.BodyHash)" }
Write-Output "PASS: $($m3.BodyHash)"
Write-Output ""
Write-Output "=== Test: Error on missing file ==="
try {
    Get-MimeMessage -Path /tmp/nonexistent.eml
    throw "FAIL: Expected error was not thrown"
} catch {
    if ($_.Exception.Message -notmatch "did not return a result of True") { throw "FAIL: Unexpected error message: $($_.Exception.Message)" }
}
Write-Output "PASS"
Write-Output ""
Write-Output "=== All tests passed ==="

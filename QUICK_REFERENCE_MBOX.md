# Get-MboxMessage Quick Reference

## Installation & Loading

```powershell
# Import the module
Import-Module "C:\path\to\EmailModule"

# Verify available cmdlets
Get-Command -Module EmailModule
```

## Basic Syntax

```powershell
Get-MboxMessage -Path <string> [-BodyHash <string>]
```

## Quick Examples

### 1. List all messages
```powershell
Get-MboxMessage -Path 'backup.mbox'
```

### 2. Count messages
```powershell
(Get-MboxMessage -Path 'backup.mbox' | Measure-Object).Count
```

### 3. With hashes
```powershell
Get-MboxMessage -Path 'backup.mbox' -BodyHash SHA256
```

### 4. Filter by sender
```powershell
Get-MboxMessage -Path 'backup.mbox' | Where-Object { $_.From -like '*@example.com' }
```

### 5. Export to CSV
```powershell
Get-MboxMessage -Path 'backup.mbox' | Export-Csv messages.csv -NoTypeInformation
```

### 6. Find messages from last 30 days
```powershell
Get-MboxMessage -Path 'backup.mbox' | Where-Object { $_.Date -gt (Get-Date).AddDays(-30) }
```

### 7. Get messages with attachments
```powershell
Get-MboxMessage -Path 'backup.mbox' | Where-Object { $_.Attachments -ne $null }
```

### 8. Sender statistics
```powershell
Get-MboxMessage -Path 'backup.mbox' | Group-Object From | Sort-Object Count -Desc
```

### 9. Save as JSON
```powershell
Get-MboxMessage -Path 'backup.mbox' | ConvertTo-Json | Out-File messages.json
```

### 10. Process each message
```powershell
Get-MboxMessage -Path 'backup.mbox' | ForEach-Object {
    Write-Output "From: $($_.From)"
    Write-Output "Subject: $($_.Subject)"
}
```

## Common Properties

| Property | Example |
|----------|---------|
| From | "John Doe <john@example.com>" |
| To | "jane@example.com" |
| Subject | "Meeting Notes" |
| Date | 01/15/2026 14:30:00 |
| MessageId | <msg-123@example.com> |
| BodyText | "Email body content..." |
| BodyHtml | "<html><body>...</body></html>" |
| Attachments | "report.pdf;image.png" |
| BodyHash | "BodyText=SHA256=abc123..." |

## Hash Algorithms

Specify with `-BodyHash` parameter:
- MD5
- SHA1
- SHA256 (recommended)
- SHA384
- SHA512

## Output Format

Each message returns a PSCustomObject with:
- Email metadata (From, To, Date, Subject, MessageId, etc.)
- Content (BodyText, BodyHtml, ContentType)
- Headers (complete dictionary)
- Attachments (filename list)
- Optional BodyHash

## Pipeline Compatibility

✓ Works with Where-Object for filtering
✓ Works with Select-Object for property selection
✓ Works with Group-Object for grouping
✓ Works with Export-Csv for export
✓ Works with ConvertTo-Json
✓ Works with ForEach-Object for iteration

## Performance Tips

1. **Large Files**: Messages are streamed, no memory limit
2. **Hashing**: Only compute when needed (adds small overhead)
3. **Filtering**: Apply Where-Object early to reduce processing
4. **Pipeline**: Let PowerShell stream - don't collect into arrays unnecessarily

## Troubleshooting

### Issue: "Module not found"
```powershell
# Verify module path
$env:PSModulePath
# Import explicitly
Import-Module -Path "C:\path\to\EmailModule"
```

### Issue: "File not found"
```powershell
# Verify MBOX file exists
Test-Path "C:\emails\backup.mbox"
# Use full path if relative path doesn't work
Get-MboxMessage -Path (Resolve-Path "backup.mbox").Path
```

### Issue: "No messages returned"
```powershell
# Verify file is valid MBOX format
# MBOX messages start with "From " (space after From)
Get-Content "backup.mbox" -Head 1
```

## Comparison: Get-MimeMessage vs Get-MboxMessage

| Feature | Get-MimeMessage | Get-MboxMessage |
|---------|---|---|
| Input | Single .eml file | MBOX file |
| Output | Single message | Multiple messages |
| Usage | Individual emails | Batch processing |
| Size | One message | Any size |
| Stream | No | Yes |

## Related Commands

```powershell
# Send emails
Send-Email -AuthUser "user@example.com" -AuthPass $pass ...

# Process individual EML files
Get-MimeMessage -Path "email.eml"

# Combine with system commands
Get-ChildItem *.mbox | Get-MboxMessage
```

## Get Help

```powershell
# Full help
Get-Help Get-MboxMessage -Full

# Examples only
Get-Help Get-MboxMessage -Examples

# Parameter help
Get-Help Get-MboxMessage -Parameter Path
```

## Links

- Full Documentation: `docs/Get-MboxMessage.md`
- Examples Script: `test/examples-get-mbox.ps1`
- Test Suite: `test/test-get-mbox.ps1`
- Implementation Summary: `GET_MBOX_MESSAGE_IMPLEMENTATION.md`

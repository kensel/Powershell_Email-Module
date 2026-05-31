# Get-MboxMessage Cmdlet Documentation

## Overview

`Get-MboxMessage` is a PowerShell cmdlet that reads MBOX files (mailbox files) and streams individual email messages as PowerShell objects. This enables easy programmatic access to email data stored in MBOX format.

MBOX is a widely-used plain text format for storing email messages, commonly used by Unix-based mail systems, Thunderbird, and many email clients for backup/export functionality.

## Syntax

```powershell
Get-MboxMessage -Path <string> [-BodyHash <string>] [<CommonParameters>]
```

## Parameters

### -Path (string)
**Required**. Specifies the path to the MBOX file to read.
- Accepts pipeline input: Yes
- Validates path exists before processing

### -BodyHash (string)
**Optional**. Computes a hash of the message body content.
- Valid values: MD5, SHA1, SHA256, SHA384, SHA512
- Hash is computed against BodyHtml if present, otherwise BodyText
- Result format: `BodyHtml=SHA256=<hex_hash>` or `BodyText=SHA256=<hex_hash>`

## Output

Returns `PSCustomObject` for each message with the following properties:

| Property | Type | Description |
|----------|------|-------------|
| MessageId | string | MIME Message-ID header value |
| Date | DateTime | Message date/timestamp (UTC) |
| Subject | string | Email subject line |
| From | string | Formatted sender address(es) |
| To | string | Formatted recipient address(es) |
| Cc | string | Carbon copy recipients |
| Bcc | string | Blind carbon copy recipients |
| ReplyTo | string | Reply-To address |
| Sender | string | Sender address (if different from From) |
| Priority | string | Message priority level |
| Importance | string | Message importance level |
| XPriority | string | X-Priority header value |
| InReplyTo | string | In-Reply-To message ID |
| References | string | References header (message threading) |
| MimeVersion | string | MIME version |
| ContentType | string | Content-Type MIME type |
| ContentTransferEncoding | string | Content-Transfer-Encoding value |
| BodyText | string | Plain text body content |
| BodyHtml | string | HTML body content |
| Attachments | string | Semicolon-separated attachment filenames |
| Headers | object | All email headers as dictionary |
| BodyHash | string | Hash value (only when -BodyHash specified) |

## Examples

### Example 1: Basic Usage - List All Messages
```powershell
Get-MboxMessage -Path 'emails.mbox'
```

Stream all messages from an MBOX file and display them.

### Example 2: Count Messages
```powershell
(Get-MboxMessage -Path 'emails.mbox' | Measure-Object).Count
```

Count the total number of messages in an MBOX file.

### Example 3: Filter Messages by Sender
```powershell
Get-MboxMessage -Path 'emails.mbox' | Where-Object { $_.From -like '*@company.com' }
```

Find all messages from a specific company domain.

### Example 4: Export to CSV
```powershell
Get-MboxMessage -Path 'emails.mbox' | 
  Select-Object From, To, Subject, Date | 
  Export-Csv -Path 'emails.csv' -NoTypeInformation
```

Export message metadata to a CSV file for analysis.

### Example 5: Compute Body Hashes
```powershell
Get-MboxMessage -Path 'emails.mbox' -BodyHash SHA256 | 
  Select-Object Subject, BodyHash |
  Format-Table
```

Compute SHA256 hashes of message bodies for deduplication or integrity verification.

### Example 6: Pipeline from File System
```powershell
Get-ChildItem -Path 'C:\Backups' -Filter '*.mbox' | 
  Get-MboxMessage | 
  Group-Object -Property From | 
  Sort-Object -Property Count -Descending
```

Analyze which senders have the most messages across multiple MBOX files.

### Example 7: Find HTML Emails
```powershell
Get-MboxMessage -Path 'emails.mbox' | 
  Where-Object { $_.BodyHtml -ne $null } |
  Measure-Object | 
  Select-Object -ExpandProperty Count
```

Count messages that have HTML content.

### Example 8: Extract Attachments Information
```powershell
Get-MboxMessage -Path 'emails.mbox' | 
  Where-Object { $_.Attachments -ne $null } |
  ForEach-Object {
    [PSCustomObject]@{
      Subject = $_.Subject
      Date = $_.Date
      Attachments = $_.Attachments
    }
  }
```

List all messages with attachments.

### Example 9: Process Messages with ForEach
```powershell
Get-MboxMessage -Path 'emails.mbox' | ForEach-Object {
    $messageSize = $_.BodyText.Length + $_.BodyHtml.Length
    Write-Output "From: $($_.From)"
    Write-Output "Subject: $($_.Subject)"
    Write-Output "Size: $messageSize bytes"
    Write-Output "---"
}
```

Process each message with custom formatting.

### Example 10: Database Import
```powershell
$connection = New-Object System.Data.SqlClient.SqlConnection("Server=localhost;Database=Emails;Integrated Security=true;")
$connection.Open()

Get-MboxMessage -Path 'emails.mbox' -BodyHash SHA256 | ForEach-Object {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = "INSERT INTO Messages (MessageId, Subject, FromAddr, ToAddr, BodyHash, MessageDate) VALUES (@id, @subject, @from, @to, @hash, @date)"
    $cmd.Parameters.AddWithValue("@id", $_.MessageId ?? [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@subject", $_.Subject ?? [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@from", $_.From ?? [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@to", $_.To ?? [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@hash", $_.BodyHash ?? [DBNull]::Value) | Out-Null
    $cmd.Parameters.AddWithValue("@date", $_.Date) | Out-Null
    $cmd.ExecuteNonQuery()
}

$connection.Close()
```

Import MBOX messages into SQL Server database.

## MBOX File Format

MBOX is a simple text-based format where:
- Each message starts with a line beginning with "From " (space after From, not the header)
- The envelope sender is typically included after "From " with a timestamp
- Messages are separated only by these "From " delimiters
- Messages themselves are in standard RFC 822 email format

Example MBOX structure:
```
From sender@example.com Thu Jan 01 12:00:00 2026
From: Sender <sender@example.com>
To: Recipient <recipient@example.com>
Subject: First Message
Date: Thu, 01 Jan 2026 12:00:00 +0000

Message body goes here.

From another@example.com Thu Jan 01 13:00:00 2026
From: Another <another@example.com>
To: Recipient <recipient@example.com>
Subject: Second Message
Date: Thu, 01 Jan 2026 13:00:00 +0000

Another message body.
```

## Comparison with Get-MimeMessage

| Feature | Get-MimeMessage | Get-MboxMessage |
|---------|-----------------|-----------------|
| Input | Single .eml file | MBOX file (multiple messages) |
| Output | Single object | Multiple objects (streaming) |
| Message Count | 1 | N (depends on MBOX file) |
| Use Case | Process individual emails | Batch process mailbox exports |
| Pipeline Input | Yes (file path) | Yes (file path) |
| Memory Efficiency | High (single message) | High (streamed) |

## Performance Notes

- **Streaming**: Messages are yielded one-by-one, not loaded into memory all at once
- **Large Files**: Supports MBOX files of any size due to streaming architecture
- **Hash Computation**: Optional BodyHash parameter adds minimal overhead when used
- **Disk I/O**: File is read once; entire content is processed sequentially

## Common Patterns

### Pattern 1: Deduplicate by Subject
```powershell
Get-MboxMessage -Path 'emails.mbox' | 
  Group-Object -Property Subject | 
  Where-Object { $_.Count -gt 1 }
```

### Pattern 2: Find Recent Messages
```powershell
Get-MboxMessage -Path 'emails.mbox' | 
  Where-Object { $_.Date -gt (Get-Date).AddDays(-30) }
```

### Pattern 3: Validate Message Integrity
```powershell
Get-MboxMessage -Path 'emails.mbox' -BodyHash SHA256 | 
  Where-Object { $_.BodyHash -eq $null } |
  ForEach-Object { Write-Warning "Message missing body: $($_.Subject)" }
```

### Pattern 4: Migrate to JSON
```powershell
Get-MboxMessage -Path 'emails.mbox' -BodyHash SHA256 | 
  ConvertTo-Json | 
  Out-File -Path 'emails.json'
```

## Error Handling

```powershell
try {
    Get-MboxMessage -Path 'emails.mbox' | ForEach-Object {
        # Process message
    }
}
catch {
    Write-Error "Failed to process MBOX file: $($_.Exception.Message)"
}
```

## Related Cmdlets

- `Get-MimeMessage` - Process individual EML files
- `Send-Email` - Send emails using SMTP

## Notes

- Addresses are formatted as "Display Name <email@domain>"
- All dates are converted to UTC
- HTML and plain text bodies are preserved separately
- Message threading information is preserved in References and InReplyTo
- All header information is accessible via the Headers property

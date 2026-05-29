# Plan: Add `Get-MimeMessage` Cmdlet

## Overview
Add a `Get-MimeMessage` PowerShell cmdlet that loads an `.eml` file and returns all MIME message properties as a flat PowerShell object. An optional `-BodyHash` parameter appends a computed hash of the body content.

## Steps

### 1. C# — `EmailLibraryCore` (`src/EmailLibraryCore/EmailLibrary/EmailLibrary.cs`)
- Add `using System.Text;` and `using System.Security.Cryptography;`
- Add `public static Dictionary<string, object?> LoadMimeMessage(string filePath, string? bodyHash = null)` to `EmailCommands` class
- Add private helpers: `FormatInternetAddressList`, `FormatMailboxAddress`, `SerializeHeaders`, `CreateHasher`
- Method loads `MimeMessage.Load(filePath)`, extracts all properties, computes optional body hash, returns flat dictionary

### 2. C# — `EmailLibraryDesktop` (`src/EmailLibraryDesktop/EmailLibrary/EmailCommands.cs`)
- Same method and helpers as Core (add using statements for `System.Collections.Generic`, `System.Text`, `System.Security.Cryptography`)

### 3. PowerShell — `EmailModule.psm1`
- Add `Get-MimeMessage` function:
  - `-Path` (mandatory, pipeline-aware): EML file path
  - `-BodyHash` (optional): `[ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')]`
  - Calls `[EmailCommands]::LoadMimeMessage(path, bodyHash)`, outputs `[PSCustomObject]`
- Update `Export-ModuleMember` to include `Get-MimeMessage`

### 4. Banner — `EmailModule.Libraries.ps1`
- Update banner to list `Get-MimeMessage` alongside `Send-Email`

## Properties Returned

| Property | Type | Source |
|---|---|---|
| `MessageId` | `string?` | `msg.MessageId` |
| `Date` | `DateTime` | `msg.Date.UtcDateTime` |
| `Subject` | `string?` | `msg.Subject` |
| `From` | `string` | `InternetAddressList` formatted as `"Name" <email>` |
| `Sender` | `string?` | `MailboxAddress` formatted |
| `ReplyTo` | `string` | `InternetAddressList` formatted |
| `To` | `string` | Semicolon-separated address list |
| `Cc` | `string` | Semicolon-separated address list |
| `Bcc` | `string` | Semicolon-separated address list |
| `Priority` | `string` | `msg.Priority` enum |
| `Importance` | `string` | `msg.Importance` enum |
| `XPriority` | `string` | `msg.XPriority` enum |
| `InReplyTo` | `string?` | `msg.InReplyTo` |
| `References` | `string?` | `msg.References` |
| `MimeVersion` | `string?` | `msg.MimeVersion` |
| `ContentType` | `string?` | `msg.ContentType.MimeType` |
| `ContentTransferEncoding` | `string` | `msg.ContentTransferEncoding` |
| `BodyText` | `string?` | `msg.TextBody` (plain text) |
| `BodyHtml` | `string?` | `msg.HtmlBody` |
| `Attachments` | `string?` | Semicolon-separated filenames |
| `Headers` | `string` | All headers as JSON string |
| `BodyHash` | `string?` | Only when `-BodyHash` is used. Format: `BodyHtml=<HASHTYPE>=<hash>` or `BodyText=<HASHTYPE>=<hash>` |

## Usage

```powershell
# Load an EML file
$msg = Get-MimeMessage -Path 'email.eml'

# Load with body hash
$msg = Get-MimeMessage -Path 'email.eml' -BodyHash SHA256

# Pipeline
Get-ChildItem *.eml | Get-MimeMessage | Export-Csv emails.csv -NoTypeInformation

# Pipeline with hash
Get-ChildItem *.eml | Get-MimeMessage -BodyHash SHA256 | ForEach-Object {
    # Insert into DB
}
```

. $PSScriptRoot\EmailModule.Libraries.ps1
# $IsInteractive = -not ([Environment]::GetEnvironmentVariable("CI")) -and $null -ne $host.UI.RawUI
function Send-Email {
    [CmdletBinding(HelpUri = 'https://github.com/Brandon-J-Navarro/Powershell_Email-Module')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [string]
        # Specifies the username used to authenticate to the SMTP server.
        # This is typically the sender's email address (EmailFrom).
        $AuthUser,

        [Parameter(Mandatory = $true, ParameterSetName = 'UserPass')]
        [object]
        # Specifies the password used to authenticate to the SMTP server.
        # Accepts Plain Text of type 'System.String' or Secure Strings of type 'System.Security.SecureString'
        # Consider using secure option such as: ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force
        $AuthPass,

        [Parameter(Mandatory = $true, ParameterSetName = 'PSCredential')]
        [PSCredential]
        # Specifies the PSCredential object containing the username and password for SMTP authentication.
        # This is an alternative to using AuthUser and AuthPass parameters separately.
        # Create using: Get-Credential or New-Object System.Management.Automation.PSCredential
        $Credential,

        [Parameter(Mandatory = $true)]
        [string]
        # Specifies the recipient's email address(es). Multiple recipients can be separated by semicolons (;).
        # Examples: "user@example.com" or "user1@example.com;user2@example.com;user3@example.com"
        $EmailTo,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        # Specifies the display name(s) of the recipients separated by semicolons (;).
        # Should correspond to EmailTo parameter. If the number of names does not match the number of email addresses,
        # or if not provided, the email addresses will be used as display names.
        # Examples: "John Doe" or "John Doe;Jane Smith;Bob Wilson"
        $EmailToName = $null,

        [Parameter(Mandatory = $true)]
        [string]
        # Specifies the sender's email address.
        # Example: "noreply@company.com"
        $EmailFrom,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        # Specifies the display name of the sender. If not provided, email address will be used.
        # Example: "Company Notifications" or "IT Department"
        $EmailFromName = $null,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        # Specifies the subject line of the email.
        # Example: "System Alert" or "Weekly Report"
        $Subject = $null,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        # Specifies the body content of the email message.
        # The message is sent as plain text.
        # Example: "This is a test message from the automation system."
        $Body = $null,

        [Parameter(Mandatory = $true)]
        [string]
        # Specifies the hostname or fully qualified domain name (FQDN) of the SMTP server to connect to.
        # Examples: "smtp.gmail.com", "mail.company.com", "smtp.office365.com"
        $SmtpServer,

        [int]
        # Specifies the TCP port number used for the SMTP connection. The default is 587.
        # Supports any port that supports STARTTLS encryption for secure email transmission.
        # Common ports: 25 (may support STARTTLS), 587 (STARTTLS standard), 465 (legacy SSL, if STARTTLS available)
        $SmtpPort = 587,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]
        # Specifies additional recipients to include in the Carbon Copy (CC) field.
        # Multiple recipients can be separated by semicolons (;).
        # Examples: "manager@company.com" or "manager@company.com;supervisor@company.com"
        $EmailCc,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]
        # Specifies the display names for the CC recipients separated by semicolons (;).
        # Should correspond to the EmailCc parameter. If the number of names does not match the number of email addresses,
        # or if not provided, the email addresses will be used as display names.
        # Examples: "Manager Name" or "Manager Name;Supervisor Name"
        $CcName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]
        # Specifies additional recipients to include in the Blind Carbon Copy (BCC) field.
        # Multiple recipients can be separated by semicolons (;).
        # Examples: "audit@company.com" or "audit@company.com;backup@company.com"
        $EmailBcc,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]
        # Specifies the display names for the BCC recipients separated by semicolons (;).
        # Should correspond to the EmailBcc parameter. If the number of names does not match the number of email addresses,
        # or if not provided, the email addresses will be used as display names.
        # Examples: "Audit Team" or "Audit Team;Backup Admin"
        $BccName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]
        # Specifies the file path to an attachment to include with the email.
        # Only a single attachment is supported. File must exist and be accessible.
        # Examples: "C:\Reports\monthly_report.pdf" or "\\server\share\document.xlsx"
        $EmailAttachment,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet("NonUrgent","Normal","Urgent",IgnoreCase = $true)]
        # Specifies the priority level of the email message. The default is Normal.
        # Valid values are "NonUrgent", "Normal", or "Urgent" (case-insensitive).
        $EmailPriority = "Normal",

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet("Low","Normal","High",IgnoreCase = $true)]
        # Specifies the importance level of the email message. The default is Normal.
        # Valid values are "Low", "Normal", or "High" (case-insensitive).
        $EmailImportance = "Normal"
    )

    if ($PSCmdlet.ParameterSetName -EQ 'PSCredential') {
        $AuthUser = $Credential.UserName
        $AuthPass = $Credential.Password
    }

    if ($EmailPriority) {
        $cultureInfo = (Get-Culture).TextInfo
        $EmailPriority = $cultureInfo.ToTitleCase($EmailPriority.ToLower())
    }

    if ($EmailImportance) {
        $cultureInfo = (Get-Culture).TextInfo
        $EmailImportance = $cultureInfo.ToTitleCase($EmailImportance.ToLower())
    }


    if ($AuthUser.ToLower() -ne $EmailFrom.ToLower()) {
        Write-Warning "The authenticated user ($AuthUser) and the sending email address ($EmailFrom) do not match."
        Write-Warning "Please verify that the authenticated user has 'Send on behalf of' or 'Send As' permissions for the specified email address."
    }

    $EmailFromDomain = ($EmailFrom.Split('@'))[1]
    if ( ! ( $SmtpServer.ToLower().Contains($EmailFromDomain.ToLower()) ) ) {
        Write-Warning "Email From domain ($EmailFromDomain) does not match the SMTP Server domain ($SmtpServer)."
        Write-Warning "This can lead to Sender Policy Framework (SPF) failures, DomainKeys Identified Mail (DKIM) failures, and Domain-based Message Authentication, Reporting, and Conformance (DMARC) rejections, causing your email to be marked as spam, denied by the recipient, or fail to send even though the SMTP connection succeeded."
        Write-Warning "Please verify that the sending domain is authorized to send through the specified SMTP server without being flagged or rejected."
        # if ($IsInteractive) {
        #     $No = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'No'
        #     $Yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Yes'
        #     $Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
        #     $choice = $host.ui.PromptForChoice("Do you wish to continue?", "", $Options, 0)
        #     if ($choice -eq 0) {              # $AuthUser = 'user@company.com'
        #         Write-Output "Exiting..."     # $EmailFrom = 'user@business.com'
        #         Start-Sleep -Seconds 1        # $SmtpServer = 'mail.corporation.com'
        #         return $null
        #     }
        # }
    }

    [EmailCommands]::SendEmail(
        [string]$AuthUser,
        [object]$AuthPass,
        [string]$EmailTo,
        [string]$EmailToName,
        [string]$EmailFrom,
        [string]$EmailFromName,
        [string]$Subject,
        [string]$Body,
        [string]$SmtpServer,
        [int]$SmtpPort,
        [string]$EmailCc,
        [string]$CcName,
        [string]$EmailBcc,
        [string]$BccName,
        [string]$EmailAttachment,
        [string]$EmailPriority,
        [string]$EmailImportance
    )

    <#
    .SYNOPSIS
    Sends an email message through an SMTP server with authentication using a compiled .NET email handler.

    .DESCRIPTION
    The Send-Email function provides an interface for sending email messages through SMTP using
    a .NET assembly that leverages the MimeKit and MailKit libraries. The underlying .NET class
    `EmailCommands` (defined in the module's EmailLibrary.dll) handles message creation,
    authentication, and secure transmission using STARTTLS.

    The Send-Email function provides a simple way to send email messages from PowerShell scripts.
    It supports SMTP authentication using username/password or PSCredential objects, and allows you to specify
    the sender, recipients (To/CC/BCC), subject, body, attachments, and message priority/importance.

    The supporting script `EmailModule.Libraries.ps1` dynamically loads the correct set of .NET assemblies
    depending on the current PowerShell edition:

    - When running on `PowerShell Core`, assemblies are loaded from:
        .\lib\net8.0\
    - When running on `Windows PowerShell (Desktop)`, assemblies are loaded from:
        .\lib\net472\

    This design ensures cross-platform compatibility and supports secure, authenticated email delivery
    from PowerShell scripts or automation environments.

    This PowerShell function serves as a wrapper that passes all user-supplied parameters to the
    EmailLibrary.dll assembly that contains the `EmailCommands` class and static method
    [EmailCommands]::SendEmail(), which constructs a MIME-compliant message and sends it
    using MailKit's SmtpClient class. The connection is secured with STARTTLS, and credentials are
    authenticated using the provided username and password.

    .INPUTS
    None.
    All input must be supplied through parameters.

    .OUTPUTS
    None.
    This function does not return an object. The result of execution is the successful transmission

    .NOTES
    Assembly information:
        - Primary assembly:  EmailLibrary.dll
        - Class:             EmailCommands
        - Namespace:         (global)
        - Dependencies:
            • MimeKit.dll
            • MailKit.dll
            • BouncyCastle.Cryptography.dll
            • System.Security.Cryptography.Pkcs.dll (Core only)
            • Additional .NET support libraries (Desktop only)
        - Encryption:        STARTTLS via MailKit.Security.SecureSocketOptions.StartTls
        - Auto-loader:       EmailModule.Libraries.ps1
        - Library paths:
            EmailModule\lib\net8.0\ → PowerShell Core
            EmailModule\lib\net472\ → Windows PowerShell Desktop

    All assemblies are automatically imported when the module is loaded.
    If a DLL fails to load, a warning will be displayed.

    The function relies on a .NET class implemented in C#, defined as:
    public static class EmailCommands
    {
        public static void SendEmail(...) { ... }
    }

    This class uses:
        - MimeKit for constructing MIME messages.
        - MailKit.Net.Smtp.SmtpClient for sending messages securely.
        - SecureSocketOptions.StartTls for encryption.

    Both MimeKit and MailKit must be available in the environment or included within the module's DLL.

    .EXAMPLE
    # Basic email with username/password authentication

    Send-Email -AuthUser "sender@company.com" -AuthPass "password123" `
            -EmailTo "recipient@company.com" -EmailFrom "sender@company.com" `
            -Subject "Test Email" -Body "This is a test message." `
            -SmtpServer "smtp.company.com" -SmtpPort 587

    .EXAMPLE
    # Email with display names for sender and recipient

    Send-Email -AuthUser "noreply@company.com" -AuthPass "securepassword" `
            -EmailTo "john.doe@company.com" -EmailToName "John Doe" `
            -EmailFrom "noreply@company.com" -EmailFromName "IT Department" `
            -Subject "System Maintenance Notice" `
            -Body "Scheduled maintenance will occur this weekend." `
            -SmtpServer "mail.company.com"

    .EXAMPLE
    # Multiple recipients with semicolon separation

    Send-Email -AuthUser "alerts@company.com" -AuthPass "alertpass" `
            -EmailTo "admin1@company.com;admin2@company.com;admin3@company.com" `
            -EmailToName "Admin One;Admin Two;Admin Three" `
            -EmailFrom "alerts@company.com" -EmailFromName "System Alerts" `
            -Subject "Server Alert" -Body "Server CPU usage is high." `
            -SmtpServer "smtp.company.com"

    .EXAMPLE
    # Email with CC and BCC recipients

    Send-Email -AuthUser "reports@company.com" -AuthPass "reportpass" `
            -EmailTo "manager@company.com" -EmailToName "Department Manager" `
            -EmailCc "supervisor@company.com" -CcName "Supervisor" `
            -EmailBcc "audit@company.com" -BccName "Audit Team" `
            -EmailFrom "reports@company.com" -EmailFromName "Reporting System" `
            -Subject "Monthly Report" -Body "Please find the monthly report attached." `
            -EmailAttachment "C:\Reports\monthly_report.pdf" `
            -SmtpServer "smtp.company.com"

    .EXAMPLE
    # Using PSCredential for authentication

    $cred = Get-Credential -UserName "service@company.com"
    Send-Email -Credential $cred `
            -EmailTo "support@company.com" `
            -EmailFrom "service@company.com" `
            -Subject "Service Status" -Body "All services are running normally." `
            -SmtpServer "smtp.company.com"

    .EXAMPLE
    # Using SecureString for password

    $securePass = ConvertTo-SecureString "mypassword" -AsPlainText -Force
    Send-Email -AuthUser "automation@company.com" -AuthPass $securePass `
            -EmailTo "admin@company.com" `
            -EmailFrom "automation@company.com" `
            -Subject "Backup Complete" -Body "Daily backup completed successfully." `
            -SmtpServer "smtp.company.com"

    .EXAMPLE
    # Email with priority and importance settings

    Send-Email -AuthUser "critical@company.com" -AuthPass "criticalpass" `
            -EmailTo "oncall@company.com" `
            -EmailFrom "critical@company.com" `
            -Subject "URGENT: System Down" -Body "Primary server is not responding." `
            -SmtpServer "smtp.company.com" `
            -EmailPriority "Urgent" -EmailImportance "High"

    .EXAMPLE
    # Using variables for reusable configuration

    $mailConfig = @{
        AuthUser = "notifications@company.com"
        AuthPass = "notifypass"
        EmailFrom = "notifications@company.com"
        EmailFromName = "Company Notifications"
        SmtpServer = "smtp.company.com"
        SmtpPort = 587
    }

    Send-Email @mailConfig `
            -EmailTo "team@company.com" `
            -Subject "Weekly Update" `
            -Body "This week's summary is attached." `
            -EmailAttachment "C:\Reports\weekly_summary.xlsx"

    .EXAMPLE
    # Office 365/Outlook.com configuration

    Send-Email -AuthUser "user@outlook.com" -AuthPass "apppassword" `
            -EmailTo "recipient@domain.com" `
            -EmailFrom "user@outlook.com" `
            -Subject "Test from Office 365" `
            -Body "Testing email via Office 365 SMTP." `
            -SmtpServer "smtp-mail.outlook.com" -SmtpPort 587

    .EXAMPLE
    # Gmail configuration (requires app password)

    Send-Email -AuthUser "user@gmail.com" -AuthPass "apppassword" `
            -EmailTo "recipient@domain.com" `
            -EmailFrom "user@gmail.com" `
            -Subject "Test from Gmail" `
            -Body "Testing email via Gmail SMTP." `
            -SmtpServer "smtp.gmail.com" -SmtpPort 587

    .EXAMPLE
    # Error handling with try-catch

    try {
        Send-Email -AuthUser "sender@company.com" -AuthPass "password" `
                -EmailTo "recipient@company.com" `
                -EmailFrom "sender@company.com" `
                -Subject "Test Email" -Body "Test message" `
                -SmtpServer "smtp.company.com"
        Write-Output "Email sent successfully!"
    catch {
        Write-Error "Failed to send email: $($_.Exception.Message)"
    }

    .EXAMPLE
    # Mismatched names example (names will be stripped, emails used as display names)

    # This will work - emails will be used as display names since count doesn't match
    Send-Email -AuthUser "sender@company.com" -AuthPass "password" `
            -EmailTo "user1@company.com;user2@company.com;user3@company.com" `
            -EmailToName "User One;User Two" `
            -EmailFrom "sender@company.com" `
            -Subject "Name Mismatch Example" `
            -Body "Only first two names provided, all emails will use addresses as display names." `
            -SmtpServer "smtp.company.com"

    .LINK
    Source Code: https://github.com/Brandon-J-Navarro/Powershell_Email-Module

    .LINK
    PSGallery: https://www.powershellgallery.com/packages/EmailModule/

    .LINK
    MimeKit: https://github.com/jstedfast/MimeKit

    .LINK
    MailKit: https://github.com/jstedfast/MailKit
    #>
}

function Get-MimeMessage {
    [CmdletBinding(HelpUri = 'https://github.com/Brandon-J-Navarro/Powershell_Email-Module')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_})]
        [string]
        # Specifies the path to the .eml file to load.
        $Path,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512', IgnoreCase = $true)]
        [string]
        # Specifies the hash algorithm to compute a body hash.
        # The hash is computed against BodyHtml if present, otherwise BodyText.
        # The value is appended as: BodyHtml=<HashType>=<hash> or BodyText=<HashType>=<hash>
        $BodyHash
    )

    [PSCustomObject][EmailCommands]::LoadMimeMessage((Resolve-Path -Path $Path | Select-Object -ExpandProperty Path), $BodyHash)

    <#
    .SYNOPSIS
    Loads an EML file and returns all MIME message properties as a PowerShell object.

    .DESCRIPTION
    The Get-MimeMessage function loads a .eml file using the MimeKit library and returns
    all relevant properties as a flat [PSCustomObject]. Properties include MessageId, Date,
    Subject, From, To, Cc, Bcc, ReplyTo, Sender, Priority, Importance, body content (plain
    text and HTML), attachments, headers (as JSON), and more.

    An optional -BodyHash parameter computes a hash of the body content (BodyHtml if present,
    otherwise BodyText) and adds a BodyHash property with the format:
        BodyHtml=<HashType>=<hex_hash>  or  BodyText=<HashType>=<hex_hash>

    Supported hash algorithms: MD5, SHA1, SHA256, SHA384, SHA512

    .INPUTS
    System.String
    You can pipe a file path to Get-MimeMessage.

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Get-MimeMessage returns a custom object with properties from the parsed EML file.

    .EXAMPLE
    # Basic usage
    Get-MimeMessage -Path 'email.eml'

    .EXAMPLE
    # With body hash
    Get-MimeMessage -Path 'email.eml' -BodyHash SHA256

    .EXAMPLE
    # Pipeline
    Get-ChildItem *.eml | Get-MimeMessage | Export-Csv emails.csv -NoTypeInformation

    .EXAMPLE
    # Pipeline with body hash
    Get-ChildItem *.eml | Get-MimeMessage -BodyHash SHA256 | ForEach-Object {
        Write-Output "Subject: $($_.Subject)"
        Write-Output "BodyHash: $($_.BodyHash)"
    }

    .LINK
    Source Code: https://github.com/Brandon-J-Navarro/Powershell_Email-Module
    #>
}

function Get-MboxMessage {
    [CmdletBinding(HelpUri = 'https://github.com/Brandon-J-Navarro/Powershell_Email-Module')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_})]
        [string]
        # Specifies the path to the .mbox file to load.
        $Path,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512', IgnoreCase = $true)]
        [string]
        # Specifies the hash algorithm to compute a body hash.
        # The hash is computed against BodyHtml if present, otherwise BodyText.
        # The value is appended as: BodyHtml=<HashType>=<hash> or BodyText=<HashType>=<hash>
        $BodyHash
    )

    $resolvedPath = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
    $messages = [EmailCommands]::LoadMboxMessages($resolvedPath, $BodyHash)
    
    foreach ($msg in $messages) {
        [PSCustomObject]$msg
    }

    <#
    .SYNOPSIS
    Reads messages from an MBOX file and streams them as PowerShell objects.

    .DESCRIPTION
    The Get-MboxMessage function reads an MBOX file (a text file containing one or more
    email messages) and parses each message using the MimeKit library. Messages are streamed
    one at a time as [PSCustomObject] with properties including MessageId, Date, Subject,
    From, To, Cc, Bcc, ReplyTo, Sender, Priority, Importance, body content, attachments,
    headers, and more.

    MBOX format separates messages with a line starting with "From " (space after From,
    not the "From:" header). Each message is RFC 822 compliant email format.

    An optional -BodyHash parameter computes a hash of the body content (BodyHtml if present,
    otherwise BodyText) and adds a BodyHash property with the format:
        BodyHtml=<HashType>=<hex_hash>  or  BodyText=<HashType>=<hex_hash>

    Supported hash algorithms: MD5, SHA1, SHA256, SHA384, SHA512

    .INPUTS
    System.String
    You can pipe a file path to Get-MboxMessage.

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Get-MboxMessage returns multiple custom objects (one per message), each with properties
    from the parsed email message.

    .EXAMPLE
    # Basic usage - stream all messages from MBOX file
    Get-MboxMessage -Path 'emails.mbox'

    .EXAMPLE
    # With body hash
    Get-MboxMessage -Path 'emails.mbox' -BodyHash SHA256

    .EXAMPLE
    # Process each message with ForEach-Object
    Get-MboxMessage -Path 'emails.mbox' | ForEach-Object {
        Write-Output "From: $($_.From) Subject: $($_.Subject)"
    }

    .EXAMPLE
    # Export all messages to CSV
    Get-MboxMessage -Path 'emails.mbox' | Export-Csv messages.csv -NoTypeInformation

    .EXAMPLE
    # Pipe to Get-MimeMessage for additional processing (if needed)
    Get-MboxMessage -Path 'emails.mbox' | ForEach-Object {
        Write-Output "Processing: $($_.Subject)"
    }

    .EXAMPLE
    # Count total messages in MBOX file
    (Get-MboxMessage -Path 'emails.mbox' | Measure-Object).Count

    .EXAMPLE
    # Find messages from specific sender
    Get-MboxMessage -Path 'emails.mbox' | Where-Object { $_.From -like '*@example.com' }

    .LINK
    Source Code: https://github.com/Brandon-J-Navarro/Powershell_Email-Module

    .LINK
    Get-MimeMessage: https://github.com/Brandon-J-Navarro/Powershell_Email-Module
    #>
}

Export-ModuleMember Send-Email, Get-MimeMessage, Get-MboxMessage


# Show banner after module is imported (optional)
# if ($IsInteractive) {
Get-Banner
# }

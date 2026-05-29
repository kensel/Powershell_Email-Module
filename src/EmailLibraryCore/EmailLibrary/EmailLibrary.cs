// EmailLibrary.cs dotNET Core 8.0
using MailKit.Security;
using Microsoft.AspNetCore.StaticFiles;
using MimeKit;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using static EmailLibrary.Builders;

public class EmailCommands
{
    public static object SendEmail(
        string authUser, object authPass,
        string emailTo, string? toName,
        string emailFrom, string? fromName,
        string? emailSubject, string? emailBody,
        string mailServer, int serverPort,
        string? emailCc, string? ccName,
        string? emailBcc, string? bccName,
        string? emailAttachment, string? emailPriority,
        string? emailImportance)
    {
#if DEBUG
        Console.WriteLine("[DEBUG] Starting SendEmail...");
#endif

        NetworkCredential credentials = CreateAuthCreds(authUser, authPass);
#if DEBUG
        Console.WriteLine("[DEBUG] Credentials created successfully.");
#endif

        var mailMessage = new MimeMessage();
#if DEBUG
        Console.WriteLine("[DEBUG] Creating Mail Message...");
#endif

        mailMessage = BuildMailMessage(mailMessage, emailFrom, fromName, "FROM");
#if DEBUG
        Console.WriteLine("[DEBUG] Successfully added FROM.");
#endif

        mailMessage = BuildMailMessage(mailMessage, emailTo, toName,"TO");
#if DEBUG
        Console.WriteLine("[DEBUG] Successfully added TO recipients.");
#endif

        if (!(string.IsNullOrEmpty(emailCc)))
        {
            mailMessage = BuildMailMessage(mailMessage, emailCc, ccName, "CC");
#if DEBUG
            Console.WriteLine("[DEBUG] Successfully added CC recipients.");
#endif
        }
        else
        {
#if DEBUG
            Console.WriteLine("[DEBUG] No CC Added.");
#endif
        }

        if (!(string.IsNullOrEmpty(emailBcc)))
        {
            mailMessage = BuildMailMessage(mailMessage, emailBcc, bccName, "BCC");
#if DEBUG
            Console.WriteLine("[DEBUG] Successfully added BCC recipients.");
#endif
        }
        else
        {
#if DEBUG
            Console.WriteLine("[DEBUG] No BCC Added.");
#endif
        }

        if (!(string.IsNullOrEmpty(emailPriority)))
        {
            mailMessage.Priority = (MessagePriority)System.Enum.Parse(typeof(MessagePriority), emailPriority);
#if DEBUG

            Console.WriteLine($"[DEBUG] Email PRIORITY set to: {emailPriority}");
#endif
        }
        else
        {
#if DEBUG
            Console.WriteLine("[DEBUG] No PRIORITY set.");
#endif
        }

        if (!(string.IsNullOrEmpty(emailImportance)))
        {
            mailMessage.Importance = (MessageImportance)System.Enum.Parse(typeof(MessageImportance), emailImportance);
#if DEBUG
            Console.WriteLine($"[DEBUG] Email IMPORTANCE set to: {emailImportance}");
#endif
        }
        else
        {
#if DEBUG
            Console.WriteLine("[DEBUG] No IMPORTANCE set.");
#endif
        }

        if (!(string.IsNullOrEmpty(emailSubject)))
        {
            mailMessage.Subject = emailSubject;
#if DEBUG
            Console.WriteLine($"[DEBUG] SUBJECT Added: {emailSubject}");
#endif
        }
        else
        {
            mailMessage.Subject = string.Empty;
#if DEBUG
            Console.WriteLine("[DEBUG] No SUBJECT Added, set to string.Empty.");
#endif
        }

        if (!(string.IsNullOrEmpty(emailAttachment)))
        {
#if DEBUG
            Console.WriteLine($"[DEBUG] Attachment found: {emailAttachment} (currently not attached in this version)");
#endif
            var body = new TextPart("plain")
            {
                Text = emailBody ?? string.Empty
            };

            var multipart = new Multipart("mixed");
            multipart.Add(body);
#if DEBUG
            Console.WriteLine("[DEBUG] Created multipart container and added email body.");
#endif

            if (!string.IsNullOrEmpty(emailAttachment) && File.Exists(emailAttachment))
            {
#if DEBUG
                Console.WriteLine($"[DEBUG] Attachment file exists at path: {emailAttachment}");
#endif
                const string DefaultContentType = "application/octet-stream";
                var provider = new FileExtensionContentTypeProvider();

                if (!provider.TryGetContentType(emailAttachment, out string contentType))
                {
#if DEBUG
                    Console.WriteLine($"[DEBUG] Could not determine MIME type for '{emailAttachment}'. Defaulting to '{DefaultContentType}'.");
#endif
                    contentType = DefaultContentType;
                }
                else
                {
#if DEBUG
                    Console.WriteLine($"[DEBUG] Determined MIME type for '{emailAttachment}': {contentType}");
#endif
                }

                var stream = File.OpenRead(emailAttachment);
#if DEBUG
                Console.WriteLine($"[DEBUG] Opened file stream for attachment: {emailAttachment}");
#endif

                var attachment = new MimePart(contentType)
                {
                    Content = new MimeContent(stream, ContentEncoding.Default),
                    ContentDisposition = new ContentDisposition(ContentDisposition.Attachment),
                    ContentTransferEncoding = ContentEncoding.Base64,
                    FileName = Path.GetFileName(emailAttachment)
                };
#if DEBUG
                Console.WriteLine($"[DEBUG] Created MimePart for attachment: {attachment.FileName}");
#endif

                multipart.Add(attachment);
#if DEBUG
                Console.WriteLine("[DEBUG] Added attachment to multipart message.");
#endif
            }
            else
            {
#if DEBUG
                Console.WriteLine($"[DEBUG] Attachment file not found at path: {emailAttachment}");
#endif
            }
            mailMessage.Body = multipart;
#if DEBUG
            Console.WriteLine("[DEBUG] Set multipart message (body + attachments) as email body.");
#endif

            if (!(string.IsNullOrEmpty(emailBody)))
            {
#if DEBUG
                Console.WriteLine($"[DEBUG] BODY Added: {emailBody}");
#endif
            }
            else
            {
#if DEBUG
                Console.WriteLine("[DEBUG] No BODY Added, set to string.Empty.");
#endif
            }
        }
        else
        {
            mailMessage.Body = new TextPart("plain")
            {
                Text = emailBody ?? string.Empty
            };
            if (!(string.IsNullOrEmpty(emailBody)))
            {
#if DEBUG
                Console.WriteLine($"[DEBUG] BODY Added: {emailBody}");
#endif
            }
            else
            {
#if DEBUG
                Console.WriteLine("[DEBUG] No BODY Added, set to string.Empty.");
#endif
            }
        }


#if DEBUG
        Console.WriteLine("[DEBUG] Email composed successfully.");
        Console.WriteLine("[DEBUG] Mail Message contents.");
        Console.WriteLine($"[DEBUG] {mailMessage}");
#endif

        using var smtpClient = new MailKit.Net.Smtp.SmtpClient();
#if DEBUG
        Console.WriteLine("[DEBUG] Connecting to SMTP server...");
#endif

#if DEBUG
        Console.WriteLine($"[DEBUG] MailServer: {mailServer}:{serverPort}");
#endif

        if (Environment.GetEnvironmentVariable("CI") == "true" && RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
        {
            smtpClient.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) =>
            {
#if DEBUG
                Console.WriteLine("[DEBUG] macOS CI detected – bypassing partial revocation SSL errors.");
#endif
                if (sslPolicyErrors == System.Net.Security.SslPolicyErrors.RemoteCertificateChainErrors &&
                    chain?.ChainStatus?.Any(s => s.Status == System.Security.Cryptography.X509Certificates.X509ChainStatusFlags.RevocationStatusUnknown) == true)
                {
                    return true;
                }

                return sslPolicyErrors == System.Net.Security.SslPolicyErrors.None;
            };
        }

        smtpClient.Connect(mailServer, serverPort, SecureSocketOptions.StartTls);
#if DEBUG
        Console.WriteLine("[DEBUG] Connected to SMTP server.");
        Console.WriteLine($"[DEBUG] Is Connected: {smtpClient.IsConnected}");
        Console.WriteLine($"[DEBUG] Is Encrypted: {smtpClient.IsEncrypted}");
        Console.WriteLine($"[DEBUG] Is Secure: {smtpClient.IsSecure}");
        Console.WriteLine($"[DEBUG] Ssl Cipher Algorithm: {smtpClient.SslCipherAlgorithm}");
        Console.WriteLine($"[DEBUG] Ssl Cipher Suite: {smtpClient.SslCipherSuite}");
        Console.WriteLine($"[DEBUG] Ssl Hash Algorithm: {smtpClient.SslHashAlgorithm}");
        Console.WriteLine($"[DEBUG] Ssl Protocol: {smtpClient.SslProtocol}");
#endif

        smtpClient.Authenticate(credentials);
#if DEBUG
        Console.WriteLine("[DEBUG] Authenticated successfully.");
        Console.WriteLine($"[DEBUG] Is Authenticated: {smtpClient.IsAuthenticated}");
#endif

        var mailSent = smtpClient.Send(mailMessage);
#if DEBUG
        Console.WriteLine("[DEBUG] Email sent successfully.");
        Console.WriteLine($"[DEBUG] {mailSent}");
#endif

        smtpClient.Disconnect(true);
#if DEBUG
            Console.WriteLine("[DEBUG] SMTP client disconnected.");
#endif
        return mailSent;
    }

    public static Dictionary<string, object?> LoadMimeMessage(string filePath, string? bodyHash = null)
    {
        if (!File.Exists(filePath))
            throw new FileNotFoundException($"EML file not found: {filePath}", filePath);

        var msg = MimeMessage.Load(filePath);
        var result = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);

        result["MessageId"] = msg.MessageId;
        result["Date"] = msg.Date.UtcDateTime;
        result["Subject"] = msg.Subject;

        result["From"] = FormatInternetAddressList(msg.From);
        result["Sender"] = msg.Sender != null ? FormatMailboxAddress(msg.Sender) : null;
        result["ReplyTo"] = FormatInternetAddressList(msg.ReplyTo);
        result["To"] = FormatInternetAddressList(msg.To);
        result["Cc"] = FormatInternetAddressList(msg.Cc);
        result["Bcc"] = FormatInternetAddressList(msg.Bcc);

        result["Priority"] = msg.Priority.ToString();
        result["Importance"] = msg.Importance.ToString();
        result["XPriority"] = msg.XPriority.ToString();

        result["InReplyTo"] = msg.InReplyTo;
        result["References"] = msg.References;

        result["MimeVersion"] = msg.MimeVersion?.ToString();
        result["ContentType"] = msg.Body?.ContentType?.MimeType;
        result["ContentTransferEncoding"] = msg.Body is MimePart mp ? mp.ContentTransferEncoding.ToString() : null;

        result["BodyText"] = msg.TextBody;
        result["BodyHtml"] = msg.HtmlBody;

        var attachmentNames = new List<string>();
        foreach (var attachment in msg.Attachments)
        {
            if (attachment is MimePart part && !string.IsNullOrEmpty(part.FileName))
                attachmentNames.Add(part.FileName);
        }
        result["Attachments"] = attachmentNames.Count > 0 ? string.Join("; ", attachmentNames) : null;

        result["Headers"] = SerializeHeaders(msg.Headers);

        if (!string.IsNullOrEmpty(bodyHash))
        {
            var bodyContent = !string.IsNullOrEmpty(msg.HtmlBody) ? msg.HtmlBody : msg.TextBody;
            if (bodyContent != null)
            {
                using var hasher = CreateHasher(bodyHash);
                if (hasher != null)
                {
                    var hashBytes = hasher.ComputeHash(Encoding.UTF8.GetBytes(bodyContent));
                    var hashString = BitConverter.ToString(hashBytes).Replace("-", "").ToLowerInvariant();
                    var prefix = !string.IsNullOrEmpty(msg.HtmlBody) ? "BodyHtml" : "BodyText";
                    result["BodyHash"] = $"{prefix}={bodyHash.ToUpperInvariant()}={hashString}";
                }
            }
        }

        return result;
    }

    private static string FormatInternetAddressList(InternetAddressList list)
    {
        if (list == null || list.Count == 0) return string.Empty;
        var parts = new List<string>(list.Count);
        foreach (var addr in list)
        {
            parts.Add(addr is MailboxAddress mailbox ? FormatMailboxAddress(mailbox) : addr.ToString());
        }
        return string.Join("; ", parts);
    }

    private static string FormatMailboxAddress(MailboxAddress addr)
    {
        return string.IsNullOrEmpty(addr.Name) ? addr.Address : $"{addr.Name} <{addr.Address}>";
    }

    private static string SerializeHeaders(HeaderList headers)
    {
        if (headers == null || headers.Count == 0) return "{}";
        var sb = new StringBuilder();
        sb.Append('{');
        bool first = true;
        foreach (var header in headers)
        {
            if (!first) sb.Append(", ");
            first = false;
            sb.Append('"');
            sb.Append(EscapeJson(header.Field));
            sb.Append("\": \"");
            sb.Append(EscapeJson(header.Value));
            sb.Append('"');
        }
        sb.Append('}');
        return sb.ToString();
    }

    private static HashAlgorithm? CreateHasher(string? hashName)
    {
        if (string.IsNullOrEmpty(hashName)) return null;
        return hashName.ToUpperInvariant() switch
        {
            "MD5" => MD5.Create(),
            "SHA1" => SHA1.Create(),
            "SHA256" => SHA256.Create(),
            "SHA384" => SHA384.Create(),
            "SHA512" => SHA512.Create(),
            _ => null,
        };
    }

    private static string EscapeJson(string s)
    {
        return s.Replace("\\", "\\\\")
                .Replace("\"", "\\\"")
                .Replace("\n", "\\n")
                .Replace("\r", "\\r")
                .Replace("\t", "\\t");
    }
}

Import-Module /module/EmailModule.psm1 -Force
Get-Command -Module EmailModule | Format-Table Name, CommandType
Write-Output ""
Get-MimeMessage -Path /tmp/test.eml | Format-List Subject, From, To, Date, BodyHash

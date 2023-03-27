<#
.Synopsis
   Script to Automated Email Reminders when Users Passwords due to Expire.
.DESCRIPTION
   Script to Automated Email Reminders when Users Passwords due to Expire.
   Robert Pearman / WindowsServerEssentials.com
   Version 2.9 August 2018
   Requires: Windows PowerShell Module for Active Directory
   For assistance and ideas, visit the TechNet Gallery Q&A Page. http://gallery.technet.microsoft.com/Password-Expiry-Email-177c3e27/view/Discussions#content

   Alternativley visit my youtube channel, https://www.youtube.com/robtitlerequired

   Videos are available to cover most questions, some videos are based on the earlier version which used static variables, however most of the code
   can still be applied to this version, for example for targeting groups, or email design.

   Please take a look at the existing Q&A as many questions are simply repeating earlier ones, with the same answers!


.EXAMPLE
  PasswordChangeNotification.ps1 -smtpServer mail.domain.com -expireInDays 21 -from "IT Support <support@domain.com>" -Logging -LogPath "c:\logFiles" -testing -testRecipient support@domain.com
  
  This example will use mail.domain.com as an smtp server, notify users whose password expires in less than 21 days, send mail from support@domain.com
  Logging is enabled, log path is c:\logfiles
  Testing is enabled, and test recipient is support@domain.com

.EXAMPLE
  PasswordChangeNotification.ps1 -smtpServer mail.domain.com -expireInDays 21 -from "IT Support <support@domain.com>" -reportTo myaddress@domain.com -interval 1,2,5,10,15
  
  This example will use mail.domain.com as an smtp server, notify users whose password expires in less than 21 days, send mail from support@domain.com
  Report is enabled, reports sent to myaddress@domain.com
  Interval is used, and emails will be sent to people whose password expires in less than 21 days if the script is run, with 15, 10, 5, 2 or 1 days remaining untill password expires.

.NOTES
  Modified by: Alejandro Aguado García
  Github:   https://github.com/Iber1to

  Modified to work with ModernAuthentication with delegated permisions.

#>
param(
    
   
    # Notify Users if Expiry Less than X Days
    [Parameter(Mandatory=$True)]
    [ValidateNotNull()]
    [int]$expireInDays,    # From Address, eg "IT Support <support@domain.com>"
    [switch]$logging,
    # Log File Path
    [string]$logPath,
    # Testing Enabled
    [switch]$testing,
    # Test Recipient, eg recipient@domain.com
    [string]$testRecipient,
    # Output more detailed status to console
    [switch]$status,
    # Log file recipient
    [string]$reportto,
    # Notification Interval
    [array]$interval
)
###################################################################################################################
# Time / Date Info
$start = [datetime]::Now
$midnight = $start.Date.AddDays(1)
$timeToMidnight = New-TimeSpan -Start $start -end $midnight.Date
$midnight2 = $start.Date.AddDays(2)
$timeToMidnight2 = New-TimeSpan -Start $start -end $midnight2.Date
# System Settings
#$textEncoding = [System.Text.Encoding]::UTF8
$today = $start
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Path to the logo if not used, comment the three next line and search this line "<img src=""cabecera.png"">" and delete it."
$cabecera = "C:\imagenes\headeremail.png"
$fileName=(Get-Item -Path $cabecera).name
$base64String = [Convert]::ToBase64String([IO.File]::ReadAllBytes($cabecera))
# End System Settings
<# Old Params credentials
#import credential
$username = "soluciona@telefonica.com"
#(get-credential).password | ConvertFrom-SecureString | set-content "C:\password\password.txt"
$password = Get-Content "C:\Password\password.txt" | ConvertTo-SecureString 
$credential = New-Object System.Management.Automation.PsCredential($username,$password)
#>
############################################################  New Params credentials ############################################################
#Specify user credentials.
$mailFrom = "emailaccount@withdelegatedpermissions"
$password = "password_email_account"
$securePwd = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($mailFrom, $securePwd)
############################################################End new params #######################################################################

# Load AD Module
try{
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch{
    Write-Warning "Unable to load Active Directory PowerShell Module"
}
# Set Output Formatting - Padding characters
$padVal = "20"
Write-Output "Script Loaded"
Write-Output "*** Settings Summary ***"
$smtpServerLabel = "SMTP Server".PadRight($padVal," ")
$expireInDaysLabel = "Expire in Days".PadRight($padVal," ")
$fromLabel = "From".PadRight($padVal," ")
$testLabel = "Testing".PadRight($padVal," ")
$testRecipientLabel = "Test Recipient".PadRight($padVal," ")
$logLabel = "Logging".PadRight($padVal," ")
$logPathLabel = "Log Path".PadRight($padVal," ")
$reportToLabel = "Report Recipient".PadRight($padVal," ")
$interValLabel = "Intervals".PadRight($padval," ")
# Testing Values
if($testing)
{
    if($null -eq ($testRecipient))
    {
        Write-Output "No Test Recipient Specified"
        Exit
    }
}
# Logging Values
if($logging)
{
    if($null -eq ($logPath))
    {
        $logPath = $PSScriptRoot
    }
}
# Output Summary Information
Write-Output "$smtpServerLabel : $smtpServer"
Write-Output "$expireInDaysLabel : $expireInDays"
Write-Output "$fromLabel : $from"
Write-Output "$logLabel : $logging"
Write-Output "$logPathLabel : $logPath"
Write-Output "$testLabel : $testing"
Write-Output "$testRecipientLabel : $testRecipient"
Write-Output "$reportToLabel : $reportto"
Write-Output "$interValLabel : $interval"
Write-Output "*".PadRight(25,"*")
# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
# To target a specific OU - use the -searchBase Parameter -https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-aduser
# You can target specific group members using Get-AdGroupMember, explained here https://www.youtube.com/watch?v=4CX9qMcECVQ 
# based on earlier version but method still works here.
$users = get-aduser -filter {(Enabled -eq $true) -and (PasswordNeverExpires -eq $false)} -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress | Where-Object { $_.passwordexpired -eq $false }
# Count Users
$usersCount = ($users | Measure-Object).Count
Write-Output "Found $usersCount User Objects"
# Collect Domain Password Policy Information
$defaultMaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop).MaxPasswordAge.Days 
Write-Output "Domain Default Password Age: $defaultMaxPasswordAge"
# Collect Users
$colUsers = @()
# Process Each User for Password Expiry
Write-Output "Process User Objects"
foreach ($user in $users)
{
    # Store User information
    $Name = $user.Name
    $emailaddress = $user.emailaddress
    # This variable are same that $pwdLastSet and not are used
    #$passwordSetDate = $user.PasswordLastSet
    $samAccountName = $user.SamAccountName
    $pwdLastSet = $user.PasswordLastSet
    # Check for Fine Grained Password
    $maxPasswordAge = $defaultMaxPasswordAge
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user) 
    if ($null -ne ($PasswordPol))
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge.Days
    }
    # Create User Object
    $userObj = New-Object System.Object
    $expireson = $pwdLastSet.AddDays($maxPasswordAge)
    $daysToExpire = New-TimeSpan -Start $today -End $Expireson
    # Round Expiry Date Up or Down
    if(($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -le $timeToMidnight.TotalHours))
    {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "0"
    }
    if(($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -gt $timeToMidnight.TotalHours) -or ($daysToExpire.Days -eq "1") -and ($daysToExpire.TotalHours -le $timeToMidnight2.TotalHours))
    {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "1"
    }
    if(($daysToExpire.Days -ge "1") -and ($daysToExpire.TotalHours -gt $timeToMidnight2.TotalHours))
    {
        $days = $daysToExpire.TotalDays
        $days = [math]::Round($days)
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "$days"
    }
    $daysToExpire = [math]::Round($daysToExpire.TotalDays)
    $userObj | Add-Member -Type NoteProperty -Name UserName -Value $samAccountName
    $userObj | Add-Member -Type NoteProperty -Name Name -Value $Name
    $userObj | Add-Member -Type NoteProperty -Name EmailAddress -Value $emailAddress
    $userObj | Add-Member -Type NoteProperty -Name PasswordSet -Value $pwdLastSet
    $userObj | Add-Member -Type NoteProperty -Name DaysToExpire -Value $daysToExpire
    $userObj | Add-Member -Type NoteProperty -Name ExpiresOn -Value $expiresOn
    # Add userObj to colusers array
    $colUsers += $userObj
}
# Count Users
$colUsersCount = ($colUsers | Measure-Object).Count
Write-Output "$colusersCount Users processed"
# Select Users to Notify
$notifyUsers = $colUsers | Where-Object { $_.DaysToExpire -le $expireInDays}
$notifiedUsers = @()
$notifyCount = ($notifyUsers | Measure-Object).Count
Write-Output "$notifyCount Users with expiring passwords within $expireInDays Days"

########################################################################### New Parameters for O365 send mail ###########################################################################
#Block to send email
# Params to authenticate with O365
#Check MSAL.PS Module is installed.
If(-not (Get-Module -Name MSAL.PS -ListAvailable)) {
    Install-Module MSAL.PS -Force -Confirm:$false
}

#Provide your Tenant Id.
$tenantId = "Your tenant ID"
   
#The Azure AD App id .
$appClientId="Your App ID"
   
$msalParams = @{
   ClientId = $appClientId
   TenantId = $tenantId
   Scopes   = "https://graph.microsoft.com/v1.0/users/$mailFrom/sendMail" # Old 'https://graph.microsoft.com/.default'
}
  
#Acquire token by passing user credentials  .
$MsalResponse = Get-MsalToken @msalParams -UserCredential $credential
$Token  = $MsalResponse.AccessToken

$Headers = @{
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $Token" }

function Send-mailOutha {
                param (
                  [string]$MsgFrom,
                  [string]$EmailRecipient,
                  [string]$MsgSubject,
                  [string]$HtmlMsg
                )
              # Create message body and properties and send
              $MessageParams = @{
                "URI"         = "https://graph.microsoft.com/v1.0/users/$MsgFrom/sendMail"
                "Headers"     = $Headers
                "Method"      = "POST"
                "ContentType" = 'application/json;Charset="UTF-8"'
                "Body" = (@{
                  "message" = @{
                  "subject" = $MsgSubject
                  "body"    = @{
                    "contentType" = 'HTML' 
                    "content"     = $htmlMsg } 
                    "toRecipients" = @(
                  @{
                    "emailAddress" = @{"address" = $EmailRecipient }
                    } )
                  "attachments" = @(
                      @{
                          "@odata.type"  = "#microsoft.graph.fileAttachment"
                          "name"         = $fileName
                          "contentType"  = "image/png"
                          "contentBytes" = $base64String
                      })       
                  }
                }) | ConvertTo-JSON -Depth 6
              } # Send the message
                 Invoke-RestMethod @Messageparams
} # End Function
########################################################################### End new parameters for O365 send mail ###########################################################################


# Send Email
# Process notifyusers
foreach ($user in $notifyUsers)
{
    # Email Address
    $samAccountName = $user.UserName
    $emailAddress = $user.EmailAddress
    # Set Greeting Message
    $name = $user.Name
    $messageDays = $user.UserMessage
    # Subject Setting
    $subject="WARNING!! User password expiration for: $samAccountName"
    # Email Body Set Here, Note You can use HTML, including Images.
    # examples here https://youtu.be/iwvQ5tPqgW0 
    $body ="
    <meta charset=""UTF-8"">
    <font face=""Calibri"">
    <br>
    <table border=""0"">
    <tr>
	<td>
	<img src=""cabecera.png"">
	</td>
    </tr>
    <tr>
	<td>
	<p> Name: <font color=#FF0000> $name </font> <br>
    Telxius ID: <font color=#FF0000> $samAccountName </font><br>
    <p> Dear user, <br><br>
    The automatic password expiration verification system has detected that your password in Telxius domain expires in: <font color=#FF0000> $messageDays days </font> <br>
    <p> Following the established regulations, in case you do NOT make the password change before the expiration of this period, your account <b>will be blocked</b>.<br>
    <br>
    <p><b> We recommend you to change your password as soon as possible.</b></p> <br>
    If you have questions about how to change your password, please review the following information.<br><br>
    <p>https://resetpasswordapps.telxius.com/<br>
    <p> <br> 
    </P>
	</td>
    </tr>
    <tr>
	<td bgcolor=""#002b3c"">
    <font color=##002b3c>.<br>
    <font color=##002b3c>.<br>
	</td>
    </tr>
    </table>
    </P>
    </font>"
    # If Testing Is Enabled - Email Administrator
    if($testing)
    {
        $emailaddress = $testRecipient
    } # End Testing
    # If a user has no email address listed
    if($null -eq ($emailaddress))
    {
        $emailaddress = $testRecipient    
    }# End No Valid Email
    $samLabel = $samAccountName.PadRight($padVal," ")
    try{
        # If using interval paramter - follow this section
        if($interval)
        {
            $daysToExpire = [int]$user.DaysToExpire
            # check interval array for expiry days
            if(($interval) -Contains($daysToExpire))
            {
                # if using status - output information to console
                if($status)
                {
                    Write-Output "Sending Email : $samLabel : $emailAddress"
                }
                # Send message - if you need to use SMTP authentication watch this video https://youtu.be/_-JHzG_LNvw
                # New method using O365 send mail
                Send-mailOutha -MsgFrom $mailFrom -EmailRecipient $emailaddress -MsgSubject $subject -HtmlMsg $body
                $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "OK"
            }
            else
            {
                # if using status - output information to console
                # No Message sent
                if($status)
                {
                    Write-Output "Sending Email : $samLabel : $emailAddress : Skipped - Interval"
                }
                $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "Skipped - Interval"
            }
        }
        else
        {
            # if not using interval paramter - follow this section
            # if using status - output information to console
            if($status)
            {
                Write-Output "Sending Email : $samLabel : $emailAddress"
            }
            # new method using O365 send mail
            Send-mailOutha -MsgFrom $mailFrom -EmailRecipient $emailaddress -MsgSubject $subject -HtmlMsg $body 
            $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "OK"
        }
    }
    catch{
        # error section
        $errorMessage = $_.exception.Message
        # if using status - output information to console
        if($status)
        {
           $errorMessage
        }
        $user | Add-Member -MemberType NoteProperty -Name SendMail -Value $errorMessage    
    }
    $notifiedUsers += $user
}

############################################################################## New parameters for O365 send mail ##############################################################################

function Send-mailOutha2 {
    param (
      [string]$MsgFrom,
      [string]$EmailRecipient,
      [string]$MsgSubject,
      [string]$HtmlMsg
    )

    $fileName=(Get-Item -Path $logFile).name
    $base64String = [Convert]::ToBase64String([IO.File]::ReadAllBytes($logFile))  
  # Create message body and properties and send
  $MessageParams = @{
    "URI"         = "https://graph.microsoft.com/v1.0/users/$MsgFrom/sendMail"
    "Headers"     = $Headers
    "Method"      = "POST"
    "ContentType" = 'application/json'
    "Body" = (@{
        "message" = @{
        "subject" = $MsgSubject
        "body"    = @{
        "contentType" = 'HTML' 
        "content"     = $htmlMsg } 
        "toRecipients" = @(
            @{
                "emailAddress" = @{"address" = $EmailRecipient }
        } )
        "attachments" = @(
            @{
                "@odata.type"  = "#microsoft.graph.fileAttachment"
                "name"         = $fileName
                "contentType"  = "text/plain"
                "contentBytes" = $base64String
          })       
      }
    }) | ConvertTo-JSON -Depth 6
  } # Send the message
     Invoke-RestMethod @Messageparams
}
######################################################################### End new parameters send mail o 365 #########################################################################

if($logging)
{
    # Create Log File
    Write-Output "Creating Log File"
    $day = $today.Day
    $month = $today.Month
    $year = $today.Year
    $date = "$day-$month-$year"
    $logFileName = "$date-PasswordLog.csv"
    if(($logPath.EndsWith("\")))
    {
       $logPath = $logPath -Replace ".$"
    }
    $logFile = $logPath, $logFileName -join "\"
    Write-Output "Log Output: $logfile"
    $notifiedUsers | Export-CSV $logFile
    if($reportTo)
    {
        $reportSubject = "Password Expiry Report"
        $reportBody = "Password Expiry Report Attached"
        try{
            Write-Output "Dentro del segundo envio de correo"
            #new function sendmail o365
            Send-mailOutha2  -MsgFrom $mailFrom -EmailRecipient $reportTo -MsgSubject $reportSubject -HtmlMsg $reportbody
        }
        catch{
            $errorMessage = $_.Exception.Message
            Write-Output $errorMessage
        }
    }
}
$notifiedUsers | Select-Object UserName,Name,EmailAddress,PasswordSet,DaysToExpire,ExpiresOn | Sort-Object DaystoExpire | Format-Table -autoSize

$stop = [datetime]::Now
$runTime = New-TimeSpan $start $stop
Write-Output "Script Runtime: $runtime"
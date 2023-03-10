############# Method 1: Azure APP Registry
# Work with Mfa and without MFa 

# Construct URI and body needed for authentication
$tenantid = 'yourtenant.onmicrosoft.com'
$AppSecret = 'secretValue'
$AppId = 'yourAPPId'
$uri = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"

$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
    grant_type    = "client_credentials"
}
 
# Get OAuth 2.0 Token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing 
 
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
 
# Base URL
$uri = "https://graph.microsoft.com/beta/"
$headers = @{Authorization = "Bearer $token"}

# Example
Invoke-restmethod -Method GET -Uri "$($uri)reports/getsharepointsiteusagesitecounts(period='D7')" -Headers $headers

############# Method 2: Azure User Autenthication

#Check MSAL.PS Module is installed.
If(-not (Get-Module -Name MSAL.PS -ListAvailable)) {
    Install-Module MSAL.PS -Force -Confirm:$false
}

#Provide your Tenant Id.
$tenantId = "27d68020-3ec4-49dc-b978-9f393df284aa"
   
#The Azure AD App id .
$appClientId="b46b16c9-c827-4a75-a60d-2c1258689c1b"
   
$msalParams = @{
   ClientId = $appClientId
   TenantId = $tenantId
   Scopes   = 'https://graph.microsoft.com/.default'
}
 
#Specify user credentials.
$userName = "AdeleV@2rhvvz.onmicrosoft.com"
$password = "Dante7924"
$securePwd = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $securePwd)
 
#Acquire token by passing user credentials  .
$MsalResponse = Get-MsalToken @msalParams -UserCredential $credential
$Token  = $MsalResponse.AccessToken

$Headers = @{
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $Token" }

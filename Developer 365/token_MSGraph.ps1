# Create a Token to use in MSGraph API 

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
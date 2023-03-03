
# Params to authenticate with O365
$AppId = "000000-0000-0000-0000-000000000000"
$AppSecret = "yourownsecret"
$TenantId = "0000000-0000-0000-0000-000000000000"
# Construct URI and body needed for authentication
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $AppSecret
    grant_type    = "client_credentials"
}
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
# Unpack Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token
$Headers = @{
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $Token" }
############################################################################################
function Send-Mail-Outha {
  param (
    [string]$MsgFrom,
    [string]$EmailRecipient,
    [string]$MsgSubject,
    [string]$HtmlMsg
  )
<#Msg Variables example
$MsgFrom = "Iber0@contoso.onmicrosoft.com"
$EmailRecipient = "alejandro.aguado@contoso.com"
$MsgSubject = "Mellow greetings"
$htmlHeaderUser = "<h2>Hi human </h2>"
$htmlline1 = "<p><b>Welcome to modern auth sendmail</b></p>"
$htmlline2 = "<p>This message has been sent to you from an account with modern authentication. </a> </p>"
$htmlline3 = "<p>Not are necessary the use of double factor autheticaction .</p>"
$htmlbody = $htmlheaderUser + $htmlline1 + $htmlline2 + $htmlline3 + "<p>"
$HtmlMsg = "</body></html>" + $HtmlBody
#>
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
    }
  }) | ConvertTo-JSON -Depth 6
} # Send the message
   Invoke-RestMethod @Messageparams
} # End Function

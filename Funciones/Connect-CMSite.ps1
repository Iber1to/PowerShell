
<#
.SYNOPSIS
    Connect to SCCM site.

.DESCRIPTION
    Connect to SCCM site and load configmanager powershell module.

.PARAMETER SiteCode
    Code for site connect

.PARAMETER ProviderMachineName
    Name FQDN Primary Server on SITE

.EXAMPLE
     Connect-CMSite

.EXAMPLE'
     Connect-CMSite -SiteCode 'CM1' -ProviderMachineName 'yourserver.contoso.com'

.NOTES
    Author:  Alejandro Aguado Garcia
    Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Twitter: @Alejand94399487
    Github: https://github.com/Iber1to
#> 
function Connect-CMSite{
 
[CmdletBinding()] 
    param (
        [ValidateNotNullOrEmpty()]
        [string]$SiteCode,
        [string]$ProviderMachineName               
          )

# Importando el ConfigurationManager.psd1 module 
if($null -eq (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Monta la unidad del sitio si no existe todavia
if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}

# Cambia la localización al codigo de sitio
Set-Location "$($SiteCode):\" 
}
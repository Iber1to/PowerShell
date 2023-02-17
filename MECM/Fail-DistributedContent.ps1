<#
.SYNOPSIS
    Redistributes failed packets.
    
.DESCRIPTION
    Get all packages that have failed to be distributed or have failed to be validated at each distribution point.
    The script use 'SMS_PackageStatusDistPointsSummarizer' WMI class more info in: https://learn.microsoft.com/en-us/mem/configmgr/develop/reference/core/servers/configure/sms_packagestatusdistpointssummarizer-server-wmi-class
    We get package with:
    State = 2 'INSTALL_RETRYING'
    State = 3 'INSTALL_FAILED'
    State = 8 'CONTENT_MONITORING' this state are Validate Content not for distributed package.
    The script are configurated for work in primary site, to to avoid problems with your network's port configuration. If you have your primary server to make remote WMI connections, you can use -Computername parameter in line 182
    Workflow:
        - Load package fails to WMI class
        - Connect to SCCM site to use SCCM cmdlets
        - Delete package fails
        - Send package delete
        - Report by email with results

.KNOWN ISSUES
    The client Upgrade Package, its an special package hidden which cannot be deleted and sent by this method, so it will always fail when processed by this script.
    It can be deleted from the SCCM console - Monitoring - Content Status. SCCM will resend the packet to the distribution point over time. 
    If you want to force the delivery you can try the procedure in the following article : http://www.kwokhau.com/2014/04/configuration-manager-client-upgrade.html
        
.NOTES
    Author:  Alejandro Aguado Garcia
    Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Twitter: @Alejand94399487
#> 
function Write-CMTracelog {

    [CmdletBinding()]
    Param(

          [Parameter(Mandatory=$true)]
          [String]$Message,
            
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Path,
                  
          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [String]$Component= $MyInvocation.MyCommand.Name,

          [Parameter()]
          [ValidateNotNullOrEmpty()]
          [ValidateSet("Information", "Warning", "Error")]
          [String]$Type = 'Information'
    )

    if(!$Path){
        $Path= $PathCMTracelog
        }
        
    switch ($Type) {
        "Info" { [int]$Type = 1 }
        "Warning" { [int]$Type = 2 }
        "Error" { [int]$Type = 3 }
    }

    # Create a CMTrace formatted entry
    $Content = "<![LOG[$Message]LOG]!>" +`
        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
        "component=`"$Component`" " +`
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
        "type=`"$Type`" " +`
        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
        "file=`"`">"

    # Add the line to the log file   
    Add-Content -Path $Path -Value $Content
}

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

function send-MailHtml{
    <#
    .SYNOPSIS
        Send an email with the corporate template.
    
    .DESCRIPTION
        Send an email with the corporate template format.
         The HTML titles H2 and H4 are used.  
    
    .PARAMETER Subject
        Subject that will appear in the email. Mandatory parameter. 
    
    .PARAMETER ListAdress
        List of addresses to send to. Supports multiple addresses. Mandatory parameter.
    
    .PARAMETER Title
        Text to appear in the body of the message with title format <H2>. Optional.
    
    .PARAMETER Message
        Text to appear in the body of the message below the title in <p> format. Optional.
    
    .PARAMETER attachment
        Attachment file to email. 
       
    .EXAMPLE
        send-MailHtml -Subject "Tarea programada ejecutada" -ListAdress "alejandro.aguado@contoso.com"
        send-MailHtml -Subject "Tarea programada ejecutada" -ListAdress "alejandro.aguado@contoso.com" -Title "Informacion sobre tareas programadas" -Message "Esta es una tarea automatizada" -attachment "C:\temp\text.txt"
    
    
    .NOTES
        Author:  Alejandro Aguado Garcia
        Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
        Twitter: @Alejand94399487
    #> 
    
        [CmdletBinding()]
        Param(
    
              [Parameter(Mandatory = $true)]
              [String]$Subject, 
              [string[]]$ListAdress,
              [string]$SmtpServer,
    
              [Parameter()]
              [ValidateNotNullOrEmpty()]
              [String]$Title,
              [String]$Message,
              [string[]]$attachment
        )
    
        #Mail variables.
        $scriptFrom = $myInvocation.ScriptName
        $LaunchDate = Get-Date
        $MailSender = "SCCM Monitoring <automatic_sender@econtoso.com>"
    
        #Body message
        $htmlBody = '<p>&nbsp;</p>
        <h2>{0}</h2>
        <p>{1}</p>
        <p>The Script: {3} are work fine.<br>
        Execution date: {2}<br>
        Please this is an automated message. Please do not reply to this email.<br></p>
        <table style="height: 25px;" width="100%">
        <tbody>
        <tr>
        <td style="text-align: left;" colspan="3"><img id="Umbrella Corp" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/4QAiRXhpZgAATU0AKgAAAAgAAQESAAMAAAABAAEAAAAAAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCACWAJYDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD8A6KKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKaz5oAGam0V0cvwt1aH4WQ+MTD/xJJtSbShIAciZYxJzxjBBIBzyVb0qZTjG3M99Dajh6tXm9nFvlTbt0S3foc5nFGa/RL9pH/g3j+I0fg23+I37Pt03xk+F+tW0Gp2EO6Gz8S2FtcxJcW6zWjOFuGaKWMqbYs7g7mhhztHzd4d/4JSftLeI/EFtpzfAv4o6M90zoLrXvD1xolhDsjaRzLd3ixW8KqiMxaSRQApJNUYnz9Rmvuf8Aao/4IxXv7CP/AATss/i58VvFUdl8QPFur2Ol+HfBmmIsrWSzRSXMk1/MxGGWCFh5USkI80O6QkvGvxLpnhy+1nT7+6tbSe4t9LiWe7kRMrbxtIsasx7Au6r9WFLmW5UISm7RV3q9PJXf3LV+RTDGnhs1HQDimSSUUA5FFABRRRQAUUUUAFFFFABRRSM2KAEc02jOa7b4NX/gWHUJrfxpp+qXEM3EF1aXPlrbHGPnQKWYZwcgkjH3Tms6tTki5Wb8ludmBwqxNeNBzjDm+1JtRXq0nb127nP+CfBd94+8QQ6bp8atNKfmd22xwJkAu7HhVGeSf5kCvrWX4c/2J8BZfAUsj/ZtVlLQpcqLdEkEYeG6TruyVG5W7yOQRnbXS+C/DPg8eGUbw7Bb6fpt1Ept59PuC32yREG7eNxG5WLD58na4B5XNVfiR8TdL8QNFpcSz+doNyTJdSg/Mvlo3AAyMtIwCjgnHGeT8XmGbVMRNRpJpR1t1v8A8Bn9GcKcBYTKsM6uMqKcqyceZP3eVptpd1KKd291ta13+n3/AAbg/tP6p8af2H7fwPqSsuo/B/UJNAuZJJ/MkktpXlurUSL1TbunhQMcbbbCg7XA+8/ivnxB8PtT0i38P2eqNcWtxBBZ3QRre6MqeXtn3MP3IJyw67d20EsBX4tf8EQPidcfs3/8FM28L6hObLw/8evD88QQMqw2uq2W66hZhkq8jRxzxAcgvqHHQGv2y034iaT4O0q6uNdvLfSdPtzNLeXV/JhbWGPJeUkAggKu4YJBUDocV9dh66rU41Y9V/w/4n8+Z3ldTLcfVwVTeDa10ut0/mrP5n4N/wDB0D+0tq3jr9o/4d/CXUNVXVpvhV4ZiuNWuBGI3m1K/ihcvJjhmNjBpzE/35JMYBwOI+DX7HbeEP2IdT8PzeXb+NPiPF517bzoA0USostpECeQUk2u64yCRzjIPl3w98Qf8PCP+CivjX4reKodumajrlz4lksJW3Ltef8A0SwDHgRopij5ONkW3qRn7WsNWbx9qMM8s9rJJbXTxxQMXZouCUYNjG8YccnaCeQMgn5ziDMJRlHD0ulm/Xov1+4/YfCfhWnUo1M0xkbqacIryaak/n8K/wC3u5+O+o6fPpN/Na3UTwXFtI0UsbjDRupwVI9QQRUNfpd+2b/wT78M/E7wt/wlSalJ4c8bSSyC6cwhrXUkRFPmSIvKOu4K0gPVlBVjgn8+fih8JNU+E2ow2+pSWMn2kMYjb3KyEgYySnDqORgsoB5xnBr2cvzahikop2l2f6dz8/4o4FzHJ5TrSjz0E7Ka2305lvF9NdG9mzlwcGpKjp6nIr1D4kWiiigAooooAKKKKACmP96n1GetABX6SeBP+CJXgn9r/wDY/wDBvxU+D/xCvtDvtcgW31LRfFCJd2un30b+TdCS8t1SSKNHAkA+zSkxTxMSozn826/Sz/ggZ8SPiReaT4q8K6Be2MXgrQ9Xt9e1C3ki3XN1dTwSRpBC8mYovNFom47DI3lRgMqCU0PbQD5z+Pn/AATu/aQ/4J2atJceJPBet2WlSQG8k1HS2XVNJntkOPNmkgLLEvOB5wjcfNwpBx5/4d+OZ8RzalayMtidYijWSKWYtE8qjZvVj0ONpAJ/hwWPFfu9Z/tjeH/hla6fqvjj4i6XoOqeK7C08QQXuq6kLC31tjAPls52wirBtWAwsRJH8jOGM5nm8y13/glF8KP2wPFHiLxd44s9I1G88UTtcWdz4RmNjJbWuyOOF45UXyrieRYzI8s0cqtJM5ClAijhr4OjW96a97uvvPpMn4pzDLrU6U26ad+R7Xaaduzs3qvnc/NS/wDjFqXh+z8IeMNCZl8WfD/V7TxBpkk43NFd2kiSRKQMEqwiOR3LL7Y/RP8A4K3ftYXmr/8ABM1vEnhvWLy4h+NEtvoehlNOktJFsptriDy5B5he5tFmd5M7AJtgBLI9eRfHr/ggJ4u+Afh268RfDf4iaVrfgyzh+0vZ+O9mhfYjk4jh1IlrYkFSfMuVtYuGyvy8/KPh79oTx1+2pD8If2f9PtfDfl/CaTWrTwy9/wCJbOyhuWvLsS4kuZpPJm8mMNFbpCZHZSFiViwFceX4ethYTppcy3j/AJeR9NxTnGVZ/iMNjef2MrKFVNN2S1U01fm0uujvyq3U6b4CfD2X4U+DNG0+xgiFw9r5+oSxFXlllmlEXzY6Lj7oP8JU/wAZFdR8UP21PAvwN8RW2bqx8UXUJ/0zTdNVZEnG3a0byf6sBhwQckZOVbpX1J8Jv+DbD4hfF6aSD4rfGzRfDNnFKkFz4f8AB1hLL5yFOY5Lu7MBVlCjP7mdeBtB6j65+A3/AAb+fss/s0NHKfhzJ461W3IaPUvGt5NqJCkZybUCGzcEkAF7cjjgnPPm0OH3Un7XFzu27tL9X/l959Vmvi1h8NRWByGh7kUoqU+iStpFP8W9esT8BvGn7aPxS+LFnr8Hht9esPD8Ur3s62hkvLqwtixWNJrvb5mxA+wOxVmBAZmODU+t/wDBNj4naH+yjffHDxRdeEvD/gllt2sbi98QQXN7r1xcYaO3ggtjNIJypZys4iwsUpJHlvj+mTx/Npvw2+DGr6HpvhHS9D8P+UbeDQtMsYodKaAyCN5EghVFSPyiGdUjZo1VsqyjLfzs/wDBZfxpYaB+0jd/Dfwa2raL8P8AR2h8R/8ACOSXEjWdnq+oWsM11PEjIoAdDDt2lkILOmwSsg+kw9ClSuqUUv1Px3Ms4x2PkpYyrKdtk3ovRbL5I+OqcnSm05OldB5o6iiigAooooAKKKKACoz1qSmN96gBK/YT/gmT8D/Bf7Gv7H1n4s+InjGP4f6544+13OpW+pa5Dp7TwLmK2jhidtzTRqJzmIGRWuZFcZhUL+PYO05Fb2j+EPEXxKubu8trW/1SRAZLi5clskDPzOx5bHbOTU1JRiuabsjbD4atXqKlQi5SeySbb+S1P1g/aW/4K2fss6FrGo33hfQfFvjTVptOt9LtrPQFOh6DFZwKyRwebcRrcKxDMzkWzqzSv2Cbfn3Rf+Cunxgl0ltM+DPhLwH8FvDdxdM639rpq399KzKytvuLsSI8mGYb4II2HHI5J8X+Bv7Lui6z4S03Xo5ovEd5IXlubOZQsUCKyLswrErISWGZQAMA45GfdvF+gaD4TlE2nXljdKybAAztD5YCscblAXKnAGcqcngGvl8w4gjSbp4dXa6vp8j9q4P8I5YzlxOa1OWEkmowabafeWqXyve+6PJfid4z1bxv4iute+JnjXxJ8Sta0+2luI9V1/UpdQVAMZjgWZmEWcIFXGQQgG3GB9lftv8A7Aenfs5/8E2P2d/G1zp+j/8ACR6jcTaR8QXWxVp7ubWoxqNq1w/KlbKeKSyDMSF3JgnKk/OX7IvwFs/2rf2//hv4GW1XU/D012PEfiOzdVW3GlWANxJbyyEhFW48nyyzYVTJEec4r9d/+CgHg++/bk/ZR8S+AobW3gl8WeH7vX7Jo7ma9nvZQr3OjQfuVAaeae1jaVg8scYVh+8DxMvVl+HnWw7qV5NuovuXl2117aI8rjTOsPlWcUsDlVKMaeFldpbTk7XUnq5e77rvd2bTPy5/Z9/a7/aM/YyvobH4T+PtQuNA0sxyp4P8Qy/2voX7sEmOBZiTakbj80Lxkgn94o4r7V/Zh/4OfvCUnj+18O/tFeAfEfwv1mCby9Qv9KgfUtNWQ/eaS2k/0uCEAYCqbtzkHPcfCH7JPjbR/H/wptfEOoSxrq9nIBNdzMPNW5TIKK2CVzvicAdPMfjk56/42/D2P4yWbDx3BZ6hp9rH/osk06tqUa7DIEiKHepwV3E7lG0E5U5rycPntbC1Pq+K95LS/X/g/mfaZx4Z5dnlCOZZK1RdRcyX2JX1Ssl7j115bpbcvU/Ye6+I/wAO/wDgoP8ADKf/AIQXxb4d8b+GftdreFtKujObOKK4SRRcpGyzWrlVYiOcRud4yvO2vwt/4L6/si3P7Nf7V+i65Gt/caN4/wBFS6ivrl5ZGmurVzbSxs8ru7SiFbSRzu25uAVVFIRfE9f+Anjb9nLxZa+Lvh74g1vT7qwlaTT77Tb17HVbYjjdFJGVZjg4Jjw3J+UYNXv2mP8AgqB8XP2vfgRp/wAP/ilfaP4x/sHVI9R07Xb7TUj1ywKwvC8HnxbBIkgcGQzI8jNFFl/kUD6vC4qjXjz0ZXX4/NH4RnXD+YZTX+r4+m4Pp1T801o/k/U+dacnSm05OldZ446iiigAooooAKKKKACmuOadTXagBta3hvx1rHg8n+y9SvLJWbcyRykRuf8AaX7rdB1B6Vk0VMoxkuWSujahiKtGaqUZOMls02mvmj6O/ZO/bG1LwJr11pc8ljazeIGWI3bWsflvJu+XzAMYPzMobJQByCuDuX1e4kttP0fVP7cmvrWDTITd3Q+yqsy9TyTyU2g4PUj5cEnNfDQOK92+Mn7Qsnj34A+EdJX7DLrl9F9n1E20aLN5cL7EEgVQTJMVWRmJLNgZ4xXzOaZLGpXhKkrKTs7dPP7lb7j9p4I8SJ4TLsTDGvmqU480G9XK7S5X3fM07725r7H6hf8ABtR+zP8A8LE8J/F744a9o1rdx+LL5PCGmQTxZhjsohHcXaFcYaMu1gisO9pKOcHH65eFfh1Y6Bren3sNja6Ta2rJLi0iCbNuf4UHIDEsNo4znjFfEvwI+MPwT/4Ix/sw+EfhZ8YvFGg+G9X0Pw9bXHkZ+06qdRmJm1BDBao915X2x5xDM6YZMxs0axCtbwL/AMHJv7JPifxMukWvjDxJ4St422wXmreHLiOyY8gKph850Unb80ioASSSq5I+jjBRXLFaLRH4tiK9SvVlWqu8pNtvu27t/efk/wDtrfBSb9jP/gq78ZPhTBC2jeHfEGsnxH4ftTGVt4YLuI3ltCoJwRHDctAW5+aAjGcgQ/ET4sWz6nq19qVxL4aYRIfs1rK/2QxQxGOMPySflHUEnd/Cc4b6p/4OqvAVl49tfgX+034L1bTfEWkXyTeE31vTb6G9s5hE73un7ZYWaORizakjEE4FuqknGF/Mz9q34z2PjHwd4ZsNHWOGO/hbUr0I5Zvnb5IXb/pmwk+XpnB618zmmUutjYSjtP4n2sv1W3mft/A/HlPL+G69KtrUw79xX3U3ov8At2d3L+60uhieKv2staup76LTfJMNw48q4u7aN5oowDhFUfIq5LMVIbJOSSea8y8R+Jb3xZqjXuoTfaLqRVVn2KuQBgcKAOlUaK+ioYOhR1pRSe1+v3n5JmvEWZZlpjK0pRu3y3fKm76qO19d9wqRRgVHShsGuk8UfRQDkUUAFFFFABRRRQAVG3WpKjoAKK94/bvsNK02++Ecek6bbaar/C/QJbsQ6ZYWX2m5eF2kmZrNFE7OTkzTFrg8LK25MD6R/Zp1b4X/AAF+L/iH/hcngPwzq3gvVPgJ4fiFtc6Zo0GpW6ancaGlzqumjb++1SK0u7+4gk/4+j5YLnZG7UAfntU+l6pdaJqVveWVxPZ3lnKs0E8MhjkhkUhldWHKsCAQRyCK+/8A/glv+zx4T+Af7U+uXHxY8Hr4wW4uL3wn4O0/WfB1zfadrE4sXvrjVktp7dvOW3sfsjpC0e/drVjMR5aNml8CPHejeG/+CfPwuTTPE37Nfw88TNr/AIhj1W/+I3wnt/EN5rtuGsWtfKuZNC1EskLPcqT5i48wJg+XwAfCniXxNqXjTxFf6xrGoX2ratqtxJeXt9eTtPc3k8jF5JZJGJZ3ZiWLMSSSSTmqNfp5bfs++GfHn7U/wN1Cax+Deut4y+E/jbUtW8WaJoMGn+AdY1TTtM12a2uEsVtIlt5rJIbA3CGyhy8SuYJFk8644Ox+H2l+Gf2a/il44+KHiX9nfxx4Bv8AT7zw3pn/AAg3gyCDV4vFcllJcaT9nuLTTbU2SLKDLIJpUhnt7a7jWOeRAqgHw/ZfFjxPp3wzvvBcHiDWIfCOp38Wq3eirduLC4u4keOO4aHOwyqjuofG7DEZxXP1+j/7UGjaX4X+GHwTh0nxx+yz8PfL+F/hnxA+h618Mre41zVL42Su0093HoM6XBuHQErc3bIxY+btDNXy5qsFp8Yf2Pvin8UNWsdJtvF1v4/8MaPF/ZOi2um6fDbXmna7NcKkFvCkNvuk020KpEI1AEoVcFsAHgdFfRf/AATU8N2fir4l/Ey3vtA8O+Iobf4SeNL6OHWLaKeO0mt9Cu54rqHzIpNtxDJGskbKFYMoAdMk186UAFFfpV8Ef+CWvir4q/siWfw50D4S+LNV8aeKPBt98Rbrxgvgea8tdP1OPZdab4fXUxF/o/m6VbXD4WQpJeavBBJHvhV4/wA1aAHIadTU606gAooooAKKKKACozwakprLmgD27wN+2lZ6V4D8P6D4y+D/AMKfimvhWF7PSb7xJ/bVre2lq0hlFu0mmajZ+dGjtIUEwkKiRlB27VHO/GP9qrXvj1468TeIvE2m+H7rUPEGkWWg2a21s9nbeG7KyFrFaQWMMLrGqxWtpHbATLLmNnY5mImHmW0ikxQB9DeCf+CnHxQ8M/FT4SeK9WvNP8ZXHwT8OSeFPDFjrazPZwWDR3MaxyLDJE7NHHclFYOrBILdSWWMLVXwL+3PZ6F8AfCfw58T/Bn4U/EbRvBd9qOoaXc69c+Ibe7jkvjAbjcdP1S1Rgfs8IAKcBOuSSfA+tFAH2Z8NP2ztUMWh+PNQ03wN8P/AIeeDbDXPAHhnwpoui3+oWNu+t6bdQancbZL9bl28i5zJc3F5JNue1WOOaOFlhwfg7pOpfADwP8AEz4d2evaH4q1L4l+Ajq2p+G7rTL2XR2sYIBrVrfxXEc0Lx6nDaQ/aoS8DRpFcyxSMGkmgHz18N/jV4n+EiXkfh/VHs4L6SGeeCSGO4geaHf5E4jlVkE8XmSeXMAJI/MfYy7mzduf2jPG974cvNLn8R39xDqAnS5nl2ve3EU8pmnge5IM7QSTM0rwl/LaR2cqWYkgH3F8W9K8N/DPxRo/hn4k/D/4O+PV8L28ngrSdb1q/wBfOo6h/ZDRWjRwpa+KIbZLfcZHElw9uFYSxIkYSOFfO/B3iSPwj4o1D4Z3HwY+EuraX8btb0vXPCGiTXWq3mnSXNnPfaVaLDe2WuiWGOWWXUInElxc/vCCzYRJE+UvE/xo8VeNY9UTWNd1DU49Z1C61a7juX8xHvLp4XubhVPCSytbwb3TDOIUBJCgC14V+P8A4x8E+E20TS9eurXT1E6wAKjTWAnXZcC2lZTJbCZPklELJ5q/K+5eKAPsvwtDqXgTxP4U1jwT8Ivgv4VvvHVsfCp0nT7zxBdW+tWHiHRYJJzK7a1c3KC1s5W81cweSt8HPmFo/Ky/iv8AD/wV4M0fxJocvwZ+GOh+INJ8RaJoiXMWmeKY5LtNQea/06dBe6+THb3llZgyl7ZZYortVULIS6fJFr+0D40sbfU4YfEmpxRaxbQ2d4iSbVnihsptPiQjHG2zuJ7cYwfLmkXozAwH44+LToFjpZ16/On6bJZzW0BYbYnszcm1YcdYvtdyFJ6CZh0wAAfQXiTRNc1D9r3W/H1r4p0/RfjZYX178UItG0rSZbTSNK+yLLrHkwXCzboZI7eHzYoo1aJYxGguBICq4/7f37N+t+FPi18VvHWoL4Ts9Pm8cva2sXhqyltdHujdT6oXNnFI7vbxwy6fNGbeQl49yL0AJ8jv/wBpDxxqvhy40q48RXk1rdRS28ruqG4NvLM08lqJ9vmi2aZnlNuGERkdn2bmJOX4q+MXijxvYapa6vrupaha61rEniG+imlLJcahIGD3RHTzGDsCw68Z6DABzqdadTU606gAooooAKKKKACiiigAooooAKa4yKdRQBHRUhXNJsFADKKfsFGwUAMop+wUbBQAyin7BRtxQAiDAp1FFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAf/Z" alt="Umbrella Corp"/>
        </td>
        </tr>
        </tbody>
        </table>'
    
    
     
        if ($attachment) {
            Send-MailMessage  -From $MailSender -to $ListAdress -SmtpServer $SmtpServer -Subject $Subject -Attachments $attachment -BodyAsHtml ($htmlBody -f $Title, $Message, $LaunchDate, $scriptFrom)
        }
        else {
            Send-MailMessage  -From $MailSender -to $ListAdress -SmtpServer $SmtpServer -Subject $Subject -BodyAsHtml ($htmlBody -f $Title, $Message, $LaunchDate, $scriptFrom)
        }
}
# Data for log archive
$pathLog = "C:\temp\"
$nameLog = "pkgredistributed.log"
[string[]]$ListAdress= "Alejandro Aguado Garcia <alejandro.aguado@contoso.com>" # List of e-mail recipients
$SmtpServer = "mail.contoso.com"

$PathCMTracelog = $pathLog+$(Get-Date -Format "MM_dd_yyyy")+"_"+$nameLog
$SiteCode = "CM1"
$Server = "primaryserver.contoso.com"

Write-CMTracelog "Starting script"
#Need execute the script in the primary Site
#Get all jobs which are reporting bad installation or failed the content validation, check http://msdn.microsoft.com/en-us/library/cc143014.aspx for valid State codes
$pkgs = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Query "Select * From SMS_PackageStatusDistPointsSummarizer Where State = 2 OR state = 3 OR state = 8" # -Compuetername $Server

Write-CMTracelog "The following packages are to be removed and redeployment:"
#Capture the data necesary to process the jobs.
$poolpkgs = New-Object System.Collections.ArrayList
foreach ($item in $pkgs){
    $newPoolPkgs = New-Object -TypeName psobject
    $newPoolPkgs | Add-Member -MemberType NoteProperty -Name "DistributionPoint" -Value ($item.ServerNALPath).trim('["Display=\\').split("\")[0]
    $newPoolPkgs | Add-Member -MemberType NoteProperty -Name "PackageID" -Value $item.PackageID
    $newPoolPkgs | Add-Member -MemberType NoteProperty -Name "PackageType" -Value $item.PackageType
    $newPoolPkgs | Add-Member -MemberType NoteProperty -Name "State" -Value $item.State # Add for Debug work
    $poolpkgs.add($newPoolPkgs) |Out-Null
    #Write-CMTracelog "Package Id: $($newPoolPkgs.PackageID) in DP: $($newPoolPkgs.DistributionPoint): "
}
Write-CMTracelog "A total of: $($poolpkgs.Count) jobs in:  $(($poolpkgs | Sort-Object -Property DistributionPoint -Unique).count) Distribution points."

# Connect to Primary SCCM server for use SCCM CMDlets
Connect-CMSite -SiteCode $SiteCode -ProviderMachineName $Server
Write-CMTracelog "Connect to Site: $SiteCode "

#Load list of APP
Write-CMTracelog "Load lists of app in MECM......"
$CMApplication = Get-CMApplication | Select-Object LocalizedDisplayName, PackageID
Write-CMTracelog "$($CMApplication.count) Apps finds."

Write-CMTracelog "We start processing the packages" -Type Warning
#Make sure $pkgs is not empty. Delete pkg and redistributed
if ($poolpkgs) {
    foreach ($item in $poolpkgs){
        switch ($item.PackageType) {
            0 { #Standard Package
                Try{
                    Remove-CMContentDistribution -Force -PackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -PackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            3 { #Driver Package
                Try{
                    Remove-CMContentDistribution -Force -DriverPackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -DriverPackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            4 { #Task Sequence Package
                Try{
                    Remove-CMContentDistribution -Force -TaskSequenceId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -TaskSequenceId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            5 { #Software Update Package
                Try{
                    Remove-CMContentDistribution -Force -DeploymentPackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -DeploymentPackageId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            8 { #Application Package
                Try{
                    Remove-CMContentDistribution -Force -ApplicationName  $($CMApplication | Where-Object {$_.PackageID -eq $item.PackageID}).LocalizedDisplayName -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -ApplicationName $($CMApplication | Where-Object {$_.PackageID -eq $item.PackageID}).LocalizedDisplayName -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            257 { #OS Image Package
                Try{
                    Remove-CMContentDistribution -Force -OperatingSystemImageID  $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -OperatingSystemImageID $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            258 { #Boot Image Package
                Try{
                    Remove-CMContentDistribution -Force -BootImageID  $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -BootImageID $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
            259 { #OS Install Package
                Try{
                    Remove-CMContentDistribution -Force -OperatingSystemInstallerId  $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was deleted with exit"
                    start-CMContentDistribution -OperatingSystemInstallerId $item.PackageID -DistributionPointName $item.DistributionPoint
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) was distributed with exit"
                }catch{
                    Write-CMTracelog "The package Id: $($item.PackageID) in DP: $($item.DistributionPoint) Fail with the next error" -Type Error
                    Write-CMTracelog $Error[0].InvocationInfo.line -Type Error
                }
            }
        }

    }
	
}
Write-CMTracelog "Packaged processed"

# Launch mails to report
Write-CMTracelog 'Sending e-mails'

[string[]]$attachment = $PathCMTracelog
send-MailHtml -Subject "Execution of automatic tasks." -Titulo "Re-distribution of failed pkgs." -Message 'This automated task finds packages that have failed to distribute to a distribution point. 
It removes them and re-distributes them.' -ListAdress $ListAdress -attachment $attachment
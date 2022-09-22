Function Convert-ToUnixDate ($PSdate) {
    $epoch = [timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
    (New-TimeSpan -Start $epoch -End $PSdate).TotalSeconds
 }
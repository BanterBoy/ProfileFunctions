function Connect-InternalPRTG {
    if(!(Get-PrtgClient))
        {
            Connect-PrtgServer -Server "https://csonetmon01.uk.cruk.net" -Credential (Get-Credential)
        }
}

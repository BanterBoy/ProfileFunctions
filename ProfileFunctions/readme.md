# Get-ADUserAudit

These files can be used to query the Security eventlog from your domain controllers to find recent user management events. Save the .ps1 and format.ps1xml files in the same folder. You will need to dot source the ps1 file to load the function into your session.

```powershell
. c:\<your-path>\get-aduseraudit.ps1
```

Then you can run a command like this which will query all domain controllers for all user accounts created and deleted in the last 12 hours.

```powershell
Get-ADUserAudit -event created,deleted -since (Get-Date).AddHours(-12)
```

This function can only retrieve information from the Security eventlog. If you log is too small, you may only be able to capture recent events. You can increase log size with a command like this:

```powershell
limit-eventlog -LogName security -ComputerName dom2,dom1 -MaximumSize 1024MB
```

## Read More

This solution is described in more detail at [https://jdhitsolutions.com/blog/powershell/8132/searching-active-directory-logs-with-powershell/](https://jdhitsolutions.com/blog/powershell/8132/searching-active-directory-logs-with-powershell/).

*_DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING._*


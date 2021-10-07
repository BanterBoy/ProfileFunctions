# Planning: PowerShell Interrogates Outlook
# Stage 1: We create a new ComObject
# New-Object -ComObject Outlook.Application

# Next, we set the namespace
$Namespace = $Outlook.GetNameSpace("MAPI")
$NameSpace.Folders.Item(1)

# Stage 2: We will retrieve information about the actual messages.

# Stage 1: PowerShell Lists Outlook's Folders

Clear-host
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
$NameSpace.Folders.Item(1).Folders | Format-Table FolderPath

# Stage 2: List Senders' Addresses Stored in Outlook's Inbox

# This script connect to the logged on user's Outlook Inbox, then enumerates the email addresses of each message's sender.

Clear-Host
$Folder = "InBox"
Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
$NameSpace.Folders.Item(1)
$Email = $NameSpace.Folders.Item(1).Folders.Item($Folder).Items
$Email | Sort-Object SenderEmailAddress -Unique | Format-Table SenderEmailAddress

# Note 1: Folders.Item(1).Folders.Item($Folder).items is correct

# Instructions: Creating a PowerShell Function
# By wrapping the above instructions in a function we introduce extra flexibility, for example, changing the folder from Inbox to Customers.

# Function: Get-EmailAddressPowerShell Gets Outlook Address
Function Global:Get-EmailAddress { 
    Param(
        [Parameter(Mandatory = $False, Position = 0)]
        [string]$Folder = "InBox"
    )
    Process {
        Clear-Host
        Add-Type -assembly "Microsoft.Office.Interop.Outlook"
        $Outlook = New-Object -ComObject Outlook.Application
        $Namespace = $Outlook.GetNameSpace("MAPI")
        $NameSpace.Folders.Item(1)
        $Email = $NameSpace.Folders.Item(1).Folders.Item($Folder).Items
        $Email | Sort-Object SenderEmailAddress -Unique | Format-Table SenderEmailAddress, To -Auto
    } # End of Process
}
Get-EmailAddress #-Folder Customers


# Ideas for Analyzing Outlook Emails
# I love discovering additional properties to incorporate in my PowerShell scripts; for this research my cmdlet of choice is Get-Member.

Clear-Host
$Folder = "InBox"
Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
$NameSpace.Folders.Item(1)
$Email = $NameSpace.Folders.Item(1).Folders.Item($Folder).Items
$Email | Get-Member -MemberType Properties | Format-Table Name

# Note 2: Using this technique I discovered the 'To' property for my Get-EmailAddress function.  Get-Member also introduced me to properties such as 'Importance' and 'Unread'.

# Another Example Reading Email Subjects
# The design brief: To filter out 'Unread', then sort on a variety of criteria; finally, list the subject and sender of each matching email.

# At the heart of any PowerShell function is the Process.  What this Get-Email function does is create an Outlook object, and then retrieve messages from a named folder.  The default location is set to the Inbox, but the benefit of a function is that you can amend the source of messages using the -Folder parameter.

Function Global:Get-Email {
    Param(
        [String]$Folder = "InBox",
        [String]$Test = "Unread",
        [String]$Compare = $True
    )
    Process {
        $Folder = $Folder
        Add-Type -Assembly "Microsoft.Office.Interop.Outlook"
        $Outlook = New-Object -ComObject Outlook.Application
        $Namespace = $Outlook.GetNameSpace("MAPI")
        $NameSpace.Folders.Item(1)
        $Email = $NameSpace.Folders.Item(1).Folders.Item($Folder).Items
        Clear-Host
        Write-Host "Trawling through Outlook, please wait ...."
        $Email | Where-Object { $_.$Test -match $Compare } | Sort-Object -Property `
        @{Expression = "Unread"; Descending = $true }, `
        @{Expression = "Importance"; Descending = $true }, `
        @{Expression = "SenderEmailAddress"; Descending = $false } -Unique `
        | Format-Table Subject, " ", SenderEmailAddress -AutoSize
    } # End of main section 'Process'
}

Get-Email  #-Compare false

# Note 3: This function has three parameters

# -Folder:  Specifies on of the yellow directories seen in Outlook

# -Test: Allows you to change the criterion.

# -Compare: Enables you to switch false to true, or use a string if that is more appropriate.

# Note 4: @Expression enables us to sort on a variety of criteria.

# Other Outlook Tasks for PowerShell
# If you remember, I used Get-Member to list properties; we could modify the output to list methods.  Methods open up more possibilities, for example, to delete emails, and even add 'Rules' for Outlook to handle incoming messages.  Here is a case in point:

Clear-Host
Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -ComObject Outlook.Application
$Namespace = $Outlook.GetNameSpace("MAPI")
# Try this
$Namespace | Get-Member -MemberType Property
# and then
$NameSpace.DefaultStore | Get-Member -MemberType Method

This is how I discovered:
$Rules = $Namespace.DefaultStore.GetRules()
$Rules | Format-Table Name

# Vaguely Related Topic: Test-Email Function
# I came accross this little function to check the validity of an email address; what attracted me was the existence of [System.Net.Mail.MailAddress].

Function Global:Test-Email {
    Param(
        [String]$Message = "Wrong#gmail.com"
    )
    Begin {
        Clear-Host
    }
    Process {
        If ($Message -As [System.Net.Mail.MailAddress]) {
            Write-Host "$Message is a good email address"
        }
        else {
            Write-Host "$Message is a bad email address"
        }
    } # End of Process 
} # End of function

Test-Email

# Note 5: While this function has a default email address, you can easily append your own thus:
# Test-Email  guythomas'cp.com.

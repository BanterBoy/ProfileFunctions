<#

.Example
# Example usage with splatting:
$parameters = @{
    Subject   = "General Customer Enquiry"
    Name      = "John Doe"
    Telephone = "123-456-7890"
    Email     = "john.doe@example.com"
    Message   = "This is a multi-line message.`nIt contains multiple lines of text.`nHere is another line."
}
Submit-TigerShedsContactForm @parameters

#>

function Submit-TigerShedsContactForm {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("New Sales Enquiry", "Bespoke Building Enquiry", "Delivery Details Update", "Order Change", "Items Delivered Query", "Cancellations", "General Customer Enquiry")]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Telephone,

        [Parameter(Mandatory = $true)]
        [string]$Email,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    # Define the URL of the form action
    $formActionUrl = "https://www.tigersheds.com/contact/"  # This is the correct endpoint based on the form action

    # Map the subject to the correct value
    $subjectMap = @{
        "New Sales Enquiry"        = "1"
        "Bespoke Building Enquiry" = "2"
        "Delivery Details Update"  = "3"
        "Order Change"             = "4"
        "Items Delivered Query"    = "5"
        "Cancellations"            = "6"
        "General Customer Enquiry" = "7"
    }
    $subjectValue = $subjectMap[$Subject]

    # Define the form data
    $formData = @{
        "subject"                    = $subjectValue
        "name"                       = $Name
        "telephone"                  = $Telephone
        "email"                      = $Email
        "message"                    = $Message
        "spamcheck"                  = (Get-Date).DayOfWeek.ToString()
        "__RequestVerificationToken" = "CfDJ8HeYB27BdFtIqnCSmzScI8Ib9Yg0I1Ld1nV7WvjWBwWqoasnEEEo-kcWaIHQEzwp6Gpq2lfB77Ekec7sxZZOx_7-RimbMpuTk53M7JZf0e6uq2SXdvUYGHtEvyltfMei-BXeGR6Lgi1fhddJ4UgcKI"  # Include this hidden field
    }

    # Send the HTTP POST request
    $response = Invoke-WebRequest -Uri $formActionUrl -Method POST -Body $formData -ContentType "application/x-www-form-urlencoded"

    # Output the response status code
    Write-Output "Response Status Code: $($response.StatusCode)"

    # Check for specific success response
    if ($response.Content -eq "true") {
        Write-Output "Form submission was successful."
    }
    else {
        Write-Output "Form submission may have failed. Please check the response content for more details."
    }

    # Output the response content for further inspection
    Write-Output "Response Content: $($response.Content)"
}


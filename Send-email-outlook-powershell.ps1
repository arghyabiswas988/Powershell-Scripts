# Path to the CSV file
$csvPath = "C:\Temp\Data.csv"

# Read the CSV file
$usernames = Import-Csv -Path $csvPath

# Loop through each username and send an email
foreach ($user in $usernames) {
    $username = $user.Username

    try {
        # Create an Outlook application object
        $Outlook = New-Object -ComObject Outlook.Application

        # Create a new mail item
        $Mail = $Outlook.CreateItem(0)

        # Set the properties of the mail item
        $Mail.Subject = "Test Email with HTML Body"
        $Mail.To = "<EMAIL>"

        # Set the body format to HTML
        $Mail.BodyFormat = 2

        # Define the HTML content with Aptos font, font size 15, and dark blue color for the entire email
        $htmlBody = @"
        <html>
        <head>
            <style>
                body { font-family: 'Aptos', Arial, sans-serif; color: #2F5496; font-size: 15px; }  /* Apply to entire email */
                h1 { font-size: 15px; }  /* Ensure header matches body font size */
                p { margin: 0; padding: 0; margin-bottom: 15px; }  /* Remove margin and padding from paragraphs */
                .signature p { margin-bottom: 0; }  /* Remove extra space in the signature */
                .signature { margin-top: 20px; }
                .line1 { color: #797979; }  /* Red color for the first line */
                .line2 { color: #FF6F18; }  /* orange color for the second line */
                .line3 { color: #0070C0; }  /* Royal Blue color for the third line */
                .line4 { color: #0070C0; }  /* Royal Blue color for the fourth line */
                .line5 { color: #0070C0; }  /* Royal Blue color for the fifth line */
                .line6 { color: #797979; }  /* Grey color for the sixth line */
                .line7 { color: #797979; }  /* Grey color for the seventh line */
            </style>
        </head>
        <body>
            <h1>Hi <USER>,</h1>
            <p>“App” has been packaged and ready for UAT. Once ready please deploy to USER.</p>
            <p></p>
            <p>Application Location: </p>
            <p></p>
            <p>@Could you please share your device name with Mrinmoy.</p>
            <p></p>
            <p>Best regards,</p>
            <div class="signature">
                <p class="line1">--</p>
                <p class="line2">Arghya Biswas</p>
                <p class="line3">Application Packager (Windows Devices)</p>
                <p class="line4">Digital Workplace</p>
                <p class="line5">Enterprise IT</p>
                <p class="line6">+44 (0) 2081863491</p>
                <p class="line7">Upcoming Annual Leave:</p>
            </div>
        </body>
        </html>
"@

        # Set the HTML body
        $Mail.HTMLBody = $htmlBody

        # Send the email
        $Mail.Send()
        Write-Output "Email sent successfully to $username."
    } catch {
        Write-Error "Failed to send email to $username. Error: $_"
    }
}

# ================================================================
# Active Directory Bulk User Creation Script
# ================================================================
# Description: This script automates the creation of Active Directory
#              user accounts by reading a list of names from a text
#              file and provisioning each one as a domain user inside
#              a specified Organizational Unit (OU).
#
# How to use:
#   1. Edit the variables in the configuration section below
#   2. Make sure your names .txt file is in the same folder as this script
#   3. Run this script in PowerShell as a Domain Administrator on the DC
#
# Names file format: one full name per line, first and last separated by a space
#   Example:
#       John Smith
#       Sarah Connor
#       Bruce Wayne
# ================================================================


# ----------------------------------------------------------------
# CONFIGURATION — Edit these variables for your own use case
# ----------------------------------------------------------------

# The default password assigned to every newly created user account.
# Users should be prompted to change this on first login in a real environment.
$PASSWORD_FOR_USERS = "Password3"

# Reads the list of names from a .txt file located in the same directory
# as this script. Replace the filename with your own names file.
# Each line in the file should contain one full name: "Firstname Lastname"
$USER_FIRST_LAST_LIST = Get-Content .\Salesnames.txt

# Replace "Salesnames.txt" with your own file name depending on the OU
# you are creating users for. For example:
#   .\ITnames.txt    → for the IT OU
#   .\HRnames.txt    → for the HR OU
#   .\Salesnames.txt → for the Sales OU

# ----------------------------------------------------------------


# Converts the plain text password into a SecureString object.
# Active Directory requires passwords in this format for security —
# it cannot accept plain text strings directly.
$password = ConvertTo-SecureString $PASSWORD_FOR_USERS -AsPlainText -Force

# Creates a new Organizational Unit (OU) in Active Directory.
# Replace "Sales" with the name of the OU you want to create
# (e.g. "IT" or "HR" depending on which department you are provisioning).
# ProtectedFromAccidentalDeletion is set to $false so the OU can be
# deleted easily in a lab environment without needing extra steps.
New-ADOrganizationalUnit -Name "Sales" -ProtectedFromAccidentalDeletion $false

# ----------------------------------------------------------------
# MAIN LOOP — Iterates through every name in the text file
# ----------------------------------------------------------------

foreach ($n in $USER_FIRST_LAST_LIST) {

    # Splits each line into two parts using the space as a separator.
    # Index [0] is the first name, index [1] is the last name.
    # .ToLower() converts everything to lowercase for consistency.
    $first = $n.Split(" ")[0].ToLower()
    $last  = $n.Split(" ")[1].ToLower()

    # Builds the username by combining the first letter of the first name
    # with the full last name — all in lowercase.
    # Example: "John Smith" becomes "jsmith"
    $username = "$($first.Substring(0,1))$($last)".ToLower()

    # Prints a confirmation message to the console for each user being created
    # so you can follow the progress as the script runs.
    Write-Host "Creating user: $($username)" -BackgroundColor Black -ForegroundColor Cyan

    # Creates the Active Directory user account with the following attributes:
    New-AdUser `
        -AccountPassword $password `      # Assigns the secure password defined above
        -GivenName $first `               # First name
        -Surname $last `                  # Last name
        -DisplayName $username `          # Display name shown in ADUC
        -Name $username `                 # Account name (e.g. jsmith)
        -EmployeeID $username `           # Employee ID set to match the username
        -PasswordNeverExpires $true `     # Fine for a lab — disable this in production
        -Path "ou=Sales,$(([ADSI]`"").distinguishedName)" ` 
        # ^ Places the user inside the target OU within the domain.
        #   Replace "Sales" with your OU name (e.g. "IT" or "HR").
        #   ([ADSI]"").distinguishedName dynamically fetches the domain's
        #   Distinguished Name (e.g. DC=mydomain,DC=com) so you don't
        #   have to hardcode it — the script works on any domain automatically.
        -Enabled $true                    # Activates the account immediately
}

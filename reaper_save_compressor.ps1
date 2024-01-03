Add-Type -AssemblyName System.windows.forms

# Function to display a folder selection dialog
function Select-FolderDialog {
    param([string]$Description = "Select a folder", [string]$RootFolder = "Desktop")

    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.rootFolder = $RootFolder
    $folderBrowser.ShowDialog() | Out-Null
    return $folderBrowser.SelectedPath
}

# Function to find the 7-Zip executable path
function Find-7ZipPath {
    # Define default 7-Zip paths
    $defaultPaths = @("C:\Program Files\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe")

    # Get the script's own path to store/find the 7z path file
    $scriptPath = $PSScriptRoot
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
    $savedPathFile = Join-Path $scriptPath "$scriptName`_7z_path.txt"

    # Check if the saved 7-Zip path file exists and read from it
    if (Test-Path $savedPathFile) {
        $savedPath = Get-Content $savedPathFile
        if (Test-Path $savedPath) {
            return $savedPath
        }
    }

    # Search for 7-Zip in default installation paths
    foreach ($path in $defaultPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # If not found, prompt user to select 7-Zip folder and save the selection
    $7zipPath = Select-FolderDialog -Description "Select the folder where 7z.exe is located"
    $fullPath = Join-Path $7zipPath "7z.exe"
    if (Test-Path $fullPath) {
        Set-Content $savedPathFile -Value $fullPath
        return $fullPath
    } else {
        Write-Host "7z.exe not found in the selected directory."
        exit
    }
}

# Function to confirm whether to encrypt the archive
function Confirm-Encryption {
    $confirmBox = New-Object System.Windows.Forms.Form
    $confirmBox.Text = "Encryption"
    $confirmBox.Size = New-Object System.Drawing.Size(300, 150)
    $confirmBox.StartPosition = "CenterScreen"

    $confirmLabel = New-Object System.Windows.Forms.Label
    $confirmLabel.Text = "Would you like to encrypt the archive?"
    $confirmLabel.Location = New-Object System.Drawing.Point(10, 20)
    $confirmLabel.Size = New-Object System.Drawing.Size(280, 20)

    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(10, 70)
    $yesButton.Size = New-Object System.Drawing.Size(75, 23)
    $yesButton.Text = "Yes"
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $confirmBox.AcceptButton = $yesButton

    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(155, 70)
    $noButton.Size = New-Object System.Drawing.Size(75, 23)
    $noButton.Text = "No"
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No

    $confirmBox.Controls.Add($confirmLabel)
    $confirmBox.Controls.Add($yesButton)
    $confirmBox.Controls.Add($noButton)

    $confirmBox.Topmost = $true

    $result = $confirmBox.ShowDialog()

    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# Function to securely get the encryption password from the user
function Get-Password {
    # Function to generate a random 30-character alphanumeric password
    function Generate-RandomPassword {
        $charSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        $random = New-Object System.Random
        $password = -join (1..30 | ForEach-Object { $charSet[$random.Next(0, $charSet.Length)] })
        return $password
    }

    # Create password input form
    $passwordBox = New-Object System.Windows.Forms.Form
    $passwordBox.Text = "Enter Password"
    $passwordBox.Size = New-Object System.Drawing.Size(300, 150)
    $passwordBox.StartPosition = "CenterScreen"

    # Password label
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(10, 20)
    $passwordLabel.Size = New-Object System.Drawing.Size(280, 20)

    # Password input field
    $passwordInput = New-Object System.Windows.Forms.TextBox
    $passwordInput.Location = New-Object System.Drawing.Point(10, 40)
    $passwordInput.Size = New-Object System.Drawing.Size(220, 20)
    $passwordInput.UseSystemPasswordChar = $true

    # OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(10, 70)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $passwordBox.AcceptButton = $okButton

    # Generate password button
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Location = New-Object System.Drawing.Point(155, 70)
    $generateButton.Size = New-Object System.Drawing.Size(75, 23)
    $generateButton.Text = "Generate"
    $generateButton.Add_Click({
        $generatedPassword = Generate-RandomPassword
        $passwordInput.Text = $generatedPassword
        [System.Windows.Forms.Clipboard]::SetText($generatedPassword)

        # Display a temporary label indicating the password was copied
        $copiedLabel = New-Object System.Windows.Forms.Label
        $copiedLabel.Location = New-Object System.Drawing.Point(10, 100)
        $copiedLabel.Size = New-Object System.Drawing.Size(280, 23)
        $copiedLabel.Text = "Password copied to clipboard"
        $passwordBox.Controls.Add($copiedLabel)

        # Set a timer to remove the label after a few seconds
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 3000 # 3 seconds
        $timer.Add_Tick({
            $passwordBox.Controls.Remove($copiedLabel)
            $timer.Stop()
        })
        $timer.Start()
    })

    # Add controls to the form
    $passwordBox.Controls.Add($passwordLabel)
    $passwordBox.Controls.Add($passwordInput)
    $passwordBox.Controls.Add($okButton)
    $passwordBox.Controls.Add($generateButton)

    $passwordBox.Topmost = $true

    # Show dialog and return result
    $result = $passwordBox.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $passwordInput.Text
    } else {
        return $null
    }
}


# Function to check for .rpp files in the selected directory
function Test-ReaperSaveExists ($folderPath) {
    # Use Get-ChildItem to search for .rpp files recursively
    return (Get-ChildItem -Path $folderPath -Recurse -Filter "*.rpp" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
}

# Function to calculate the size of a directory or file
function Get-SizeInMB {
    param($path)
    $bytes = (Get-ChildItem $path -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum
    return [math]::Round($bytes / 1MB, 2)
}

### Main script execution starts here
# Find the 7-Zip executable path
$7zipPath = Find-7ZipPath
if (-not (Test-Path $7zipPath)) {
    [System.Windows.Forms.MessageBox]::Show("7z.exe not found. Please install 7-Zip.", "Error")
    exit
}

# Prompt user to select a directory to archive
$folderToArchive = Select-FolderDialog -Description "Select a directory to archive"
if ([string]::IsNullOrWhiteSpace($folderToArchive)) {
    [System.Windows.Forms.MessageBox]::Show("Nothing was entered.", "Error")
    exit
}
if (-not (Test-ReaperSaveExists $folderToArchive)) {
    [System.Windows.Forms.MessageBox]::Show("No .rpp files found in the selected directory.", "Error")
    exit
}

# Confirm whether to encrypt the archive
$encrypt = Confirm-Encryption
$password = $null
if ($encrypt) {
    $password = Get-Password
    if (-not $password) {
        exit
    }
}

# Prepare the archive name based on the parent folder
$parentFolderName = Split-Path -Path $folderToArchive -Leaf
$archiveName = [IO.Path]::Combine($folderToArchive, "$parentFolderName`_archive.7z")
$7zipArgs = "a", "`"$archiveName`"", "`"$folderToArchive\*`""


# Add password and file name encryption to 7-Zip arguments if encryption is needed
if ($encrypt -and $password) {
    $7zipArgs += "-p$password"
    $7zipArgs += "-mhe=on"
}

# Execute 7-Zip command
$dirSizeBefore = Get-SizeInMB -path $folderToArchive
& $7zipPath $7zipArgs

# Check if 7-Zip command executed successfully
if ($?) {
    $archiveSize = Get-SizeInMB -path $archiveName
    $message = "Folder archived successfully. `n`nDirectory size before: $dirSizeBefore MB`nArchive size after: $archiveSize MB `n`nNow opening the folder containing the archive: $archiveName"
    [System.Windows.Forms.MessageBox]::Show($message, "Success")
} else {
    [System.Windows.Forms.MessageBox]::Show("Failed to archive the folder.", "Error")
}

# Open the folder containing the archive
Invoke-Item $folderToArchive

# End of script
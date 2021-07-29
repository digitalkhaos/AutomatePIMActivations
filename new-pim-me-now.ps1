$accounts = @(
    ("John PInchin", "johnd@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "Global Reader", 8 ),
    ("John Bulletproof", "john.devito@bulletproofsoc.com", "9a63d138-53ea-411b-be84-58b7e2570747", "Global Reader", 8)
)

$sysCheck = 0
$Error.Clear()

if (Get-Module -ListAvailable -Name AzureADPreview) 
{
    $sysCheck = 1
} 
else 
{
    Write-Host "Module does not exist"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    $sysCheck = 1
}

if($sysCheck -eq 1)
{ 
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'PimMeNow!'
    $form.Size = New-Object System.Drawing.Size(580, 500)
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font("opensans", 9, [System.Drawing.FontStyle]::bold)

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(150, 360)
    $OKButton.Size = New-Object System.Drawing.Size(75, 23)
    $OKButton.Height = 50
    $OKButton.Width = 120
    $OKButton.Text = 'Cancel'
    $OKButton.Text = 'OK'
    $OKButton.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    $OKButton.Add_Click(
    {    
        $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
        $TenantID =  $accounts[$listBox.SelectedIndex][2].ToString()
        $role =  $accounts[$listBox.SelectedIndex][3].ToString()
        $duration =  $accounts[$listBox.SelectedIndex][4].ToString()    

        if($admin.Length -ne 0 -and $textBox.Text.Length -ne 0)
        {
            Import-Module azureadpreview
            Connect-AzureAD -AccountId $admin
            $oid = Get-AzureADUser -ObjectId $admin
            
            $roleToAssign=Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantID | Where-Object{$_.displayname -like $role}

            $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
            $schedule.Type = "Once"
            $durationString = "PT" + $duration + "H" 
            $schedule.Duration = $durationString
            $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

            Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TenantID -RoleDefinitionId $roleToAssign.id -SubjectId $oid.objectID -Type 'UserAdd' -AssignmentState 'Active' -reason "security monitoring" -Schedule $schedule 

            disconnect-azuread
        }
    }
    )

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(300, 360)
    $CancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $CancelButton.Height = 50
    $CancelButton.Width = 120
    $CancelButton.Text = 'Cancel'
    $CancelButton.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 30)
    $label.Size = New-Object System.Drawing.Size(280, 30)
    $label.Text = 'Select an Account:'
    $form.Controls.Add($label)
 
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 60)
    $listBox.Size = New-Object System.Drawing.Size(420, 10)
    $listBox.Height = 200
    $listBox.Width = 545
    $listBox.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($listBox)
 
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 270)
    $label2.Size = New-Object System.Drawing.Size(280, 30)
    $label2.Text = 'Justification:'

    foreach($key in $accounts) 
    {    
        [void] $listBox.Items.Add($key[0].Tostring())
    }

    $listBox.SetSelected(0,$true)
    $listBox.add_SelectedIndexChanged({$textBox.Focus()})
    $form.Controls.Add($label2)
}

 $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
 $duration =  $accounts[$listBox.SelectedIndex][5].ToString()   

 $counterlabel = New-Object 'System.Windows.Forms.Label'
 $counterlabel.AutoSize = $True
 $counterlabel.Font = 'Open Sans, 24pt, style=Bold'
 $counterlabel.Location = '5, 55'
 $counterlabel.Name = 'label000000'
 $counterlabel.Size = '208, 46'
 $counterlabel.TabIndex = 0
 $duration = $duration -as [int]
 $counterlabel.Text = $duration * 60
 $form.controls.Add($counterlabel)

 $form.controls.Remove($LinkLabel)
 $form.controls.Remove($listBox)
 $form.controls.Remove($OKButton)
 $form.controls.Remove($CancelButton)
 $form.Controls.Remove($label2)
 $form.Controls.Remove($textBox)
 $form.Size = New-Object System.Drawing.Size(235, 150)
 $form.Font = New-Object System.Drawing.Font("opensans", 9, [System.Drawing.FontStyle]::Regular)

 $label.Size =  New-Object System.Drawing.Size(195, 40) 
 $label.Location = New-Object System.Drawing.Point(10, 20)
 $label.text = "Minutes until " + $admin + " gets deactivated:"
 $CancelButton.Location = New-Object System.Drawing.Point(0, 30)

 function CountDown 
 {
    $isNumeric = $counterlabel.Text -match '^\d+$'

    if($isNumeric -eq $true)
    {
        $counterlabel.Text -= 1
        If ($counterlabel.Text -eq 0) 
        {
            $timer.Stop()
            $counterlabel.Text = "Deactivated!"
        } 
    }
 }

$timer=New-Object System.Windows.Forms.Timer
$timer.Interval=60000
$timer.add_Tick({CountDown})
$timer.Start()    

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)

if (!(Test-Path "errors.txt"))
{
    New-Item -path errors.txt -type "file" 
}
if($Error.count -ne 0)
{
    $date = get-date
    $sessionData = "Admin: " + $admin + " | TenantID: " + $TenantID + " | Profile: " + $edgeProfile + " | Pim-Role: " + $role + " | Duration: " +$duration 
    Add-Content -path errors.txt -value $date
    Add-Content -path errors.txt -value $sessionData
    Add-Content -path errors.txt -value $Error
}
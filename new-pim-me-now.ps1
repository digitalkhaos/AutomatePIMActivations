
# Your PIM Profiles
$accounts = @(
    ("John PInchin", "johnd@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "Global Reader", 8 ),
    ("John PInchin", "johnd@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "Security Reader", 8 ),
    ("John Bulletproof", "john.devito@bulletproofsoc.com", "9a63d138-53ea-411b-be84-58b7e2570747", "Global Reader", 8)

    # add pim account: name of profile, accountname, tenantID, profile-number edge, pim role, duration in hours
    #("Jule Sec admin","jule@100pcloud.com","bf830bb0-fb9g-4081-9a9c-53859bc1dc97","Profile 5","security administrator",2), #default
    #("Jule MSX admin","jule@100pcloud.com","bf8xxxxxxxxxxxxxxxxxxxxxxxxdc97","Profile 5","Exchange administrator",2), 
    #("AdmLab GA","administrator@100pcloud.com","bf8xxxxxxxxxxxxxxxxxxxxxxxxc97","Profile 4","security administrator",2)
)

#initialzation
$systemCheck = 0
$Error.Clear()

# Check if PIM PS Module exists - if not install it
if (Get-Module -ListAvailable -Name AzureADPreview) 
{
    $systemCheck = 1
} 
else 
{
    Write-Host "Module does not exist...installing"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    $systemCheck = 1
    Write-Host "Done."
}

# check if we are ready
if($systemCheck -eq 1)
{  
    foreach($account in $accounts) {
        
        # connect to PIM
        $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
        $TenantID =  $accounts[$listBox.SelectedIndex][2].ToString()
        $role =  $accounts[$listBox.SelectedIndex][3].ToString()
        $duration =  $accounts[$listBox.SelectedIndex][4].ToString()    


        # connect to azuread
        Write-Host "Connecting..."
        Import-Module azureadpreview

        Connect-AzureAD -AccountId $admin
        $oid = Get-AzureADUser -ObjectId $admin
                    
        # find roleassignment
        $roleToAssign = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantID | Where-Object{ $_.displayname -like $role }

        # prepare activation
        $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
        $schedule.Type = "Once"
        $durationString = "PT" + $duration + "H" 
        $schedule.Duration = $durationString
        $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

        # activate your role
        Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TenantID -RoleDefinitionId $roleToAssign.id -SubjectId $oid.objectID -Type 'UserAdd' -AssignmentState 'Active' -reason 'Security Monitoring' -Schedule $schedule 

        # disconnect azuread
        disconnect-azuread
    }
}

<#
 # listbox items
 $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
 $duration =  $accounts[$listBox.SelectedIndex][4].ToString()   

 # counter label
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

 # rebuild form for counter
 $form.controls.Remove($LinkLabel)
 $form.controls.Remove($listBox)
 $form.controls.Remove($OKButton)
 $form.controls.Remove($CancelButton)
 $form.Controls.Remove($label2)
 $form.Controls.Remove($textBox)
 $form.Size = New-Object System.Drawing.Size(235,150)
 $form.Font = New-Object System.Drawing.Font("opensans",9,[System.Drawing.FontStyle]::Regular)

 # reset label for counter
 $label.Size =  New-Object System.Drawing.Size(195,40) 
 $label.Location = New-Object System.Drawing.Point(10,20)
 $label.text = "Minutes until " + $admin + " gets deactivated:"
 $CancelButton.Location = New-Object System.Drawing.Point(0,30)

 # Pim Duration Counter
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

# Countdown is decreased every second
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000
$timer.add_Tick({CountDown})
$timer.Start()    

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)
#>

# error log
if (!(Test-Path "errors.txt"))
{
    New-Item -path errors.txt -type "file" 
}
if($Error.count -ne 0)
{
    $date = get-date
    # add session data
    $sessionData = "Admin: " + $admin + " | TenantID: " + $TenantID + " | Pim-Role: " + $role + " | Duration: " +$duration 
    Add-Content -path errors.txt -value $date
    Add-Content -path errors.txt -value $sessionData
    Add-Content -path errors.txt -value $Error
}
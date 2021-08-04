$accounts = @(
    ("John PInchin", "johnd@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "Global Reader", 8 ),
    ("John Bulletproof", "john.devito@bulletproofsoc.com", "9a63d138-53ea-411b-be84-58b7e2570747", "Global Reader", 8)
)

$check = 0
$Error.Clear()

if (Get-Module -ListAvailable -Name AzureADPreview) 
{
    $check = 1
} 
else 
{
    Write-Host "Module does not exist"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    $check = 1
}

if($check -eq 1)
{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Size = New-Object System.Drawing.Size(580, 500)
    $mainForm.Text = 'Bulletproof Auto-Pim'
    $mainForm.StartPosition = 'CenterScreen'
    $mainForm.Font = New-Object System.Drawing.Font("opensans", 9, [System.Drawing.FontStyle]::bold)

    $OKBtn = New-Object System.Windows.Forms.Button
    $OKBtn.Location = New-Object System.Drawing.Point(150, 360)
    $OKBtn.Size = New-Object System.Drawing.Size(75, 23)
    $OKBtn.Height = 50
    $OKBtn.Width = 120
    $OKBtn.Text = 'Cancel'
    $OKBtn.Text = 'OK'
    $OKBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $OKBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $mainForm.AcceptButton = $OKBtn
    $mainForm.Controls.Add($OKBtn)
 
    $OKBtn.Add_Click(
    {    
        $adm =  $accounts[$listBox.SelectedIndex][1].ToString()
        $TenantID =  $accounts[$listBox.SelectedIndex][2].ToString()
        $role =  $accounts[$listBox.SelectedIndex][3].ToString()
        $duration =  $accounts[$listBox.SelectedIndex][4].ToString()    

        if($adm.Length -ne 0)
        {
            Import-Module azureadpreview
            Connect-AzureAD -AccountId $adm
            $oid = Get-AzureADUser -ObjectId $adm
            $roleAssigned = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantID | Where-Object{$_.displayname -like $role}

            # prepare activation
            $sched = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedsched
            $sched.Type = "Once"
            $durationString = "PT" + $duration + "H" 
            $sched.Duration = $durationString
            $sched.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

            # activate your role
            Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TenantID -RoleDefinitionId $roleAssigned.id -SubjectId $oid.objectID -Type 'UserAdd' -AssignmentState 'Active' -reason 'security monitoring' -sched $sched 

            disconnect-azuread
        }
    }
    )

    $CancelBtn = New-Object System.Windows.Forms.Button
    $CancelBtn.Location = New-Object System.Drawing.Point(300, 360)
    $CancelBtn.Size = New-Object System.Drawing.Size(75, 23)
    $CancelBtn.Height = 50
    $CancelBtn.Width = 120
    $CancelBtn.Text = 'Cancel'
    $CancelBtn.Font = New-Object System.Drawing.Font("opensans",10,[System.Drawing.FontStyle]::bold)
    $CancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $mainForm.CancelBtn = $CancelBtn
    $mainForm.Controls.Add($CancelBtn)

    $lbl = New-Object System.Windows.Forms.lbl
    $lbl.Location = New-Object System.Drawing.Point(10, 30)
    $lbl.Size = New-Object System.Drawing.Size(280, 30)
    $lbl.Text = 'Account:'
    $mainForm.Controls.Add($lbl)

    # Listbox with account / tenant pairs
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 60)
    $listBox.Size = New-Object System.Drawing.Size(420, 10)
    $listBox.Height = 200
    $listBox.Width = 545
    $listBox.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::Regular)
    $mainForm.Controls.Add($listBox)

    # add items to listbox
    foreach ($key in $accounts) 
    {    
        [void] $listBox.Items.Add($key[0].Tostring())
    }

    # preselect listbox
    $listBox.SetSelected(0, $true)
    $mainForm.Controls.Add($lbl2)

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()
}

# error log
if (!(Test-Path "errors.txt"))
{
    New-Item -path errors.txt -type "file" 
}
if($Error.count -ne 0)
{
    $date = get-date
    # add session data
    $sessionData = "adm: " + $adm + " | TenantID: " + $TenantID + " |  Pim-Role: " + $role + " | Duration: " +$duration 
    Add-Content -path errors.txt -value $date
    Add-Content -path errors.txt -value $sessionData
    Add-Content -path errors.txt -value $Error
}
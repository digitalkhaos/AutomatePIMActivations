<#
    Bulletproof AUTO PIMs                  
    by john 

    TODO: Add all tenants
    TODO:  
#>

$tenants = @(
    ("Pinchin", "soc-john@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "32d3f793-2252-46d3-9f5f-26274c2f342d"),
    ("Bulletproof", "john.devito@bulletproofsoc.com", "9a63d138-53ea-411b-be84-58b7e2570747", "32d3f793-2252-46d3-9f5f-26274c2f342d")
)

if (Get-Module -ListAvailable -Name AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule)
{
    $readyCheck = 1
} 
else 
{
    Write-Host "Module does not exist"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    $readyCheck = 1
}
    
if($readyCheck -eq 1)
{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Size = New-Object System.Drawing.Size(400, 800)
    $mainForm.Text = 'Bulletproof Auto-PIM'
    $mainForm.StartPosition = 'CenterScreen'
    $mainForm.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)

    $activateBtn = New-Object System.Windows.Forms.Button
    $activateBtn.Location = New-Object System.Drawing.Point(50, 670)
    $activateBtn.Size = New-Object System.Drawing.Size(75, 23)
    $activateBtn.Height = 50
    $activateBtn.Width = 120
    $activateBtn.Text = 'Cancel'
    $activateBtn.Text = 'Activate'
    $activateBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainForm.Controls.Add($activateBtn)

    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.endDateTime = "2021-09-01T04:59:59.770Z"

    $activateBtn.Add_Click({ 
        $tenantName = $tenants[$tenantListBox.SelectedIndex][0].ToString()   
        $adm =  $tenants[$tenantListBox.SelectedIndex][1].ToString()
        $tenantID =  $tenants[$tenantListBox.SelectedIndex][2].ToString()
        $objectID =  $tenants[$tenantListBox.SelectedIndex][3].ToString()    

        $txtBox.Text = "Connected to: $tenantName as $adm`n" 

        Connect-AzureAD

        Get-AzureADMSPrivilegedRoleAssignment -ProviderID aadRoles -ResourceID "9a63d138-53ea-411b-be84-58b7e2570747" -Filter "subjectId eq '32d3f793-2252-46d3-9f5f-26274c2f342d'" | Write-Host

        Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId '9a63d138-53ea-411b-be84-58b7e2570747' -RoleDefinitionId 'f2ef992c-3afb-46b9-b7cf-a126ee74c451' -SubjectId '32d3f793-2252-46d3-9f5f-26274c2f342d' -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"

    }
    )
    
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Location = New-Object System.Drawing.Point(200, 670)
    $cancelBtn.Size = New-Object System.Drawing.Size(75, 23)
    $cancelBtn.Height = 50
    $cancelBtn.Width = 120
    $cancelBtn.Text = 'Cancel'
    $cancelBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $mainForm.CancelButton = $cancelBtn
    $mainForm.Controls.Add($cancelBtn)

    $lbl = New-Object System.Windows.Forms.label
    $lbl.Location = New-Object System.Drawing.Point(10, 30)
    $lbl.Size = New-Object System.Drawing.Size(280, 30)
    $lbl.Text = 'Tenant:'
    $mainForm.Controls.Add($lbl)

    # tenantListBox with account / tenant pairs
    $tenantListBox = New-Object System.Windows.Forms.ListBox
    $tenantListBox.Location = New-Object System.Drawing.Point(10, 60)
    $tenantListBox.Size = New-Object System.Drawing.Size(420, 10)
    $tenantListBox.Height = 285
    $tenantListBox.Width = 360
    $tenantListBox.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::Regular)
    $mainForm.Controls.Add($tenantListBox)

    # add items to tenantListBox
    foreach ($item in $tenants) 
    {    
         [void] $tenantListBox.Items.Add($item[0].Tostring())
    }

    # preselect tenantListBox
    $tenantListBox.SetSelected(0, $true)
    $mainForm.Controls.Add($lbl2)

    $txtBox = New-Object System.Windows.Forms.TextBox
    $txtBox.Location = New-Object System.Drawing.Point(10, 360)
    $txtBox.Size = New-Object System.Drawing.Size(420, 10)
    $txtBox.Multiline = $true
    $txtBox.Height = 285
    $txtBox.Width = 360
    $txtBox.ReadOnly = $true
    $mainForm.Controls.Add($txtBox)

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()  
}

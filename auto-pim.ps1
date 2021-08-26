<#
    Bulletproof AUTO PIMs                  
    by john 

    TODO: Add all tenants
    TODO:  
#>

$tenants = @(
    ("Pinchin", "soc-john@pinchin.com", "c4516901-933c-4b63-9f4b-69df48749dbb", "32d3f793-2252-46d3-9f5f-26274c2f342d"),
    ("Bulletproof", "john.devito@bulletproofsoc.com", "9a63d138-53ea-411b-be84-58b7e2570747", "adff98f3-fe9d-45c3-a53c-05769a2669fb")
)

$check = 0
$Error.Clear()

if (Get-Module -ListAvailable -Name AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule)
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
    $mainForm.Size = New-Object System.Drawing.Size(400, 800)
    $mainForm.Text = 'Bulletproof Auto-PIM'
    $mainForm.StartPosition = 'CenterScreen'
    $mainForm.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)

    $ActivateButton = New-Object System.Windows.Forms.Button
    $ActivateButton.Location = New-Object System.Drawing.Point(50, 670)
    $ActivateButton.Size = New-Object System.Drawing.Size(75, 23)
    $ActivateButton.Height = 50
    $ActivateButton.Width = 120
    $ActivateButton.Text = 'Cancel'
    $ActivateButton.Text = 'Activate'
    $ActivateButton.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    #$ActivateButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    #$mainForm.AcceptButton = $ActivateButton
    $mainForm.Controls.Add($ActivateButton)

    $ActivateButton.Add_Click({ 
        $TenantName = $tenants[$tenantListBox.SelectedIndex][0].ToString()   
        $adm =  $tenants[$tenantListBox.SelectedIndex][1].ToString()
        $TenantID =  $tenants[$tenantListBox.SelectedIndex][2].ToString()
        $ObjectID =  $tenants[$tenantListBox.SelectedIndex][3].ToString()    

        $txt.Text = "value of adm: $adm`n" 
        $FilterOn = "subjectId eq $ObjectID"

        $cred = Get-Credential
        Connect-AzureAD -Credential $cred

        Get-AzureADMSPrivilegedRoleAssignment -ProviderID aadRoles -ResourceID $TenantID  -Filter $FilterOn | Write-Host

        $txt.AppendText("Connected to $TenantName")
        
        
    }
    )
    
    $CancelBtn = New-Object System.Windows.Forms.Button
    $CancelBtn.Location = New-Object System.Drawing.Point(200, 670)
    $CancelBtn.Size = New-Object System.Drawing.Size(75, 23)
    $CancelBtn.Height = 50
    $CancelBtn.Width = 120
    $CancelBtn.Text = 'Cancel'
    $CancelBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $CancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $mainForm.CancelButton = $CancelBtn
    $mainForm.Controls.Add($CancelBtn)

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

    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(10, 360)
    $txt.Size = New-Object System.Drawing.Size(420, 10)
    $txt.Multiline = $true
    $txt.Height = 285
    $txt.Width = 360
    $txt.ReadOnly = $true
    $mainForm.Controls.Add($txt)

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()  
}

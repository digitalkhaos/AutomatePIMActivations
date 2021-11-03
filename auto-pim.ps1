<#
    Bulletproof AUTO PIMs                  
    by bulletprood soc

    TODO: requires statements
    TODO:  

    $GLobalReaderRole = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
    $SecurityReaderRole = '5d6b6bb7-de71-4623-b4af-96380a352509'
    $SecurityAdministratorRole = '194ae4cb-b126-40b2-bd5b-6091b380977d'
    $HelpdeskAdministratorRole = '729827e3-9c14-49f7-bb1b-9608f156bbb8'

#>
#Requires -Version 5.0
#Requires -Modules AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule


if (Get-Module -ListAvailable -Name AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule)
{
    Import-Module AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule
    $readyCheck = 1
} 
else 
{
    Write-Host "Module does not exist"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    Import-Module -Name AzureADPreview, Microsoft.Azure.ActiveDirectory.PIM.PSModule
    $readyCheck = 1
}

# ("Name", "TenantID, "ObjectID", "AccountID")
$tenants = @(
    ("Pinchin", "c4516901-933c-4b63-9f4b-69df48749dbb", "adff98f3-fe9d-45c3-a53c-05769a2669fb", "soc-john@pinchin.com"),
    ("Bulletproof", "9a63d138-53ea-411b-be84-58b7e2570747", "32d3f793-2252-46d3-9f5f-26274c2f342d", "john.devito@bulletproofsoc.com"),
    ("Colliers", "049e3382-8cdc-477b-9317-951b04689668","db71a9ec-c370-4d04-b2ca-0d6cf6d3c900", "soc-john.devito@colliers.onmicrosoft.com"),
    ("Gaming Labs", "00ba7ca4-fc6d-4d83-b18b-1460659aa27f","5ba8696a-a998-4372-965a-21966b0dc478", "soc-john.devito@gaminglabs.com"),
    ("OSCO", "0ee60ac4-5059-4f1c-857c-a9c4d2daab23","bc7973ad-6fb2-44c3-adff-bdea73d933e1", "soc-john@oscoit.com"),
    ("Saint Johns", "aea3b21f-bb9b-4220-aad8-be4853beaa41","622c239c-ab5e-4562-8438-b731ffb078de", "soc-john.devito@saintjohn.ca"),
    ("Barrington", "cad398a2-a2cb-4b5a-937d-b3272385c40f","1213b785-60ba-40e8-a9bb-0697223f7b08", "soc-john.devito@barringtongrp.ca"),
    ("CAA Atlantic", "081df473-6051-4752-b907-0771955b2fb5","13e5c075-c1ba-4f6a-baef-d0a9828c0aec", "soc-john.devito@caaatlantic310.onmicrosoft.com"),
    ("Engineering", "e36e2432-b327-457a-bb91-2c778cfcb631","c44bb9d7-6b80-4e67-b595-51074a9b6686", "soc-john.devito@colliersengineering.com")
    ("Project Leaders", "e74c4d20-b67d-4981-8c32-09fbc95f970f", "ad355bf5-7cfe-4a48-a5b5-de3955584f1a", "soc-john.devito@colliersprojectleaders.com"),
    ("Colliers Test", "32fde73e-d008-4c64-9dae-3c75284e7b02","7850aa40-21be-416e-b06a-a0bf3eef6b34", "soc-john.devito@collierstest.com"),
    ("Cupe", "e96558c0-737b-417b-94e6-c6e2afe5b005","2b001a87-d0af-452d-8ccc-3211967d7251", "soc-john.devito@cupe.onmicrosoft.com"),
    ("Edmunton", "ec76ae32-319a-4ab8-8520-b711c24b9a50","151360bc-b1f1-4a47-a2cc-3f26daa7e28d", "soc-john.devito@edmundston.ca"),
    ("Trevali", "239d993c-3c12-4070-b892-0a39e3e0a0a3","d268bc73-2781-4153-b229-5e4c6301956e", "soc-john.devito@trevali.com"),
    ("Uni", "a86d09ed-c313-4200-a4db-ae6b219e5bae","d04d0d2c-0777-4452-8fca-af5374b3cc04", "soc-john.devito@uni365.ca"),
    ("Loundsbury", "79f89a32-1845-41a8-bb88-0b2490a71c14","fd6ad5b4-2485-43dd-8dff-791b44f4c336", "spc-johnd@lounsburygroup.onmicrosoft.com"),
    ("Larco", "5c75effe-0780-49d7-99be-5e9e23c75d81","2f82634b-0f40-4fa8-9f55-1109f04c061a", "soc-johnd@mlpm1.ca"),
    ("Wilson", "6fca3bf6-4214-454c-9b03-329295b56cbc","ffdf575e-74bb-4357-9569-3c525dad87a9", "soc-johnd@wilson.nb.ca")
)
    
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
    $activateBtn.Text = 'Activate'
    $activateBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainForm.Controls.Add($activateBtn)

    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.Duration = "PT8H"

    $activateBtn.Add_Click({ 
        $tenantName = $tenants[$tenantListBox.SelectedIndex][0].ToString()   
        $tenantID =  $tenants[$tenantListBox.SelectedIndex][1].ToString()
        $objectID =  $tenants[$tenantListBox.SelectedIndex][2].ToString()
        $accountID = $tenants[$tenantListBox.SelectedIndex][3].ToString()   
        #$userID = "`'" + $objectID + "`'"
        
        $GlobalReaderFlag = 0
        $SecurityAdministratorFlag = 0
        $HelpdeskAdministratorFlag = 0

        $txtBox.Text = "Connecting to: $tenantName`r`n" 
        
        try{
            Connect-AzureAD -TenantID $tenantID -AccountID $accountID
            $txtBox.Text += "Connected to $tenantName`r`n"
        }
        catch{
            $txtBox.Text += "Failed to connect to $tenantName`r`n"
            $txtBox.Text += "Please check your credentials and try again`r`n"
            return
        }

        try{
            $GlobalReaderRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Global Reader'}
            $txtBox.Text += "`r`nGlobal Reader Available`r`n"
            $GlobalReaderFlag = 1
        }
        catch{
            $txtBox.Text += "`r`nGlobal Reader not available`r`n"
            $GlobalReaderFlag = 0
        }
        
        try{
            $SecurityAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Security Administrator'}
            $txtBox.Text += "`r`nSecurity Administrator Available`r`n"
            $SecurityAdministratorFlag = 1
        }
        catch{
            $txtBox.Text += "`r`nSecurity Administrator not available`r`n"
            $SecurityAdministratorFlag = 0
        }

        try{
            $HelpdeskAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Helpdesk Administrator'}
            $txtBox.Text += "`r`nHelpdesk Administrator Available`r`n"
            $HelpdeskAdministratorFlag = 1
        }
        catch{
            $txtBox.Text += "`r`nHelpdesk Administrator not available`r`n"
            $HelpdeskAdministratorFlag = 0
        }

        if($GlobalReaderFlag -eq 1){
            try{
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $GlobalReaderRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`n`r`nActivated Global Reader `r`n"
            }
            catch{
                $txtBox.Text += "`r`nFailed to activate Global Reader Role`r`n"
            }
        }
        else {
            $txtBox.Text += "`r`nGlobal Reader Role Not Found`r`n"
            return
        }
    
        if($SecurityAdministratorFlag -eq 1){
            try{
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $SecurityAdministratorRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`nActivated Security Administrator Role`r`n"
            }
            catch {
                $txtBox.Text += "`r`nFailed to activate Security Administrator Role`r`n"
            }
        }
        else {
            $txtBox.Text += "`r`nSecurity Administrator Role Not Found`r`n"
            return
        }

        if($HelpdeskAdministratorFlag -eq 1){
            try{
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $HelpDeskAdministratorRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`nActivated Helpdesk Administrator Role`r`n"
            }
            catch{
                $txtBox.Text += "`r`nFailed to activate Helpdesk Administrator Role`r`n"
            }
        }
        else {
            $txtBox.Text += "`r`nHelpdesk Administrator Role Not Found`r`n"
            return
        }
    })
    
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
         $tenantListBox.Items.Add($item[0].Tostring())
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
    $txtBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $mainForm.Controls.Add($txtBox)

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()  
}

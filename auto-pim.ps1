<#
    Bulletproof AUTO PIMs                  
    by bulletprood soc.......
#>

#Requires -Version 5.0
$GlobalReaderFlag = $false
$SecurityAdministratorFlag = $false
$HelpdeskAdministratorFlag = $false
$ADPreviewFlag = $false
$PIMModuleFlag = $false

try{
    Import-Module -Name PowerShellGet
    $initflag = $true
}
catch{
    Write-Host "This script requires the PowerShellGet module. Installing..."

    try{
        Install-Module -Name PowerShellGet -Force
        Write-Host "`r`nInstalling...`r`n"
        $initflag = $true
    }
    catch{
        Write-Host "Could not install PowerShellGet"
        $initflag = $false
    }
}

if($initflag -eq $true){
    try { 
        Import-Module -Name AzureADPreview
        $ADPreviewFlag = $true
    }
    catch { 
        Write-Host "Installing Module: AzureADPreview"
        #Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -scope currentuser -force"
        Install-Module -Name AzureADPreview -Scope CurrentUser -Force
        Import-Module -Name AzureADPreview
        $ADPreviewFlag = $true
    }
    try {
        Import-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule
        $PIMModuleFlag = $true
    } 
    catch {
        Write-Host "Installing Module: Microsoft.Azure.ActiveDirectory.PIM.PSModule"
        #Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module Microsoft.Azure.ActiveDirectory.PIM.PSModule -force"
        Install-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule -Force -Scope CurrentUser
        Import-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule
        $PIMModuleFlag = $true
    }
}
if(($ADPreviewFlag) -eq $true -and ($PIMModuleFlag -eq $true)) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Size = New-Object System.Drawing.Size(400, 800)
    $mainForm.Text = 'Bulletproof Auto-PIM'
    $mainForm.StartPosition = 'CenterScreen'
    $mainForm.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainForm.FormBorderStyle = 'FixedSingle'

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

    $pimconfig = Get-Content "C:\Users\bsi534\Sentinel Repo\Sentinel\SOC Tools\Auto-PIM\pim-config.json" | Out-String | ConvertFrom-Json

    $activateBtn.Add_Click({ 
        $tenantName = $pimconfig.tenants[$tenantListBox.SelectedIndex].name  
        $tenantID = $pimconfig.tenants[$tenantListBox.SelectedIndex].tenantID
        $objectID = $pimconfig.tenants[$tenantListBox.SelectedIndex].objectID
        $accountID = $pimconfig.tenants[$tenantListBox.SelectedIndex].accountID  
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
            $GlobalReaderFlag = $true
        }
        catch{
            $txtBox.Text += "`r`nGlobal Reader not available`r`n"
            $GlobalReaderFlag = $false
        }
        
        try{
            $SecurityAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Security Administrator'}
            $txtBox.Text += "`r`nSecurity Administrator Available`r`n"
            $SecurityAdministratorFlag = $true
        }
        catch{
            $txtBox.Text += "`r`nSecurity Administrator not available`r`n"
            $SecurityAdministratorFlag = $false
        }

        try{
            $HelpdeskAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Helpdesk Administrator'}
            $txtBox.Text += "`r`nHelpdesk Administrator Available`r`n"
            $HelpdeskAdministratorFlag = $true
        }
        catch {
            $txtBox.Text += "`r`nHelpdesk Administrator not available`r`n"
            $HelpdeskAdministratorFlag = $false
        }

        if($GlobalReaderFlag -eq 1){
            try {
                Start-Sleep -Milliseconds 250
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $GlobalReaderRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`n`r`nActivated Global Reader `r`n"
            }
            catch {
                $txtBox.Text += "`r`nFailed to activate Global Reader Role`r`n"
            }
        }
        else {
            $txtBox.Text += "`r`nGlobal Reader Role Not Found`r`n"
            return
        }
    
        if($SecurityAdministratorFlag -eq $true){
            try {
                Start-Sleep -Milliseconds 250
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

        if($HelpdeskAdministratorFlag -eq $true){
            try {
                Start-Sleep -Milliseconds 250
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $HelpDeskAdministratorRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`nActivated Helpdesk Administrator Role`r`n"
            }
            catch {
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

    #Activate All Button
    $ActivateAllBtn = New-Object System.Windows.Forms.Button
    $ActivateAllBtn.Location = New-Object System.Drawing.Point(130, 600)
    $ActivateAllBtn.Size = New-Object System.Drawing.Size(75, 23)
    $ActivateAllBtn.Height = 50
    $ActivateAllBtn.Width = 120
    $ActivateAllBtn.Text = 'Activate All'
    $ActivateAllBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainform.Controls.Add($ActivateAllBtn)

    $ActivateAllBtn.Add_Click({
        $pimconfig.tenants.foreach({
            $tenantName = $_.tenantName
            $tenantID = $_.tenantID
            $objectID = $_.objectID
            $accountID = $_.accountID
            $txtBox.Text += "Connecting to: $tenantName`r`n" 
            
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
                $GlobalReaderFlag = $true
            }
            catch{
                $txtBox.Text += "`r`nGlobal Reader not available`r`n"
                $GlobalReaderFlag = $false
            }
            
            try{
                $SecurityAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Security Administrator'}
                $txtBox.Text += "`r`nSecurity Administrator Available`r`n"
                $SecurityAdministratorFlag = $true
            }
            catch{
                $txtBox.Text += "`r`nSecurity Administrator not available`r`n"
                $SecurityAdministratorFlag = $false
            }

            try{
                $HelpdeskAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Helpdesk Administrator'}
                $txtBox.Text += "`r`nHelpdesk Administrator Available`r`n"
                $HelpdeskAdministratorFlag = $true
            }
            catch{
                $txtBox.Text += "`r`nHelpdesk Administrator not available`r`n"
                $HelpdeskAdministratorFlag = $false
            }
        })
    })

    $lbl = New-Object System.Windows.Forms.label
    $lbl.Location = New-Object System.Drawing.Point(10, 30)
    $lbl.Size = New-Object System.Drawing.Size(280, 30)
    $lbl.Text = 'Tenant:'
    $mainForm.Controls.Add($lbl)
    $tenantListBox = New-Object System.Windows.Forms.ListBox
    $tenantListBox.Location = New-Object System.Drawing.Point(10, 60)
    $tenantListBox.Size = New-Object System.Drawing.Size(420, 10)
    $tenantListBox.Height = 285
    $tenantListBox.Width = 360
    $tenantListBox.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::Regular)
    $mainForm.Controls.Add($tenantListBox)

    $pimconfig.tenants.forEach({
        $tenantListBox.Items.Add($_.name)
    })

    # preselect tenantListBox
    $tenantListBox.SetSelected(0, $true)

    $mainForm.Controls.Add($lbl2)
    $txtBox = New-Object System.Windows.Forms.TextBox
    $txtBox.Location = New-Object System.Drawing.Point(10, 360)
    $txtBox.Size = New-Object System.Drawing.Size(420, 10)
    $txtBox.Multiline = $true
    $txtBox.Height = 200
    $txtBox.Width = 360
    $txtBox.ReadOnly = $true
    $txtBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $mainForm.Controls.Add($txtBox)

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()  
}

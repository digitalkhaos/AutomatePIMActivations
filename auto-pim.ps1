<#
    Bulletproof AUTO PIMs                  
    by bulletprood soc.......
#>

#TODO: refactor comparing strings to use a hash table
#TODO: look into functions for PIM groups (ie OSCO)
#TODO: tenant specific 'reason' in schedule to activate PIM
#TODO: ability to override default 'reason' in schedule to activate PIM
#TODO: move tenantID into script (hardcode values)
#TODO: variabilize as much as possible

#Requires -Version 5.0
$GlobalReaderFlag = $false
$SecurityAdministratorFlag = $false
$HelpdeskAdministratorFlag = $false
$ADPreviewFlag = $false
$PIMModuleFlag = $false

$script_path = (Get-Location).Path
$auto_pim_config_file = "$script_path\pim-config.json"
$auto_pim_config = Get-Content $auto_pim_config_file | Out-String | ConvertFrom-Json
$auto_pim_log_file = $auto_pim_config.config.log_file

function log($string)
{
   write-host $string
   $TimeStamp = (Get-date -Format dd-MM-yyyy) + " @ " + (Get-Date -format HH:MM:sstt) 
   $TimeStamp + " -> " + $string | out-file -Filepath $auto_pim_log_file -append -Force
}

log "Auto PIM Script Started"

try{
    log "Checking for PowerShellGet..."
    Import-Module -Name PowerShellGet
    $PSGFlag = $true
    log "PowerShellGet found!"
}
catch{
    $PSGFlag = $false
    log "This script requires the PowerShellGet module to be installed: $($_.Exception.Message)"

    try{
        log "Attempting to install PowerShellGet..."
        Install-Module -Name PowerShellGet -Force
        $PSGFlag = $true
        log "PowerShellGet installed!"
    }
    catch{
        log "PowerShellGet installation failed: $($_.Exception.Message)"
        $PSGFlag = $false

            try{
                log "Attempting to install PowerShellGet..."
                Install-Module -Name PowerShellGet -Force -Source chocolatey
                $PSGFlag = $true
                log "PowerShellGet installed!"
            }
            catch{
                log "PowerShellGet installation failed: $($_.Exception.Message)"
                $PSGFlag = $false
            }
    }
}

if($PSGFlag -eq $true){
    try {
        log "Checking for AzureADPreview Module..." 
        Import-Module -Name AzureADPreview
        $ADPreviewFlag = $true
        log "AzureADPreview Module found"
    }
    catch { 
        log "AzureADPreview Module not found"
        $ADPreviewFlag = $false

        #install
        try {
            log "Attempting to install AzureADPreview Module..."
            Install-Module -Name AzureADPreview -Scope CurrentUser -Force
            $ADPreviewFlag = $true
        }
        catch {
            log "AzureADPreview Module installation failed: $($_.Exception.Message)"
            $ADPreviewFlag = $false
        }

        #import
        try {
            log "Checking for AzureADPreview Module..." 
            Import-Module -Name AzureADPreview
            $ADPreviewFlag = $true
            log "AzureADPreview Module found"
        }
        catch { 
            log "AzureADPreview Module not found"
            $ADPreviewFlag = $false
        }
    }
}

if($ADPreviewFlag -eq $true){
    try {
        log "Checking for PIM Module..."
        Import-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule
        $PIMModuleFlag = $true
        log "PIM Module found"
    } 
    catch {
        log "PIM Module not found"
        $PIMModuleFlag = $false
        
        #install
        try {
            log "Attempting to install PIM Module..."
            Install-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule -Scope CurrentUser -Force
            $PIMModuleFlag = $true
        }
        catch {
            log "PIM Module installation failed: $($_.Exception.Message)"
            $PIMModuleFlag = $false
        }

        #import
        try {
            log "Checking for PIM Module..."
            Import-Module -Name Microsoft.Azure.ActiveDirectory.PIM.PSModule
            $PIMModuleFlag = $true
            log "PIM Module found"
        }
        catch { 
            log "PIM Module not found"
            $PIMModuleFlag = $false
        }
    }
}

if(($PSGFlag) -eq $true -and  ($ADPreviewFlag) -eq $true -and ($PIMModuleFlag -eq $true)) {
    #draw main form
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Size = New-Object System.Drawing.Size(400, 800)
    $mainForm.Text = 'Bulletproof Auto-PIM'
    $mainForm.StartPosition = 'CenterScreen'
    $mainForm.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainForm.FormBorderStyle = 'FixedSingle'

    $txtBox = New-Object System.Windows.Forms.TextBox
    $txtBox.Location = New-Object System.Drawing.Point(10, 360)
    $txtBox.Size = New-Object System.Drawing.Size(420, 10)
    $txtBox.Multiline = $true
    $txtBox.Height = 200
    $txtBox.Width = 360
    $txtBox.ReadOnly = $true
    $txtBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $mainForm.Controls.Add($txtBox)

    #tenant listbox
    $mainForm.Controls.Add($lbl2)
    $tenantListBox = New-Object System.Windows.Forms.ListBox
    $tenantListBox.Location = New-Object System.Drawing.Point(10, 60)
    $tenantListBox.Size = New-Object System.Drawing.Size(420, 10)
    $tenantListBox.Height = 285
    $tenantListBox.Width = 360
    $tenantListBox.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::Regular)
    $mainForm.Controls.Add($tenantListBox)

    #Activate Button
    $activateBtn = New-Object System.Windows.Forms.Button
    $activateBtn.Location = New-Object System.Drawing.Point(50, 670)
    $activateBtn.Size = New-Object System.Drawing.Size(75, 23)
    $activateBtn.Height = 50
    $activateBtn.Width = 120
    $activateBtn.Text = 'Activate'
    $activateBtn.Font = New-Object System.Drawing.Font("opensans", 10, [System.Drawing.FontStyle]::bold)
    $mainForm.Controls.Add($activateBtn)

    #cancel button
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
    $mainForm.Controls.Add($ActivateAllBtn)

    #label
    $lbl = New-Object System.Windows.Forms.label
    $lbl.Location = New-Object System.Drawing.Point(10, 30)
    $lbl.Size = New-Object System.Drawing.Size(280, 30)
    $lbl.Text = 'Tenant:'
    #$mainForm.Controls.Add($lbl)

    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.Duration = "PT8H"

    try {
        log "Loading tenants"
        $auto_pim_config.tenants.forEach({
            $tenantListBox.Items.Add($_.name)
        })
        log "Tenants loaded"
    }
    catch {
        log "Failed to load tenants: $($_.Exception.Message)"
        $txtBox.Text += "`r`nFailed to load tenants`r`n"
        return
    }

    # preselect tenantListBox
    $tenantListBox.SetSelected(0, $true)

    $activateBtn.Add_Click({ 
        log "Activate button clicked"
        $tenantName = $auto_pim_config.tenants[$tenantListBox.SelectedIndex].name  
        $tenantID = $auto_pim_config.tenants[$tenantListBox.SelectedIndex].tenantID
        $objectID = $auto_pim_config.tenants[$tenantListBox.SelectedIndex].objectID
        $accountID = $auto_pim_config.tenants[$tenantListBox.SelectedIndex].accountID  
        
        try{
            <#
            # Get token for MS Graph by prompting for MFA
            $MsResponse = Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") -ClientId $tenantID -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Authority "https://login.microsoftonline.com/common" -Interactive -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}

            # Get token for AAD Graph
            $AadResponse = Get-MSALToken -Scopes @("https://graph.windows.net/.default") -ClientId $tenantID -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Authority "https://login.microsoftonline.com/common"
            #>

            Connect-AzureAD -TenantID $tenantID -AccountID $accountID
            #Connect-AzureAD -AadAccessToken $AadResponse.AccessToken -MsAccessToken $MsResponse.AccessToken -AccountId: $accountID -tenantId: $tenantID
            log "Connected to Azure AD: $($_.Exception.Message)"
            $txtBox.Text += "Connected to: $tenantName`r`n"
            # Connect-AzureAD -Credential $creds -Schedule $schedule -Reason: "Auto-PIM" -Force
        }
        catch{
            log "Error connecting to Azure AD: $($_.Exception.Message) $accountID : $tenantID "
            $txtBox.Text += "Failed to connect to $tenantName`r`n"
            $txtBox.Text += "Please check your credentials and try again`r`n"
            return
        }
        
        <#
        # Call cmdlet which requires MFA
        $resource = Get-AzureADMSPrivilegedResource -ProviderId AadRoles

        $roleDefinition = Get-AzureADMSPrivilegedRoleDefinition  -ProviderId AadRoles -ResourceId $resource.Id -Filter "DisplayName eq 'Global Reader'"

        $subject = Get-AzureADUser -Filter "userPrincipalName eq '$accountID'"

        $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
        $schedule.Type = "Once"
        $schedule.Duration="PT8H"
        $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

        Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AadRoles -Schedule $schedule -ResourceId $resource.Id -RoleDefinitionId $roleDefinition.Id -SubjectId $subject.ObjectId -AssignmentState "Active" -Type "UserAdd" -Reason "Test"
        #>

        try{
            log "Checking for Global Reader PIM..."
            $GlobalReaderRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Global Reader'}
            $txtBox.Text += "`r`nGlobal Reader Available`r`n"
            $GlobalReaderFlag = $true
            log "Global Reader PIM found"
        }
        catch{
            $txtBox.Text += "`r`nGlobal Reader not available`r`n"
            $GlobalReaderFlag = $false
            log "Global Reader PIM not found: $($_.Exception.Message)"
        }
        
        try{
            log "Checking for Security Administrator PIM..."
            $SecurityAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Security Administrator'}
            $txtBox.Text += "`r`nSecurity Administrator Available`r`n"
            $SecurityAdministratorFlag = $true
            log "Security Administrator PIM found"
        }
        catch{
            $txtBox.Text += "`r`nSecurity Administrator not available`r`n"
            $SecurityAdministratorFlag = $false
            log "Security Administrator PIM not found: $($_.Exception.Message)"
        }

        try{
            log "Checking for Helpdesk Administrator PIM..."
            $HelpdeskAdministratorRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantID | Where-Object {$_.DisplayName -eq 'Helpdesk Administrator'}
            $txtBox.Text += "`r`nHelpdesk Administrator Available`r`n"
            $HelpdeskAdministratorFlag = $true
            log "Helpdesk Administrator PIM found"
        }
        catch {
            $txtBox.Text += "`r`nHelpdesk Administrator not available`r`n"
            $HelpdeskAdministratorFlag = $false
            log "Helpdesk Administrator PIM not found: $($_.Exception.Message)"
        }

        if($GlobalReaderFlag -eq $true){
            try {
                Start-Sleep -Milliseconds 250
                log "Activating Global Reader PIM..."
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $GlobalReaderRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`n`r`nActivated Global Reader `r`n"
                log "Global Reader PIM activated"
            }
            catch {
                $txtBox.Text += "`r`nFailed to activate Global Reader Role`r`n"
                log "Failed to activate Global Reader PIM: $($_.Exception.Message)"
            }
        }
        else {
            $txtBox.Text += "`r`nGlobal Reader Role Not Found`r`n"
            log "Global Reader PIM not found"
            return
        }
    
        if($SecurityAdministratorFlag -eq $true){
            try {
                Start-Sleep -Milliseconds 250
                log "Activating Security Administrator PIM..."
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $SecurityAdministratorRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`nActivated Security Administrator Role`r`n"
                log "Security Administrator PIM activated"
            }
            catch {
                $txtBox.Text += "`r`nFailed to activate Security Administrator Role`r`n"
                log "Failed to activate Security Administrator PIM: $($_.Exception.Message)"
            }
        }
        else {
            $txtBox.Text += "`r`nSecurity Administrator Role Not Found`r`n"
            return
            log "Security Administrator PIM not found"
        }

        if($HelpdeskAdministratorFlag -eq $true){
            try {
                Start-Sleep -Milliseconds 250
                log "Activating Helpdesk Administrator PIM..."
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $tenantID -RoleDefinitionId $HelpDeskAdministratorRole.Id -SubjectId $objectID -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "security monitoring"
                $txtBox.Text += "`r`nActivated Helpdesk Administrator Role`r`n"
                log "Helpdesk Administrator PIM activated"
            }
            catch {
                $txtBox.Text += "`r`nFailed to activate Helpdesk Administrator Role`r`n"
                log "Failed to activate Helpdesk Administrator PIM: $($_.Exception.Message)"
            }
        }
        else {
            $txtBox.Text += "`r`nHelpdesk Administrator Role Not Found`r`n"
            log "Helpdesk Administrator PIM not found"
            return
        }
    })

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

    # bring up mainForm
    $mainForm.Add_Shown({$mainForm.Activate()})
    $mainForm.ShowDialog()
}


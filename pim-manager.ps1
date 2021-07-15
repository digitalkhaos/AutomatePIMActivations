<#
.Synopsis
   Enable or disable Priviledged role in Azure PIM
#.DESCRIPTION
   With this script you can enable or disable privileged role assignments
   You need to have the module Microsoft.Azure.ActiveDirectory.PIM.PSModule
   
   To get all active roles use this command Get-PrivilegedRoleAssignment |? {$_.IsElevated -eq $true -and $_.IsPermanent -eq $false}
#.EXAMPLE
   .\Enable-PIMrole.ps1 -pimroles 'Exchange Administrator','SharePoint Service Administrator', 'User Administrator' -ticketnumber "nvt" -reason "changes" -duration 8
   Enables roles Exchange Administrator, SharePoint Service Administrator and User Administrator
#.EXAMPLE
   .\Enable-PIMrole.ps1 -pimroles 'Exchange Administrator','SharePoint Service Administrator' -Disable
   Disable roles Exchange Administrator and SharePoint Service Administrator
#.EXAMPLE
   .\Enable-PIMrole.ps1 -DisableAll
   Disable all active roles
#>
<#
Param
(
    # What PIM role should be activated
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='Addrole')]
    [Parameter(ParameterSetName='Removerole')]
    [ValidateSet("Application Administrator","Application Developer","Billing Administrator","Cloud Application Administrator","Cloud Device Administrator","Compliance Administrator","Conditional Access Administrator","CRM Service Administrator","Customer LockBox Access Approver","Desktop Analytics Administrator","Device Administrators","Directory Readers","Directory Writers","Exchange Administrator","Global Administrator","Guest Inviter","Information Protection Administrator","Intune Service Administrator","License Administrator","Message Center Reader","Password Administrator","Power BI Service Administrator","Privileged Role Administrator","Reports Reader","Security Administrator","Security Reader","Service Administrator","SharePoint Service Administrator","Skype for Business Administrator","Teams Communications Administrator","Teams Communications Support Engineer","Teams Communications Support Specialist","Teams Service Administrator","User Administrator")]
    [string[]]$pimroles,

    # What is the ticketnumber
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='Addrole')]
    [string]$ticketnumber,

    # What is the reason for activating
    [Parameter(Mandatory=$true, Position=2, ParameterSetName='Addrole')]
    [string]$reason,

    # What is the duration for the activation.
    [Parameter(Mandatory=$true, Position=3, ParameterSetName='Addrole')]
    [int]$duration,

    # should we disable the role? Default is enable
    [Parameter(Mandatory=$true, ParameterSetName='Removerole')]
    [switch]$Disable,

    # should we remove all roles
    [Parameter(Mandatory=$true, ParameterSetName='RemoveAllroles')]
    [switch]$DisableAll
)

#check if we are connected to PIM
if([string]::IsNullOrEmpty((Show-PimServiceConnection).UserName))
{
    Connect-PimService
}

if($DisableAll)
{
    # Disable all roles
    Write-Host "Disabling all active roles"
    Get-PrivilegedRoleAssignment | Where-Object {$_.IsElevated -eq $true -and $_.IsPermanent -eq $false} | Disable-PrivilegedRoleAssignment
}
else
{
    foreach($pimrole in $pimroles)
    {
        $roleAssignment = $null
        $roleAssignment = Get-PrivilegedRoleAssignment | Where-Object {$_.RoleName -eq $pimrole}
        if([string]::IsNullOrEmpty($roleAssignment))
        {
            Write-Error -Message "Cannot find $pimrole for your account"
        }
        else
        {
            $roleid = $roleAssignment.RoleId
            if($Disable)
            {
                Write-Host "Disabling $pimrole"
                Disable-PrivilegedRoleAssignment -RoleId $roleid
            }
            else
            {
                Write-Host "Enabling $pimrole for $duration hours"
                Enable-PrivilegedRoleAssignment -TicketNumber $ticketnumber -Reason $reason -Duration $duration -RoleId $roleid
            }
        }
    }
}

#>




#get credential from user
#$AzureAdCred = Get-Credential
#Connect-AzureAD -Credential $AzureAdCred

#function showMenu {
#    cls
#    Write-Host "1: List Accounts to be logged into"
#    Write-Host "2: Add Account to be logged into"
#    Write-Host "3: Remove Account to be logged into"
#    Write-Host "4: execute script...LOGIN!"
#    Write-Host "x: Exit"
#    Write-Host
#}

<#
Function MenuMaker{
    param(
        [parameter(Mandatory=$true)][String[]]$Selections,
        [switch]$IncludeExit,
        [string]$Title = $null
        )

    $Width = if($Title){
        $Length = $Title.Length;
        $Length2 = $Selections|%{$_.length}|Sort -Descending|Select -First 1;
        $Length2,$Length|Sort -Descending|Select -First 1
        }
        else{
            $Selections|%{
                $_.length
                }
            
                |Sort -Descending|Select -First 1
            }

    $Buffer = if(($Width * 1.5) -gt 78){
        [math]::floor((78 - $width) / 2)
        }else{
            [math]::floor($width / 4)
        }

    if($Buffer -gt 6){
        $Buffer = 6
    }
    $MaxWidth = $Buffer * 2 + $Width + $($Selections.count).length + 2
    $Menu = @()
    $Menu += "╔"+"═"*$maxwidth+"╗"

    if($Title){
        $Menu += "║" + " " * [Math]::Floor(($maxwidth-$title.Length) / 2) + $Title+" "*[Math]::Ceiling(($maxwidth - $title.Length) / 2) + "║"
        $Menu += "╟" + "─" * $maxwidth + "╢"
    }
    For($i = 1; $i -le $Selections.count; $i++){
        $Item = "$(if ($Selections.count -gt 9 -and $i -lt 10){" "})$i`. "
        $Menu += "║"+" "*$Buffer+$Item+$Selections[$i-1]+" "*($MaxWidth-$Buffer-$Item.Length-$Selections[$i-1].Length)+"║"
    }
    If($IncludeExit){
        $Menu += "║"+" "*$MaxWidth+"║"
        $Menu += "║"+" "*$Buffer+"X - Exit"+" "*($MaxWidth-$Buffer-8)+"║"
    }
    $Menu += "╚"+"═"*$maxwidth+"╝"
    $menu
}
#>


Do {
    Clear-Host
    Write-Host "Wlecome to auto-login for Bulletproof.  A configuration file will hold your login information and automatically activate all of your roles."
    Write-Host

    #MenuMaker -Selections 'Show List of Accounts','Add Account to List', 'Remove Account from List' -Title 'Choose Option' -IncludeExit
    $Response = Read-Host "Enter Option"
} While($Response -notin 1,2,3,'x')

Switch($Response){
    1 {
        # List of Accounts
        Write-Host "List of current accounts:"
        Write-Host

        $stream_reader = New-Object System.IO.StreamReader{C:\Users\bsi534\login-info.txt}
        #This needs to be changed from hard coded
        $line_number = 1
        Write-Host

        While($null -ne ($current_line = $stream_reader.ReadLine()))
        {
            Write-Host "$line_number  $current_line"
            $line_number++
        }
    }

    2 {
        #Add account
        $AzureAdCred = Get-Credential 

        if ($null -ne $AzureAdCred) {
            
        }
        Add-Content C:\Users\bsi534\login-info.txt "\n" $AzureAdCred

        Write-Host "Account added"

         
    }

    3 {
        #remove account
        #go through each line matching the string wanting to be removed (must be exact)
        #$accountToRemove = Read-Host "Account to Remove"

    }
}































#get role information
#Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId 926d99e7-117c-4a6a-8031-0cc481e9da26
#Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId "926d99e7-117c-4a6a-8031-0cc481e9da26"
#Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId "926d99e7-117c-4a6a-8031-0cc481e9da26" -Filter "subjectId eq 'f7d1887c-7777-4ba3-ba3d-974488524a9d'"
#Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId "926d99e7-117c-4a6a-8031-0cc481e9da26" -Filter "roleDefinitionId eq '0bb54a22-a3df-4592-9dc7-9e1418f0f61c'"

#Activate role
#Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId '926d99e7-117c-4a6a-8031-0cc481e9da26' -RoleDefinitionId 'f55a9a68-f424-41b7-8bee-cee6a442d418' -SubjectId 'f7d1887c-7777-4ba3-ba3d-974488524a9d' -Type 'UserAdd' -AssignmentState 'Active' -schedule $schedule -reason "dsasdsas"

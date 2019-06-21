[CmdletBinding()]
param()

Import-Module ..\Az.AzureLabs.psm1 -Force

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$today      = (Get-Date).ToString()
$tomorrow   = (Get-Date).AddDays(1)
$end        = (Get-Date).AddMonths(4).ToString()

$rgName     = 'Acme'
$rgLocation = 'West Europe'
$labName    = 'Advancing Differenciation'
$laName     = 'Workshops'
$imgName    = 'CentOS-Based*'
$maxUsers   = 2
$usageQuota = 30
$usageAMode = 'Restricted'
$shPsswd    = $false
$size       = 'Medium'
$title      = 'Advancing Differenciation Workshop'
$descr      = 'Bringing it to the 21st Century'
$userName   = 'test0000'
$password   = 'Test00000000'
$linuxRdp   = $true
$emails     = @('lucabolg@gmail.com')
$invitation = "Please register to the $title"

$schedules  = @(
    [PSCustomObject]@{Frequency='Weekly';FromDate=$today;ToDate = $end;StartTime='10:00';EndTime='11:00';Notes='Theory'}
    [PSCustomObject]@{Frequency='Weekly';FromDate=$tomorrow;ToDate = $end;StartTime='11:00';EndTime='12:00';Notes='Practice'}
)

if(-not (Get-AzResourceGroup -ResourceGroupName $rgName -EA SilentlyContinue)) {
    New-AzResourceGroup -ResourceGroupName $rgName -Location $rgLocation | Out-null
    Write-Verbose "$rgname resource group didn't exist. Created it."
}

$la  = New-AzLabAccount -ResourceGroupName $rgName -LabAccountName $laName
Write-Verbose "$laName lab account created or found."

$img = $la | Get-AzLabAccountGalleryImage | Where-Object {$_.name -like $imgName}
if(-not $img -or $img.Count -ne 1) {Write-Error "$imgName not a valid image name."}
Write-Verbose "Image $imgName found."

$lab = $la | Get-AzLab -LabName $labName

if($lab) {
    $lab = $la `
        | New-AzLab -LabName $LabName -MaxUsers $maxUsers -UsageQuotaInHours $usageQuota -UserAccessMode $usageAMode -SharedPasswordEnabled:$shPsswd `
        | Publish-AzLab
    Write-Verbose "$LabName lab already exist. Republished."
} else {
    $lab = $la `
        | New-AzLab -LabName $LabName -MaxUsers $maxUsers -UsageQuotaInHours $usageQuota -UserAccessMode $usageAMode -SharedPasswordEnabled:$shPsswd `
        | New-AzLabTemplateVM -Image $img -Size $size -Title $title -Description $descr -UserName $userName -Password $password -LinuxRdpEnabled:$linuxRdp `
        | Publish-AzLab
    Write-Verbose "$LabName lab doesn't exist. Created it."
}

$lab | Add-AzLabUser -Emails $emails
$users = $lab | Get-AzLabUser
$users | ForEach-Object { $lab | Send-AzLabUserInvitationEmail -User $_ -InvitationText $invitation}
Write-Verbose "Added Users: $emails."

$schedules | ForEach-Object { $lab | New-AzLabSchedule $_}
Write-Verbose "Added all schedules."

Remove-Module Az.AzureLabs -Force
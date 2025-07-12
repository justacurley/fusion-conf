$SettingsPAge = New-UDApp -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User  
    # Homepage content for the Health Dashboard

}
# Return the settings app
$SettingsPage

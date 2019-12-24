# use this file to define global variables on module scope
# or perform other initialization procedures.

<# Validate running as admin
$admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if(!$admin){
    # Exit if not in Admin mode
    for($i=1;$i>=3;$i++){Write-Host "Please restart in admin mode!!!`n";Break;}
    Exit
}#>

# Load the initialization script
Import-Module $PSScriptRoot\loader.psm1 -Force
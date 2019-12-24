# LOADING ALL FUNCTION DEFINITIONS:


## Fetch libraries for import that aren't the base library
$libraries = $(Get-ChildItem $PSScriptRoot\libraries -Recurse -Include "*.psm1")

# Check for our libraries folder
if(!$(Test-Path -Path "$PSScriptRoot\libraries" -ErrorAction SilentlyContinue)){
    write_log "No libraries found to import!!! Moving on..." -other_log $this.LogFile
}else{
    $libraries | ForEach-Object {
        Import-Module "$($_.FullName)" -Force
    }
}
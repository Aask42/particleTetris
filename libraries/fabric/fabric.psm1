
class particleFabric
{
    $fabric_id = "{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999)
    $fabric_block_units = @{}

    [int32] $block_unit_id_counter = 0

    [int64] $tick_count = 0

    # Set default log location and filename
    $LogFolderPath = "$PSScriptRoot\logs"
    $LogFilePath = "$($this.LogFolderPath)\$($pid)`_particleFabric.log"

    particleFabric () {

    }

    [string] generate_new_block_unit () {
        $new_block = New-BlockUnit($this.block_unit_id_counter)
        $block_unit_id = "block_unit.$($new_block.block_unit)"

        $this.fabric_block_units += @{
            "$block_unit_id" = $new_block
        }

        $this.block_unit_id_counter += 1

        return $block_unit_id
    }

    [System.Management.Automation.PSObject] get_timestamp () {
        return Get-Date -UFormat '%s'
    }

    [System.Management.Automation.PSObject] write_log ($msg) {
        # Fetch the current time
        while(!(Test-Path $this.LogFolderPath)) {
            Write-Host("Creating new folder: $($this.LogFolderPath)...")

            New-Item $this.LogFolderPath -ItemType Directory -Force -Confirm:$false

            Write-Output "$($this.get_timestamp())`: Generated new logfile ^_^" | Out-File $this.LogFilePath -Append


            if($Error) {
                Write-Host("There were errors creating $($this.LogFolderPath), please investigate!!!")
                Write-Host($Error)
            }
        }

        $timestamp = $($this.get_timestamp())

        # Write-Host "$timestamp`: $msg"
        Write-Output "$timestamp`: $msg" | Out-File $this.LogFilePath -Append

        return $timestamp
    }

    [void] tick () {
        # This method will progress the arrow of time
        $this.tick_count += 1

    }
}

function New-ParticleFabric()
{
    ## This function will return a new block_unit object
    $particle_fabric = New-Object particleFabric

    return $particle_fabric
}

function Test-ParticleDrop() {
    $fabric = New-ParticleFabric

    $block_unit_id = $fabric.generate_new_block_unit()
    $run = $true
    while($run) {
        if($fabric.fabric_block_units.$block_unit_id.do_something("move_down") -eq 1) {
            Clear-Host
            $fabric.fabric_block_units.$block_unit_id.draw_block_unit()
            Start-Sleep -Milliseconds 500
        } else {
            $run = $false
        }
    }
}

function Test-ParticleMovement() {
    $fabric = New-ParticleFabric

    $block_unit_id = $fabric.generate_new_block_unit()

    $run = $true
    $key = $null
    while($run) {
        # Check to see if a key was pressed
        $action = $null

        $key = [System.Console]::ReadKey()

        switch($key.Key) {
            # Left key
            'LeftArrow' {
                $msg = "LEFT key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_left"
            }
            # Up key
            'UpArrow' {
                $msg = "UP key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_up"
            }
            # Right key
            'RightArrow' {
                $msg = "RIGHT key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_right"
            }
            # Down key
            'DownArrow' {
                $msg = "DOWN key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_down"
            }
            # X key
            'X' {
                $msg = "X key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "rotate_right"
            }
            # Z key
            'Z' {
                $msg = "Z key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "rotate_left"
            }
        }

        if($null -ne $action) {
            $fabric.fabric_block_units.$block_unit_id.do_something($action)
            Clear-Host
            $fabric.fabric_block_units.$block_unit_id.draw_block_unit()
            $key = $null
        }

        Start-Sleep -Milliseconds 1
    }
}

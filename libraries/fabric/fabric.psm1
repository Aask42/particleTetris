
class particleFabric
{
    $fabric_id = "{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999)
    $fabric_block_units = @{}

    [int32] $block_unit_id_counter = 0

    [int64] $tick_count = 0

    $particle_roster = @()

    # Set default log location and filename
    $LogFolderPath = "$PSScriptRoot\logs"
    $LogFilePath = "$($this.LogFolderPath)\$($pid)`_particleFabric.log"

    particleFabric () {
    }

    [string] generate_new_block_unit () {

        # Figure out if this is the active block or not
        $active = $true

        if ( $this.fabric_block_units.Keys | Where-Object { $this.fabric_block_units.$_.is_active } ) {
            $active = $false
        }

        $new_block = New-BlockUnit($this.block_unit_id_counter)

        $new_block.is_active = $active

        $new_block.on_deck = !$active

        $block_unit_id = "block_unit.$($new_block.block_unit)"

        $new_block.particle_roster = $this.particle_roster

        $this.fabric_block_units += @{
            "$block_unit_id" = $new_block
        }

        # Ensure this particle doesn't get the full roster until its siblings have been added
        $this.update_particle_roster()

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

    [void] draw_particles ($block_unit_object) {

        # Fetch our block unit data
        $block_unit = $block_unit_object

        # Create our dataset object from our dimensions
        $block_unit_particle_coordinates = New-Object 'switch[,]' $($block_unit.max_dimensions.x.Count + 1),$($block_unit.max_dimensions.y.Count + 1)

        foreach($particle in $block_unit.particle_dimensions.Keys){
            foreach($point in $block_unit.particle_dimensions.$particle) {
                $block_unit_particle_coordinates[($point.x),($point.y)] = $true
                $this.write_log("Particle located at $($point.x),$($point.y)")
            }
        }

        # Draw our piece
        $lines = @()

        foreach ($y_coord in $block_unit.max_dimensions.y) {
            $y_coord = $y_coord
            $line = @("|")
            foreach ($x_coord in $block_unit.max_dimensions.x) {
                $x_coord = $x_coord
                if ($block_unit_particle_coordinates[$x_coord,$y_coord] -eq $true) {
                    $line = "$line$($block_unit.piece_type[0])"
                } else {
                    $line = "$line "
                }
            }
            $line = "$line|"

            $lines += @($line)
        }

        $lines | ForEach-Object {Write-Host $_}
    }

    [void] update_particle_roster () {
        # Refresh our table of block_units
        $this.particle_roster = New-Object 'switch[,]' $($this.fabric_block_units.'block_unit.0'.max_dimensions.x[-1] + 1),$($this.fabric_block_units.'block_unit.0'.max_dimensions.y[-1] + 1)

        # Add all of our block units to the table
        foreach ( $block_unit_object in $this.fabric_block_units.Keys )  {

            $particle_dimensions = $this.fabric_block_units.$block_unit_object.particle_dimensions
            foreach($particle in $particle_dimensions.Keys){

                $datapoints = $particle_dimensions.$particle
                foreach ( $point in $datapoints ) {
                    $this.particle_roster[($point.x),($point.y)] = $true
                    $this.write_log("Particle located at $($point.x),$($point.y)")
                }
            }
        }

        $this.write_log("Updated particle roster ^_^")
    }

    [void] draw_particle_roster ($active_block) {

        # Draw our table of block_units
        $block_unit_base = $this.fabric_block_units.'block_unit.0'

        $full_particle_roster = $this.particle_roster

        foreach( $block_unit_object in $($this.fabric_block_units.Keys | Where-Object { $this.fabric_block_units.$_.is_active}) ) {

            $particle_dimensions = $block_unit_object.particle_dimensions
            foreach($particle in $particle_dimensions.Keys){

                $datapoints = $particle_dimensions.$particle
                foreach ( $point in $datapoints ) {
                    $full_particle_roster[($point.x),($point.y)] = $true
                }
            }
        }

        # Draw our piece
        $lines = @()

        foreach ($y_coord in $block_unit_base.max_dimensions.y) {
            $y_coord = $y_coord
            $line = @("|")
            foreach ($x_coord in $block_unit_base.max_dimensions.x) {
                $x_coord = $x_coord
                if ($full_particle_roster[$x_coord,$y_coord] -eq $true) {
                    $line = "$line`x"
                } else {
                    $line = "$line "
                }
            }
            $line = "$line|"

            $lines += @($line)
        }
        $lines | ForEach-Object {Write-Host $_}
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

    $fabric.draw_particles($fabric.fabric_block_units.$block_unit_id)

    $run = $true
    while($run) {
        if($fabric.fabric_block_units.$block_unit_id.do_something("move_down") -eq 1) {
            Clear-Host
            $fabric.draw_particles($fabric.fabric_block_units.$block_unit_id)
            Start-Sleep -Milliseconds 500
        } else {
            $run = $false
        }
    }
}

function Test-ParticleMovement() {

    $fabric = New-ParticleFabric

    $block_unit_id = $fabric.generate_new_block_unit()

    $fabric.draw_particles($fabric.fabric_block_units.$block_unit_id)

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
            # Up key
            'UpArrow' {
                $msg = "UP key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_up"
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

            $fabric.draw_particles($fabric.fabric_block_units.$block_unit_id)

            $key = $null
        }

        Start-Sleep -Milliseconds 1
    }
}

function Test-ParticleStacking() {
    $fabric = New-ParticleFabric

    $block_unit_id = $fabric.generate_new_block_unit()

    $fabric.draw_particle_roster()

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
            # Up key
            'UpArrow' {
                $msg = "UP key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $action = "move_up"
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
            'N' {
                $msg = "N key was pressed!"
                Write-Host $msg
                $fabric.write_log("$msg")
                $fabric.generate_new_block_unit()
            }
        }

        # We need to do something after setting the sibling_block_units variable
        if($null -ne $action) {

            $block_unit_id = $($fabric.fabric_block_units.Keys | Where-Object { $fabric.fabric_block_units.$_.is_active})

            $fabric.fabric_block_units.$block_unit_id.do_something($action)

            Clear-Host

            $fabric.draw_particle_roster($fabric.fabric_block_units.$block_unit_id)

            $key = $null
        }

        Start-Sleep -Milliseconds 1
    }
}

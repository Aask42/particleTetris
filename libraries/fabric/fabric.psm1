
class particleFabric
{
    $fabric_id = "{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999)
    $fabric_block_units = @{}

    [int] $block_unit_id_counter = 0
    [int] $current_block_unit = 0

    [int64] $tick_count = 0

    $particle_roster = @{}
    $active_particle_roster = @{}

    $current_time = 0

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

        if ( $active ) {
            $new_block.toggle_activity_state()
        }

        $new_block.on_deck = !$new_block.is_active

        $block_unit_id = "block_unit.$($new_block.block_unit)"

        $new_block.particle_roster = $this.particle_roster

        $this.fabric_block_units += @{
            "$block_unit_id" = $new_block
        }

        # Ensure this particle doesn't get the full roster until its siblings have been added
        $this.update_particle_roster()

        $this.block_unit_id_counter += 1

        Write-Host "`nGenerated new block_unit on-deck ^_^"

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

    [void] draw_particles ($block_unit_id) {

        # Fetch our block unit data
        $block_unit = $this.fabric_block_units.$block_unit_id

        # Create our dataset object from our dimensions
        $block_unit_particle_coordinates = New-Object 'switch[,]' $($block_unit.max_dimensions.x.Count + 1),$($block_unit.max_dimensions.y.Count + 1)

        foreach($particle in $block_unit.particle_dimensions.Keys){
            foreach($point in $block_unit.particle_dimensions.$particle) {
                $block_unit_particle_coordinates[($point.x),($point.y)] = $true
                $this.current_time = $this.write_log("Particle located at $($point.x),$($point.y)")
            }
        }

        # Draw our piece
        $lines = @()

        foreach ($y_coord in $block_unit.max_dimensions.y) {
            $y_coord = $y_coord
            $line = ""
            foreach ($x_coord in $block_unit.max_dimensions.x) {
                $x_coord = $x_coord
                if ($block_unit_particle_coordinates[$x_coord,$y_coord] -eq $true) {
                    $line = "$line$($block_unit.block_unit_type[0])"
                } else {
                    $line = "$line "
                }
            }
            $line = "|$line|"

            $lines += @($line)
        }

        $lines | ForEach-Object {Write-Host $_}
    }

    [void] update_particle_roster () {
        # Refresh our table of block_units
        $temp_particle_roster = @{}

        # Add all of our block units to the table
        foreach ( $block_unit in $this.fabric_block_units.Keys | Where-Object { !($this.fabric_block_units.$_.is_active)}) {

            $block_unit_object = $this.fabric_block_units.$block_unit

            foreach($particle in $block_unit_object.particle_dimensions.Keys){
                foreach ( $point in $block_unit_object.particle_dimensions.$particle ) {
                    $temp_particle_roster += @{
                        "$($point.x),$($point.y)" = "$($block_unit_object.block_unit_type)"
                    }
                }
            }
        }

        $this.particle_roster = $temp_particle_roster

        $this.current_time = $this.write_log("Updated particle roster ^_^")
    }

    [void] draw_particle_roster () {

        # Build the full particle roster to display
        [Console]::SetBufferSize(512,512)

        # Fetch the depth of the x dimension, and add one since our grid is actually starting @ position one,one
        $x_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.x[-1] + 1)

        # Fetch the depth of the y dimension, and add one since our grid is actually starting @ position one,one
        $y_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.y[-1] + 1)

        # Generate data object to store the roster of particles we are going to display
        $full_particle_roster = New-Object 'switch[,]' $x_dimension_depth,$y_dimension_depth
        $particle_type_roster = @{}

        # Add each set of particles from each block_unit to the full particle roster we're going to draw
        foreach ( $block_unit in $this.fabric_block_units.Keys ) {

            $block_unit_object = $this.fabric_block_units.$block_unit

            foreach($particle in $block_unit_object.particle_dimensions.Keys){
                foreach ( $point in $block_unit_object.particle_dimensions.$particle ) {
                    $particle_type_roster += @{
                        "$($point.x),$($point.y)" = "$($block_unit_object.block_unit_type)"
                    }
                    $full_particle_roster[($point.x),($point.y)] = $true
                }
            }
        }

        # Build the output lines based on the table of particle locations
        $lines = ""

        # Build the lines we want to display
        foreach ($y_coord in $this.fabric_block_units.'block_unit.0'.max_dimensions.y) {
            $line = ""
            foreach ($x_coord in $this.fabric_block_units.'block_unit.0'.max_dimensions.x) {
                # Fetch our particle_type_roster from the roster
                $block_unit_type = $particle_type_roster."$x_coord,$y_coord"

                if( $false -eq $full_particle_roster[$x_coord,$y_coord] ) {
                    $piece_symbol = " "
                } else {
                    $piece_symbol = "$($block_unit_type[0])"
                }

                # Add a piece symbol. Everyone loves piece.
                $line = "$line$($piece_symbol)"
            }
            # Add it to the list of lines
            $lines = "$lines`n|$line|"
        }

        # Display the lines
        [Console]::Write($lines)
    }
    [void] swap_active_block () {

        if ( $this.fabric_block_units.Count -gt 1 ) {

            $block_unit_id = "block_unit.$($this.current_block_unit)"

            [int] $temp_current_block_unit = $this.current_block_unit + 1

            if( $temp_current_block_unit -gt ($this.fabric_block_units.Count - 1) ) {
                $temp_current_block_unit = 0
            }

            $temp_block_unit_id = "block_unit.$temp_current_block_unit"

            $this.update_particle_roster()

            $full_roster = $this.particle_roster

            foreach($particle in $this.fabric_block_units.$block_unit_id.particle_dimensions.Keys){
                foreach ( $point in $this.fabric_block_units.$block_unit_id.particle_dimensions.$particle ) {
                    if ( !$full_roster."$($point.x),$($point.y)" ) {
                        $full_roster += @{
                            "$($point.x),$($point.y)" = "$($this.fabric_block_units.$block_unit_id.block_unit_type)"
                        }
                    }
                }
            }

            $this.fabric_block_units.$temp_block_unit_id.particle_roster = $full_roster

            if(!($this.fabric_block_units.$temp_block_unit_id.is_active)) {
                $active_block_unit = $($this.fabric_block_units.Keys | Where-Object { $this.fabric_block_units.$_.is_active})
                $toggle = $this.fabric_block_units.$temp_block_unit_id.toggle_activity_state()
                if ( ($null -ne $active_block_unit) -and $toggle ) {

                    # Deactivate any blocks in motion only after we've toggled another on successfully

                    $this.fabric_block_units.$active_block_unit.toggle_activity_state()

                    $this.write_log("Successfully added piece to the board from on_deck!")

                    $this.fabric_block_units.$active_block_unit.particle_roster = $this.particle_roster

                    $this.update_particle_roster()

                    $this.fabric_block_units.$temp_block_unit_id.particle_roster = $this.particle_roster

                    $this.current_block_unit = $temp_current_block_unit

                    Clear-Host

                    Write-Host("`nSuccessfully swapped active piece")

                    $this.draw_particle_roster()

                } else {
                    Write-Host("`nUnable to add piece to board from on-deck...")
                    $this.draw_particle_roster()
                }
            }
        }
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
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "move_left"
            }
            # Up key
            'UpArrow' {
                $msg = "UP key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "move_up"
            }
            # Right key
            'RightArrow' {
                $msg = "RIGHT key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "move_right"
            }
            # Down key
            'DownArrow' {
                $msg = "DOWN key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "move_down"
            }
            # Up key
            'UpArrow' {
                $msg = "UP key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "move_up"
            }
            # X key
            'X' {
                $msg = "X key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "rotate_right"
            }
            # Z key
            'Z' {
                $msg = "Z key was pressed!"
                Write-Host $msg
                $fabric.current_time = $fabric.write_log("$msg")
                $action = "rotate_left"
            }
        }

        if($null -ne $action) {

            $fabric.fabric_block_units.$block_unit_id.do_something($action)

            Clear-Host

            $fabric.draw_particles($fabric.fabric_block_units.$block_unit_id)

            $key = $null
        }

        # Start-Sleep -Milliseconds 1
    }
}

function Test-ParticleStacking() {
    $fabric = New-ParticleFabric

    $block_unit_id = $fabric.generate_new_block_unit()

    $fabric.draw_particle_roster()

    $run = $true
    $key = $null

    $current_block_unit = 0

    $block_unit_id = "block_unit.$current_block_unit"

    while($run) {
        # Check to see if a key was pressed
        $action = $null

        # If the key is not currently being held, detect key press
        if ( ([console]::KeyAvailable) ) {

            $key = [System.Console]::ReadKey()
            [System.Console]::Clear()

            switch($key.Key) {
                # Left key
                'LeftArrow' {
                    $fabric.current_time = $fabric.write_log("LEFT key was pressed!")
                    $action = "move_left"
                }
                # Up key
                'UpArrow' {
                    $fabric.current_time = $fabric.write_log("UP key was pressed!")
                    $action = "move_up"
                }
                # Right key
                'RightArrow' {
                    $fabric.current_time = $fabric.write_log("RIGHT key was pressed!")
                    $action = "move_right"
                }
                # Down key
                'DownArrow' {
                    $fabric.current_time = $fabric.write_log("DOWN key was pressed!")
                    $action = "move_down"
                }
                # Up key
                'UpArrow' {
                    $fabric.current_time = $fabric.write_log("UP key was pressed!")
                    $action = "move_up"
                }
                # X key
                'X' {
                    $fabric.current_time = $fabric.write_log("X key was pressed!")
                    $action = "rotate_right"
                }
                # Z key
                'Z' {
                    $fabric.current_time = $fabric.write_log("Z key was pressed!")
                    $action = "rotate_left"
                }
                'N' {
                    $fabric.current_time = $fabric.write_log("N key was pressed!")
                    $fabric.generate_new_block_unit()
                    $fabric.draw_particle_roster()
                }
                "S" {
                    $fabric.swap_active_block()
                }
                'Escape' {
                    $run = $false
                }
            }

            # We need to do something after setting the sibling_block_units variable
            if($null -ne $action) {

                # $block_unit_id = $($fabric.fabric_block_units.Keys | Where-Object { $fabric.fabric_block_units.$_.is_active})

                $block_unit_id = "block_unit.$($fabric.current_block_unit)"

                $fabric.update_particle_roster()

                $fabric.fabric_block_units.$block_unit_id.particle_roster = $fabric.particle_roster

                $fabric.fabric_block_units.$block_unit_id.do_something($action)

                $fabric.draw_particle_roster()
                # $fabric.fabric_block_units.$block_unit_id.print_block_unit_dimensions()

                $Host.UI.RawUI.FlushInputBuffer()
            }

            Start-Sleep -Milliseconds 5
        }

    }
    return $fabric
}


class particleFabric
{
    $fabric_id = "{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999)
    $fabric_block_units = @{}

    [int] $block_unit_id_counter = 0
    [int] $current_block_unit = 0

    [int64] $tick_count = 0

    $particle_roster = $null

    $full_particle_roster = $null
    $full_particle_roster_colors = $null
    $full_particle_roster_shape = $null
    $inactive_particle_roster = $null
    $active_particle_roster = $null

    $current_time = 0

    [bool] $auto_play = $false;

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

        $this.fabric_block_units += @{
            "$block_unit_id" = $new_block
        }

        # Ensure this particle doesn't get the full roster until its siblings have been added
        $this.update_particle_roster()

        $this.fabric_block_units.$block_unit_id.particle_roster = $this.inactive_particle_roster

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

        # Fetch the depth of the x dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.x[-1]
        $x_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.x[-1] + 2)

        # Fetch the depth of the y dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.y[-1]
        $y_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.y[-1] + 2)

        # Generate data object to store the roster of particles we are going to display
        $temp_full_particle_roster = New-Object 'switch[,]' $x_dimension_depth,$y_dimension_depth
        $temp_full_particle_roster_colors = New-Object 'string[,]' $x_dimension_depth,$y_dimension_depth
        $temp_full_particle_roster_shape = New-Object 'string[,]' $x_dimension_depth,$y_dimension_depth
        # Create our in/active particle roster
        $temp_inactive_particle_roster = New-Object 'switch[,]' $x_dimension_depth,$y_dimension_depth
        $temp_active_particle_roster = New-Object 'switch[,]' $x_dimension_depth,$y_dimension_depth
        $temp_particle_roster = @{}

        $active_color_background = 'Green'
        $active_color_foreground = 'Black'

        $inactive_color_background = 'Gray'
        $inactive_color_foreground = 'Black'
        $border_color_background = 'Cyan'
        $border_color_foreground = 'White'

        # Set the full border of the roster and its colors
        foreach ( $y in $(0..$($y_dimension_depth - 1)) ) {
            $temp_full_particle_roster_colors[0,$y] = "$border_color_background,$border_color_foreground"
            $temp_full_particle_roster_colors[$($x_dimension_depth - 1),$y] = "$border_color_background,$border_color_foreground"
            $temp_full_particle_roster_shape[0,$y] = ' '
            $temp_full_particle_roster_shape[$($x_dimension_depth - 1),$y] = ' '
            $temp_full_particle_roster[0,$y] = $true
            $temp_full_particle_roster[$($x_dimension_depth - 1),$y] = $true
            $temp_inactive_particle_roster[0,$y] = $true
            $temp_inactive_particle_roster[$($x_dimension_depth - 1),$y] = $true
        }
        # Set the full border of the roster and its colors
        foreach ( $x in $(0..$($x_dimension_depth - 1)) ) {
            $temp_full_particle_roster_colors[$x,0] = "$border_color_background,$border_color_foreground"
            $temp_full_particle_roster_colors[$x,$($y_dimension_depth - 1)] = "$border_color_background,$border_color_foreground"
            $temp_full_particle_roster_shape[$x,0] = ' '
            $temp_full_particle_roster_shape[$x,$($y_dimension_depth - 1)] = ' '
            $temp_full_particle_roster[$x,0] = $true
            $temp_full_particle_roster[$x,$($y_dimension_depth - 1)] = $true
            $temp_inactive_particle_roster[$x,0] = $true
            $temp_inactive_particle_roster[$x,$($y_dimension_depth - 1)] = $true
        }

        $num_of_particles = 0;
        foreach ( $block_unit in $this.fabric_block_units.Keys ) {
            foreach ( $particle in $this.fabric_block_units.$block_unit.particle_dimensions.Keys ) {
                # Make our coords
                $x = $($this.fabric_block_units.$block_unit.particle_dimensions.$particle.x)
                $y = $($this.fabric_block_units.$block_unit.particle_dimensions.$particle.y)

                # Set our shape
                $temp_full_particle_roster_shape[$x,$y] = $this.fabric_block_units.$block_unit.block_unit_type

                # Add coords to complete roster
                $temp_full_particle_roster[$x,$y] = $true

                # Set printout colors, and set particle in either in/active particle rosters
                if ( $this.fabric_block_units.$block_unit.is_active ) {
                    $active_color_background = $this.fabric_block_units.$block_unit.block_unit_colors.$($this.fabric_block_units.$block_unit.block_unit_type)
                    $temp_full_particle_roster_colors[$x,$y] = "$active_color_background,$active_color_foreground"
                    $temp_active_particle_roster[$x,$y] = $true
                } else {
                    $inactive_color_background = $this.fabric_block_units.$block_unit.block_unit_colors.$($this.fabric_block_units.$block_unit.block_unit_type)
                    $temp_full_particle_roster_colors[$x,$y] = "$inactive_color_background,$inactive_color_foreground"
                    $temp_inactive_particle_roster[$x,$y] = $true
                }
                $temp_particle_roster += @{
                    "$($this.fabric_block_units.$block_unit.block_unit).$particle" = @{
                        "x" = $x;
                        "y" = $y
                    }
                }
            }
        }

        $this.full_particle_roster = $temp_full_particle_roster
        $this.full_particle_roster_colors = $temp_full_particle_roster_colors
        $this.full_particle_roster_shape = $temp_full_particle_roster_shape
        $this.inactive_particle_roster = $temp_inactive_particle_roster
        $this.active_particle_roster = $temp_active_particle_roster
        $this.particle_roster = $temp_particle_roster

        $this.fabric_block_units."block_unit.$($this.current_block_unit)".particle_roster = $temp_inactive_particle_roster

        $this.current_time = $this.write_log("Updated particle roster ^_^")
    }

    [void] draw_particle_roster () {

        $this.update_particle_roster()

        # Fetch the depth of the x dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.x[-1]
        $x_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.x[-1] + 2)

        # Fetch the depth of the y dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.y[-1]
        $y_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.y[-1] + 2)

        # Loop through all grid spots and print out colors according to values in our hash tables
        Clear-Host
        foreach ( $y in $(0..$($y_dimension_depth - 1))) {
            foreach ( $x in $(0..$($x_dimension_depth - 1))) {
                if ( $this.full_particle_roster_colors[$x,$y] -ne $null ) {
                    [Console]::SetCursorPosition($x,$y)
                    $symbol = ' '# $this.full_particle_roster_shape[$x,$y][0]
                    $background_color = $this.full_particle_roster_colors[$x,$y].Split(",")[0]
                    $foreground_color = $this.full_particle_roster_colors[$x,$y].Split(",")[-1]
                    Write-Host "$symbol" -ForegroundColor $foreground_color -BackgroundColor $background_color -NoNewline
                }
            }
        }
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

            $this.fabric_block_units.$temp_block_unit_id.particle_roster = $this.inactive_particle_roster

            if(!($this.fabric_block_units.$temp_block_unit_id.is_active)) {
                $active_block_unit = $($this.fabric_block_units.Keys | Where-Object { $this.fabric_block_units.$_.is_active})
                $toggle = $this.fabric_block_units.$temp_block_unit_id.toggle_activity_state()
                if ( ($null -ne $active_block_unit) -and $toggle ) {

                    # Deactivate any blocks in motion only after we've toggled another on successfully

                    $this.fabric_block_units.$active_block_unit.toggle_activity_state()

                    $this.write_log("Successfully added piece to the board from on_deck!")

                    $this.current_block_unit = $temp_current_block_unit

                    $this.update_particle_roster()

                    $this.fabric_block_units.$temp_block_unit_id.particle_roster = $this.inactive_particle_roster

                    Clear-Host

                    $this.write_log("Successfully swapped active piece")

                    $this.draw_particle_roster()

                } else {
                    $this.write_log("Unable to add piece to board from on-deck...")
                    $this.draw_particle_roster()
                }
            }
        }
    }
        [void] clear_complete_lines () {

        # Fetch the depth of the x dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.x[-1]
        $x_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.x[-1] + 2)

        # Fetch the depth of the y dimension, and add TWO since our grid is actually starting @ position one,one and ending at max_dimensions.y[-1]
        $y_dimension_depth = $($this.fabric_block_units.'block_unit.0'.max_dimensions.y[-1] + 2)

        $y = 1
        $cleared_line = $false

        $particles_to_remove = @()
        $particles_to_move_down = @()

        while ($y -lt ($y_dimension_depth - 1)) {
            $row_particle_count = 0
            if($($this.particle_roster.values.y -eq $y).Count -eq 10){
                $this.write_log("Removing line in row $y!!!")
                $cleared_line = $true
                $temp_keys = $this.fabric_block_units.Keys
                 foreach($block_unit in $this.fabric_block_units.Keys) {
                    foreach($particle in $this.fabric_block_units.$block_unit.particle_dimensions.Keys) {
                        if($this.fabric_block_units.$block_unit.particle_dimensions.$particle.y -eq $y) {
                            $particles_to_remove += "$block_unit;$particle"
                        }
                        else {
                            if($this.fabric_block_units.$block_unit.particle_dimensions.$particle.y -lt $y){
                                $particles_to_move_down += "$block_unit;$particle"
                            }
                        }
                    }
                }
                foreach($ghost_particle in $particles_to_remove) {
                    $block_unit = $ghost_particle.Split(";")[0]
                    $particle = $ghost_particle.Split(";")[-1]
                    $this.remove_particle_from_block_unit($block_unit,$particle)
                }
                foreach($loose_particle in $particles_to_move_down) {
                    $block_unit = $loose_particle.Split(";")[0]
                    $particle = $loose_particle.Split(";")[-1]
                    $this.fabric_block_units.$block_unit.particle_dimensions.$particle.y += 1
                }
            }
            $y++
        }
        if( $cleared_line ) {
            $this.write_log( "Cleared completed lines ^_^" )
        }
    }

    [bool] remove_particle_from_block_unit ($block_unit_id, $particle) {

        if(!$this.fabric_block_units.$block_unit_id) {
            Write-Host "$block_unit_id doesn't exist...you sure that's the command you wanted to submit? \\(^_^)/"
            return 0
        }
        if(!$this.fabric_block_units.$block_unit_id.particle_dimensions.$particle) {
            Write-Host "$block_unit_id doesn't have that particle...you sure that's the command you wanted to submit? \\(^_^)/"
            return 0
        }
        $temp = $this.fabric_block_units.$block_unit_id.particle_dimensions
        $temp.Remove($particle)

        if($this.fabric_block_units.$block_unit_id.particle_dimensions.$particle) {
            return 0
        }
        $this.fabric_block_units.$block_unit_id.particle_dimensions = $temp
        return 1
    }

    [void] step_time_forward() {
        $this.current_time += 1
    }

    [void] step_time_forward($steps_to_take) {
        $i = 0
        while($i -le $steps_to_take) {
            $this.step_time_forward()
            $i++;
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

            # Clear our console
            [System.Console]::Clear()

            $fabric.current_time = $fabric.write_log("$key key was pressed!")

            $fabric.current_time = $fabric.write_log("$key key was pressed!")

            switch($key.Key) {
                # Left key
                'LeftArrow' { $action = "move_left" }
                # Up key
                'UpArrow' { $action = "move_up" }
                # Right key
                'RightArrow' { $action = "move_right" }
                # Down key
                'DownArrow' { $action = "move_down" }
                # X key
                'X' { $action = "rotate_left" }
                # Z key
                'Z' { $action = "rotate_right" }
                'N' {
                    $fabric.generate_new_block_unit()
                    $fabric.draw_particle_roster()
                }
                "S" { $fabric.swap_active_block() }
                "C" { $fabric.clear_complete_lines() }
                'Escape' { $run = $false }
            }

            # Now act on the active block unit
            if($null -ne $action) {

                $block_unit_id = "block_unit.$($fabric.current_block_unit)"

                $do_something = $fabric.fabric_block_units.$block_unit_id.do_something($action)

            }
            $fabric.draw_particle_roster()

            $Host.UI.RawUI.FlushInputBuffer()
            # Start-Sleep -Milliseconds 1
        }

    }
    return $fabric
}

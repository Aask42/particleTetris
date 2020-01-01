class blockUnit
{
    # Set a unique name for this block
    $block_unit = $("{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999))

    # Default to inactive, because this piece by default should generate in an "on_deck" state
    $is_active = $false
    $on_deck = $true

    # Set the max playground size
    $max_dimensions = @{
        "x" = (1..10)
        "y" = (1..20)
    }

    $center = $($this.max_dimensions.x[-1] / 2)

    # Set allowed piece types
    $block_unit_types = $null

    $particle_dimensions = $null
    $particle_roster = $(New-Object 'switch[,]' $($this.max_dimensions.x[-1] + 1),$($this.max_dimensions.y[-1] + 1))

    $block_unit_successfully_did_something = $false

    $piece_initial_shape = @()
    [string] $block_unit_type = $null

    [int] $rotation_angle = 90 # This is the angle each piece rotates with a call of the rotate method
    [int] $number_of_orientations = $(360 / $this.rotation_angle) # A circle has 360 degrees, this lets us know the max piece orientations possible
    [int] $piece_orientation = 0 # Max is dynamically calculated based off of the number of orientations possible

    # Set default log location and filename
    $LogFolderPath = "$PSScriptRoot\logs"
    $LogFilePath = "$($this.LogFolderPath)\$($pid)`_particleTetris.log"

    blockUnit ()
    {
        # Let's start some block_unit things! Like what kind of block is this?
        $this.write_log("Generating new block_unit type...")

        # Set the allowed pieces and their size

        $this.set_block_unit_types()

        # Randomize piece generation
        $pick_a_number = Get-Random -Minimum 0 -Maximum $($this.block_unit_types.Keys.Count - 1)

        $this.block_unit_type = $(@($this.block_unit_types.Keys)[$pick_a_number])

        $this.write_log("Generated block_unit with the block_unit_type of $($this.block_unit_type) ^_^")
    }

    [bool] do_something ([string] $action) {

        $status = 0

        $this.block_unit_successfully_did_something = $false

        # Validate this is the active piece

        if ( $this.is_active -eq $false ) {
            $this.write_log("Piece is inactive! Pretend we did something anyways ^_^")
            return 1
        }

        # Sort the pieces from left to right so they can be operated on in the correct direction

        switch ($action) {
            "rotate_left" {
                $this.write_log("Attempting to rotate $($this.block_unit) left...")
                $this.rotate_block_unit("left")
                $status = 1
            }
            "rotate_right" {
                $this.write_log("Attempting to rotate $($this.block_unit) left...")
                $this.rotate_block_unit("right")
                $status = 1
            }
            "move_down" {
                $this.write_log("Attempting to move $($this.block_unit) one spot down...")
                $this.move_block_unit_vertical("move_down")
                $status = 1
            }
            "move_up" {
                $this.write_log("Attempting to move $($this.block_unit) one spot down...")
                $this.move_block_unit_vertical("move_up")
                $status = 1
            }
            "move_right" {
                $this.write_log("Attempting to move $($this.block_unit) right...")
                $this.move_block_unit_horizontal("right")
                $status = 1
            }
            "move_left" {
                $this.write_log("Attempting to move $($this.block_unit) left...")
                $this.move_block_unit_horizontal("left")
                $status = 1
            }
        }

        return $status
    }

    hidden [void] set_block_unit_types () {
        $this.block_unit_types = @{
            "I"         = @{                                        #######
                "beauty"    = @{"x" = $this.center;"y" = 1}         #  I  #
                "strange"   = @{"x" = $this.center;"y" = 2}         #  I  # # truth is the center
                "truth"     = @{"x" = $this.center;"y" = 3}         #  I  #
                "charmed"   = @{"x" = $this.center;"y" = 4}         #  I  #
            }                                                       #######
            "Square"    = @{
                "beauty"    = @{"x" = $this.center;"y" = 1}         ######
                "truth"     = @{"x" = $this.center;"y" = 2}         # SS # # there is no center
                "strange"   = @{"x" = $($this.center + 1);"y" = 1}  # SS #
                "charmed"   = @{"x" = $($this.center + 1);"y" = 2}  ######
            }
            "Z"         = @{
                "truth"     = @{"x" = $this.center; "y" = 1}        #######
                "strange"   = @{"x" = $this.center; "y" = 2}        # ZZ  # # truth is the center
                "beauty"    = @{"x" = $($this.center - 1); "y" = 1} #  ZZ #
                "charmed"   = @{"x" = $($this.center + 1); "y" = 2} #######
            }
            "5"         = @{
                "truth"     = @{"x" = $this.center;"y" = 1}         ####### # truth is the center
                "strange"   = @{"x" = $this.center;"y" = 2}         #  55 #
                "beauty"    = @{"x" = $($this.center + 1);"y" = 1}  # 55  #
                "charmed"   = @{"x" = $($this.center - 1);"y" = 2}  #######
            }
            "L"         = @{                                        ######
                "beauty"    = @{"x"=$this.center; "y" = 1}          # L  #
                "truth"     = @{"x"=$this.center; "y" = 2}          # L  # # truth is the center
                "strange"   = @{"x"=$this.center; "y" = 3}          # LL #
                "charmed"   = @{"x"=$($this.center + 1); "y" = 3}   ######
            }
            "Reverse_L" = @{                                        ######
                "beauty"    = @{"x" = $this.center;"y" = 1}         #  R #
                "truth"     = @{"x" = $this.center;"y" = 2}         #  R #
                "strange"   = @{"x" = $this.center;"y" = 3}         # RR # # truth is the center
                "charmed"   = @{"x" = $($this.center - 1);"y" = 3}  ######
            }
            "T"         = @{
                "beauty"    = @{"x" = $this.center;"y" = 1}         #######
                "truth"     = @{"x" = $this.center;"y" = 2}         #  T  # # truth is the center
                "charmed"   = @{"x" = $($this.center + 1);"y" = 2}  # TTT #
                "strange"   = @{"x" = $($this.center - 1);"y" = 2}  #######
            }
        }
    }

    [bool] toggle_activity_state () {
        ## This function will toggle the activity state and also record the history of the activity state
        $status = 0
        # Swap our state from it's current assignment
        $generate_dimensions = ($null -eq $this.particle_dimensions)

        if ( $generate_dimensions ) {
            $this.particle_dimensions = $this.block_unit_types.$($this.block_unit_type)
            $this.write_log("Generated block_unit default dimensions for active block ^_^")
        }

        if ( $this.is_in_particle_roster() -and !$this.is_active -and $generate_dimensions) {
            # Can't toggle state if there's something already in the way
            $this.particle_dimensions = $null
            $this.write_log("Unable to toggle activity state due to other particles in the way")
        } else {
            $this.is_active = [switch] !$this.is_active
            $this.write_log("is_active toggled to $($this.is_active)")
            $status = 1
        }

        return $status
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

    hidden [System.Management.Automation.PSObject] get_timestamp () {
        return Get-Date -UFormat '%s'
    }

    hidden [bool] rotate_block_unit ($direction) {

        # Validate we can rotate the block and fetch the new coordinates
        $this.particle_dimensions = $this.test_rotate_block_unit($direction)

        $this.write_log("Successfully rotated $($this.block_unit) to the $direction ^_^")

        return 1
    }

    hidden [System.Management.Automation.PSObject] test_rotate_block_unit ($direction) {

        # Squares not allowed, only cool blocks
        if ( $this.block_unit_type -eq "Square" ) { return $this.particle_dimensions }

        # This is the orientation of the piece, max rotations determined by
        # angle of each rotation

        $x_edge = 0
        $y_edge = 0

        $new_coords = @{

            "beauty"    = @{"x" =  $this.particle_dimensions."beauty".x;"y" = $this.particle_dimensions."beauty".y}
            "truth"     = @{"x" =  $this.particle_dimensions."truth".x;"y" = $this.particle_dimensions."truth".y}
            "strange"   = @{"x" =  $this.particle_dimensions."strange".x;"y" = $this.particle_dimensions."strange".y}
            "charmed"   = @{"x" =  $this.particle_dimensions."charmed".x;"y" = $this.particle_dimensions."charmed".y}
        }

        if($this.piece_orientation -eq $this.number_of_orientations) {
            $this.piece_orientation = 0
        } else {
            $this.piece_orientation = $this.piece_orientation + 1
        }

        $this.write_log("Set block_unit orientation to: $($this.piece_orientation)")

        $this.write_log("Attempting to transform to new possible dimension")

        # Translate each particle's rotation independently about the "truth" axis

        foreach($particle in $this.particle_dimensions.Keys -ne "truth"){
            foreach($point in $this.particle_dimensions.$particle) {

                $x_truth = $this.particle_dimensions.truth.x
                $y_truth = $this.particle_dimensions.truth.y

                $x_new = $x_truth
                $y_new = $y_truth

                $y_len = $this.particle_dimensions.$particle.x - $x_truth
                $x_len = $this.particle_dimensions.$particle.y - $y_truth

                if($direction -eq "right") {
                    $y_new = $y_new - $y_len
                    $x_new = $x_new + $x_len

                }
                if($direction -eq "left") {
                    $y_new = $y_new + $y_len
                    $x_new = $x_new - $x_len
                }

                # Store our new temp coords
                $new_coords.$particle.x = $x_new
                $new_coords.$particle.y = $y_new

                # Check to see if we're over the edge
                if($x_new -gt $this.max_dimensions.x[-1]) { $x_edge -= 1 }
                if($x_new -lt 1) { $x_edge += 1 }
                if($y_new -gt $this.max_dimensions.y[-1]) { $y_edge -= 1 }
                if($y_new -lt 1) { $y_edge += 1 }
            }
        }



        # Validate we aren't going to intersect with another piece
        $collission_mod = @{}
        $collission = $false

        foreach ( $particle in $new_coords.Keys ) {
            # Check to see if our current coords are inside of another block
            $collission_mod += @{ "$particle" = @{"x"=0;"y"=0} }

            if ( $this.coords_in_particle_roster(@{ "x" = $new_coords.$particle.x;"y" = $new_coords.$particle.y }) ) {
                $collission = $true
                # Can we bump back in any of our dimensions?
                $bump_coord_mods = @(
                    @{"x_mod" = 0;"y_mod" = -1}
                    @{"x_mod" = 1;"y_mod" = 0}
                    @{"x_mod" = 1;"y_mod" = -1}
                    @{"x_mod" = 1;"y_mod" = 1}
                    @{"x_mod" = 0;"y_mod" = 1}
                    @{"x_mod" = -1;"y_mod" = 0}
                    @{"x_mod" = -1;"y_mod" = 1}
                    @{"x_mod" = -1;"y_mod" = -1}
                )

                $run = $true
                foreach ( $mod in $bump_coord_mods ) {
                    if ( $run ) {
                        $x_mod_coords = $new_coords.$particle.x + $mod.x_mod
                        $y_mod_coords = $new_coords.$particle.y + $mod.y_mod

                        $mod_check = !$this.coords_in_particle_roster( @{ "x" = $x_mod_coords;"y" = $y_mod_coords } )
                        if ( $mod_check ) {
                            $collission_mod.$particle.x = $mod.x_mod
                            $collission_mod.$particle.y = $mod.y_mod
                            $run = $false
                        }
                    }
                }
            }
        }

        if ( $collission ) {

            $x_mods = $collission_mod.Values.x -ne 0
            $y_mods = $collission_mod.Values.y -ne 0

            foreach ( $particle in $new_coords.Keys ) {
                $new_coords.$particle.x = $($new_coords.$particle.x + $x_mods[0])
                $new_coords.$particle.y = $($new_coords.$particle.y + $y_mods[0])
            }

        }

        # If we're over the edge, bump the piece one out

        if($x_edge -ne 0) {
            foreach($particle in $new_coords.Keys) {
                $this.write_log("Moved $y_edge positions horizontally to get off the edge ^_^")
                $new_coords.$particle.x = $new_coords.$particle.x + $x_edge
            }
        }

        if($y_edge -ne 0) {
            foreach($particle in $new_coords.Keys) {
                $this.write_log("Moved $y_edge positions vertically to get off the edge ^_^")
                $new_coords.$particle.y = $new_coords.$particle.y + $y_edge
            }
        }

        foreach ( $particle in $new_coords.Keys ) {
            if ( $this.coords_in_particle_roster( @{"x"=$new_coords.$particle.x;"y"=$new_coords.particle.y} ) ) {
                Write-Host "Unable to rotate piece!"
                return $this.particle_dimensions
            }
        }
        # If we have successfully passed all checks, set status of doing something successfully to true ^_^
        $this.block_unit_successfully_did_something = $true

        return $new_coords
    }

    hidden [bool] move_block_unit_vertical ($direction) {
        # Try to move this block unit vertically
        $this.particle_dimensions = $this.test_move_block_unit_vertical($direction)

        return 1
    }

    hidden [System.Management.Automation.PSObject] test_move_block_unit_vertical ($direction) {

        $new_particle_dimensions = @{}

        $number_of_spaces = 1

        if($direction -eq "move_up") { $number_of_spaces = -1 }

        # This will transform the block vertically

        $this.write_log("Checking to see if we can move $number_of_spaces space vertically...")

        foreach($particle in $this.particle_dimensions.Keys){
            $y_curr = $this.particle_dimensions.$particle.y
            $x_curr = $this.particle_dimensions.$particle.x

            $y_new = $y_curr + $number_of_spaces

            # Ensure we're within the bounds of our playground
            if($y_new -lt 1) { return $this.particle_dimensions }
            if($y_new -gt $this.max_dimensions.y[-1]) { return $this.particle_dimensions }

            $coords = @{ "x"=$x_curr; "y"=$y_new }

            # Validate no collissions with other block_units
            if ( $this.coords_in_particle_roster($coords) ) {
                return $this.particle_dimensions
            }

            # Add to new particle_dimensions
            $new_particle_dimensions += @{ "$particle" = $coords }
        }

        $this.block_unit_successfully_did_something = $true

        return $new_particle_dimensions
    }


    hidden [bool] move_block_unit_horizontal ([string] $direction) {

        # Try to move this block unit horizontally
        $this.particle_dimensions = $this.test_move_block_unit_horizontal($direction)

        return 1
    }

    hidden [System.Management.Automation.PSObject] test_move_block_unit_horizontal ([string] $direction) {

        $new_particle_dimensions = @{}

        # This will transform the block horizontally
        # Default direction of movement to right
        $number_of_spaces = 1

        # Check to see if we requested a direction other than default
        if($direction -eq 'left') { $number_of_spaces = -1 }

        $this.write_log("Attempting to move $number_of_spaces space horizontally...")
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $x_curr = $this.particle_dimensions.$particle.x
                $y_curr = $this.particle_dimensions.$particle.y

                $x_new = $x_curr + $number_of_spaces

                if(!($x_new -in $this.max_dimensions.x)) { return $this.particle_dimensions }
                $coords = @{"x"=$x_new;"y"=$y_curr}
                if ( $this.coords_in_particle_roster($coords) ) {
                    return $this.particle_dimensions
                }

                # Add to new particle_dimensions
                $new_particle_dimensions += @{ "$particle" = $coords }
            }
        }

        $this.block_unit_successfully_did_something = $true

        return $new_particle_dimensions
    }

    [void] print_block_unit_dimensions () {
        foreach($particle in $this.particle_dimensions.Keys){
            $temp_msg = $null
            foreach($point in $this.particle_dimensions.$particle) {
                foreach($axis in $point.Keys) {
                    if($null -eq $temp_msg){
                        $temp_msg = "{0,-10} {1,10}" -f "$particle", "$axis : $($point.$axis)"
                    } else {
                        $temp_msg = "$temp_msg | $axis : $($point.$axis)"
                    }
                }
            }
            $this.write_log("$temp_msg")
        }
    }

    [bool] is_in_particle_roster () {
        # Fetch the block_unit's initial particle location
        foreach ( $particle in $this.block_unit_types.$($this.block_unit_type).Keys ) {

            $x = $this.block_unit_types.$($this.block_unit_type).$particle.x
            $y = $this.block_unit_types.$($this.block_unit_type).$particle.y

            if ( $this.particle_roster."$x,$y" ) {
                $this.write_log("This block_unit could intersect with something in the roster!!!")
                return $true
            }
        }

        return $false
    }

    [bool] coords_in_particle_roster ($coords) {
        # Fetch the block_unit's initial particle location

        $x = $coords.x
        $y = $coords.y

        if ( $this.particle_roster."$x,$y" ) {
            $this.write_log("This block_unit could intersect with something in the roster!!!")
            return $true
        }

        return $false
    }
}

function New-BlockUnit($block_unit_id = $null)
{
    ## This function will return a new block_unit object
    $block_unit = New-Object blockUnit

    if($null -ne $block_unit_id) {
        $block_unit.block_unit = $block_unit_id
    }

    return $block_unit
}

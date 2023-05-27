class blockUnit
{
    # Set a unique name for this block
    $block_unit = $("{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999))
    $move_fail_counter = 0

    # Default to inactive, because this piece by default should generate in an "on_deck" state
    $is_active = $false
    $on_deck = $true

    [bool] $automated_move = $false

    # Let's do a 7 block bag system. This will require passing the bag back out to fabric.psm1 in the Play-Tetris function

    # Set the max playground size
    $max_dimensions = @{
        "x" = (1..10)
        "y" = (1..20)
    }

    $center = $($this.max_dimensions.x[-1] / 2)

    # Set allowed piece types
    $block_unit_types = $null
    $block_unit_colors = $null

    $particle_dimensions = $null
    $particle_roster = $(New-Object 'switch[,]' $($this.max_dimensions.x[-1] + 2),$($this.max_dimensions.y[-1] + 2))

    [bool] $block_unit_successfully_did_something = $false

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

        # Generate an empty particle roster
        foreach ( $x in $(0..$($this.max_dimensions.x[-1] + 1))) {
            foreach ( $y in $(0..$($this.max_dimensions.y[-1] + 1))) {
                $this.particle_roster[$x,$y] = $null
            }
        }

        # Randomize piece generation
        $pick_a_number = Get-Random -Minimum 0 -Maximum $($this.block_unit_types.Keys.Count - 1)

        $this.block_unit_type = $(@($this.block_unit_types.Keys)[$pick_a_number])

        $this.write_log("Generated block_unit with the block_unit_type of $($this.block_unit_type) ^_^")
    }

    [bool] do_something ([string] $action) {

        [bool] $status = 0

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
            }
            "rotate_right" {
                $this.write_log("Attempting to rotate $($this.block_unit) left...")
                $this.rotate_block_unit("right")
            }
            "move_down" {
                $this.write_log("Attempting to move $($this.block_unit) one spot down...")
                $this.move_block_unit_vertical("move_down")
            }
            "move_up" {
                $this.write_log("Attempting to move $($this.block_unit) one spot up...")
                $this.hard_drop()
            }
            "move_right" {
                $this.write_log("Attempting to move $($this.block_unit) right...")
                $this.move_block_unit_horizontal("right")
            }
            "move_left" {
                $this.write_log("Attempting to move $($this.block_unit) left...")
                $this.move_block_unit_horizontal("left")
            }
        }

        return $this.block_unit_successfully_did_something

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

        $this.block_unit_colors = @{
                "I"         = "White"
                "Square"    = "Yellow"
                "Z"         = "Green"
                "5"         = "Red"
                "L"         = "Cyan"
                "Reverse_L" = "Magenta"
                "T"         = "Blue"
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
        if($this.piece_orientation -eq $this.number_of_orientations) {
            $this.piece_orientation = 0
        } else {
            $this.piece_orientation = $this.piece_orientation + 1
        }

        $this.write_log("Set block_unit orientation to: $($this.piece_orientation)")

        $this.write_log("Attempting to transform to new possible dimension")

        # Translate each particle's rotation independently about the "truth" axis
        $new_coords = Copy-Object $this.particle_dimensions
        $old_coords = Copy-Object $this.particle_dimensions

        $x_mod = $null
        $y_mod = $null
        $x_collision = $false
        $y_collision = $false

        $collision = $false

        foreach($particle in $new_coords.Keys -ne "truth"){
            foreach($point in $new_coords.$particle) {

                if($direction -eq "right") {
                    $y_mod = -($old_coords.$particle.x - $old_coords.truth.x)
                    $x_mod = $old_coords.$particle.y - $old_coords.truth.y
                }
                if($direction -eq "left") {
                    $y_mod = $old_coords.$particle.x - $old_coords.truth.x
                    $x_mod = -($old_coords.$particle.y - $old_coords.truth.y)
                }

                $new_coords.$particle.x = $old_coords.truth.x + $x_mod
                $new_coords.$particle.y = $old_coords.truth.y + $y_mod

                if ( $this.coords_in_particle_roster($point) ) {
                    $collision = $true
                }
            }
        }

        while ( $collision ) {
            # Try moving it on the y axis
            $temp_new_coords = Copy-Object $new_coords

            foreach($particle in $new_coords.Keys){

                $temp_new_coords.$particle.x = $new_coords.$particle.x
                $temp_new_coords.$particle.y = $new_coords.$particle.y - 1

                if ( $this.coords_in_particle_roster($temp_new_coords.$particle) ) {
                    $y_collision = $true
                }
            }

            if ( !$y_collision ) {
                $new_coords = Copy-Object $temp_new_coords
                break
            } else {
                $temp_new_coords = Copy-Object $new_coords
                $y_collision = $false
                foreach($particle in $new_coords.Keys){

                    $temp_new_coords.$particle.x = $new_coords.$particle.x
                    $temp_new_coords.$particle.y = $new_coords.$particle.y + 1

                    if ( $this.coords_in_particle_roster($temp_new_coords.$particle) ) { $y_collision = $true }
                }
                if ( !$y_collision ) {
                    $new_coords = Copy-Object $temp_new_coords
                    break
                }
            }
            # Try moving it positive on the x axis

            $temp_new_coords = Copy-Object $new_coords
            foreach($particle in $new_coords.Keys){

                $temp_new_coords.$particle.x = $new_coords.$particle.x + 1
                $temp_new_coords.$particle.y = $new_coords.$particle.y

                if ( $this.coords_in_particle_roster($temp_new_coords.$particle) ) {
                    $x_collision = $true
                }
            }

            if ( !$x_collision ) {
                $new_coords = Copy-Object $temp_new_coords
                break
            } else {
                $temp_new_coords = Copy-Object $new_coords
                $x_collision = $false
                foreach($particle in $temp_new_coords.Keys){

                    $temp_new_coords.$particle.x = $new_coords.$particle.x - 1
                    $temp_new_coords.$particle.y = $new_coords.$particle.y

                    if ( $this.coords_in_particle_roster($temp_new_coords.$particle) ) {
                        $x_collision = $true
                    }
                }
                if ( !$x_collision ) {
                    $new_coords = Copy-Object $temp_new_coords
                    break
                }
            }

            $new_coords = Copy-Object $old_coords
            break
        }

        if ( !$x_collision -or !$y_collision ) {
            # If we have successfully passed all checks, set status of doing something successfully to true ^_^
            $this.block_unit_successfully_did_something = $true
        }

        return $new_coords
    }

    hidden [bool] move_block_unit_vertical ($direction) {
        # Try to move this block unit vertically
        $this.particle_dimensions = $this.test_move_block_unit_vertical($direction)

        return $this.block_unit_successfully_did_something
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
            if($y_new -le 1) { 
                if($this.automated_move){
                    $this.move_fail_counter += 1
                }else{
                    $this.move_fail_counter = 0
                }   
                return $this.particle_dimensions 
            }
            if($y_new -gt $this.max_dimensions.y[-1] - 1) { 

                if($this.automated_move){
                    $this.move_fail_counter += 1
                }else{
                    $this.move_fail_counter = 0
                }        
                return $this.particle_dimensions 
            }

            $coords = @{ "x"=$x_curr; "y"=$y_new }

            # Validate no collisions with other block_units
            if ( $this.coords_in_particle_roster($coords) ) {
                $this.move_fail_counter += 1
                return $this.particle_dimensions
            }

            # Add to new particle_dimensions
            $new_particle_dimensions += @{ "$particle" = $coords }
        }

        $this.block_unit_successfully_did_something = $true
        $this.move_fail_counter = 0

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

    

    hidden [void] hard_drop () {

        ## Figure out the max # of spaces we can move down.

        $y_len = $this.particle_roster.GetLength(1) - 1
        
        foreach ( $length in @( 1..$($y_len - 1) ) ) {
            $this.particle_dimensions = $this.test_move_block_unit_vertical("move_down")
        }
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

            if ( $this.particle_roster[$x,$y] ) {
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

        if ( $this.particle_roster[$x,$y] -ne $false ) {
            $this.write_log("This block_unit could intersect with something in the roster!!!")
            return $true
        }

        return $false
    }

    [void] clear_complete_lines(){
        # This function should check to see if any of our particles are in a line and need to clear out
    }
}

function Copy-Object {
    # http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    $memStream = New-Object -TypeName IO.MemoryStream
    $formatter = New-Object -TypeName Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream, $InputObject)
    $memStream.Position = 0
    $formatter.Deserialize($memStream)
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

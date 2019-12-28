class blockUnit
{
    # Set a unique name for this block
    $block_unit = $("{0:d6}" -f $(Get-Random -Minimum 1 -Maximum 999999))

    # Default to inactive, because this piece by default should generate in an "on_deck" state
    $is_active = $false
    $on_deck = $true
    $is_active_history = @{}

    # Set the max playground size

    $max_dimensions = @{
        "x" = (1..10)
        "y" = (1..20)
    }

    $center = $($this.max_dimensions.x[-1] / 2)

    # Set allowed piece types
    $piece_types = $null

    $particle_dimensions = @()

    $piece_initial_shape = @()
    [string] $piece_type = $null
    [int] $rotation_angle = 90 # This is the angle each piece rotates with a call of the rotate method
    [int] $number_of_orientations = 360 / 90 # A circle has 360 degrees, this lets us know the max piece orientations possible
    [int] $piece_orientation = 0 # Max is dynamically calculated based off of the number of orientations possible

    # Set default log location and filename
    $LogFolderPath = "$PSScriptRoot\logs"
    $LogFilePath = "$($this.LogFolderPath)\$($pid)`_particleTetris.log"

    blockUnit ()
    {
        # Let's start some block_unit things! Like what kind of block is this?
        $this.write_log("Generating new block_unit type...")

        # Set the allowed pieces and their size

        $this.set_piece_types()

        # Randomize piece generation
        $pick_a_number = Get-Random -Minimum 0 -Maximum $($this.piece_types.Keys.Count - 1)

        $this.piece_type = $(@($this.piece_types.Keys)[$pick_a_number])

        $this.write_log("Generated block_unit with the piece_type of $($this.piece_type) ^_^")

        # Fetch the block_unit's initial particle location
        $this.particle_dimensions = $this.piece_types.$($this.piece_type)

        $this.write_log("Generated block_unit default dimensions ^_^")

        $this.print_block_unit_dimensions()

        $this.draw_block_unit()
    }

    set_block_unit_id ([int32] $block_unit_id) {
        $this.write_log("Setting block_unit ID to $block_unit_id")
        $this.block_unit = $block_unit_id
    }

    [bool] do_something ([string] $action) {
        $status = 0

        # Sort the pieces from left to right so they can be operated on in the correct direction

        switch ($action) {
            "rotate_left" {
                $this.particle_dimensions = $this.particle_dimensions | Sort-Object -Property x

                $this.write_log("Attempting to rotate $($this.block_unit) left...")

                $this.rotate_block_unit("left")

                $status = 1
            }
            "rotate_right" {
                $this.particle_dimensions = $this.particle_dimensions | Sort-Object -Property x

                $this.write_log("Attempting to rotate $($this.block_unit) left...")

                $this.rotate_block_unit("right")

                $status = 1
            }
            "move_down" {
                $this.write_log("Attempting to move $($this.block_unit) one spot down...")

                if($this.test_move_block_unit_vertical("move_down") -eq 1) {
                    $this.move_block_unit_vertical("move_down")
                } else {
                    $this.write_log("unable to move block_unit DOWN!!!")
                    $status = 0
                }

                $status = 1
            }
            "move_right" {
                $this.write_log("Attempting to move $($this.block_unit) right...")

                $this.particle_dimensions = $this.particle_dimensions | Sort-Object -Property x -Descending

                if($this.test_move_block_unit_horizontal("right") -eq 1) {
                    $this.move_block_unit_horizontal("right")
                } else {
                    $this.write_log("unable to move block_unit RIGHT!!!")
                    $status = 0
                }

                $status = 1
            }
            "move_left" {
                $this.write_log("Attempting to move $($this.block_unit) one spot left...")

                $this.particle_dimensions = $this.particle_dimensions | Sort-Object -Property x

                if($this.test_move_block_unit_horizontal("left") -eq 1) {
                    $this.move_block_unit_horizontal("left")
                } else {
                    $this.write_log("unable to move block_unit LEFT!!!")
                    $status = 0
                }

                $status = 1
            }
        }

        return $status
    }

    hidden [void] set_piece_types () {
        $this.piece_types = @{
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

    [bool] active_check () {
        if ($this.is_active) {
            $this.write_log("block_unit: $($this.block_unit) is ACTIVE  ^_^")
            return 1
        }
        $this.write_log("block_unit: $($this.block_unit) is NOT active!!!")
        return 0
    }

    [void] toggle_activity_state () {
        ## This function will toggle the activity state and also record the history of the activity state

        # Swap our state from it's current assignment
        $this.is_active = [switch] !$this.is_active

        $time = $this.write_log("is_active toggled to $($this.is_active)")

        # Keep track of state history
        $this.is_active_history += @{
            "$time" = "$($this.is_active.ToString())"
        }
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

    [void] draw_block_unit () {

        # Create our dataset object from our dimensions
        $block_unit_particle_coordinates = New-Object 'switch[,]' $($this.max_dimensions.x.Count + 1),$($this.max_dimensions.y.Count + 1)
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $block_unit_particle_coordinates[($point.x),($point.y)] = $true
                Write-Host "Particle located at $($point.x),$($point.y)"
            }
        }

        $this.write_log("Created block_unit_particle_coordinates for graphing")

        # Draw our piece
        $lines = @()

        foreach ($y_coord in $this.max_dimensions.y) {
            $y_coord = $y_coord
            $line = @("|")
            foreach ($x_coord in $this.max_dimensions.x) {
                $x_coord = $x_coord
                if ($block_unit_particle_coordinates[$x_coord,$y_coord] -eq $true) {
                    $line = "$line`x"
                } else {
                    $line = "$line "
                }
            }
            $line = "$line|"

            $lines += @($line)
        }

        $x = $this.particle_dimensions.truth.x
        $y = $this.particle_dimensions.truth.y

        Write-Host "Piece centered at $x,$y"

        $lines | ForEach-Object {Write-Host $_}
    }

    hidden [bool] rotate_block_unit ($direction) {

        # Validate we can rotate the block
        if(!($this.test_rotate_block_unit($direction) -eq 1)){
            $this.write_log("Unable to move block vertically!!!")
            return 0
        }

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

        foreach($particle in $this.particle_dimensions.Keys -ne "truth"){
            foreach($point in $this.particle_dimensions.$particle) {

                $x_truth = $this.particle_dimensions.truth.x
                $y_truth = $this.particle_dimensions.truth.y

                $x_new = $x_truth
                $y_new = $y_truth

                $x_curr = $this.particle_dimensions.$particle.x
                $y_curr = $this.particle_dimensions.$particle.y

                $y_len = $x_curr - $x_truth
                $x_len = $y_curr - $y_truth

                if($direction -eq "right") {
                    $y_new = $y_new - $y_len
                    $x_new = $x_new + $x_len
                }
                if($direction -eq "left") {
                    $y_new = $y_new + $y_len
                    $x_new = $x_new - $x_len
                }

                if(!($x_new -in $this.max_dimensions.x)) {
                    return 0
                }
                if(!($y_new -in $this.max_dimensions.y)) {
                    return 0
                }

                $this.particle_dimensions.$particle.x = $x_new
                $this.particle_dimensions.$particle.y = $y_new
            }
        }

        $this.write_log("Successfully rotated $($this.block_unit) to the $direction ^_^")
        return 1
    }

    hidden [bool] test_rotate_block_unit ($direction) {

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

        foreach($particle in $this.particle_dimensions.Keys -ne "truth"){
            foreach($point in $this.particle_dimensions.$particle) {

                $x_truth = $this.particle_dimensions.truth.x
                $y_truth = $this.particle_dimensions.truth.y

                $x_new = $x_truth
                $y_new = $y_truth

                $x_curr = $this.particle_dimensions.$particle.x
                $y_curr = $this.particle_dimensions.$particle.y

                $y_len = $x_curr - $x_truth
                $x_len = $y_curr - $y_truth

                if($direction -eq "right") {
                    $y_new = $y_new - $y_len
                    $x_new = $x_new + $x_len

                }
                if($direction -eq "left") {
                    $y_new = $y_new + $y_len
                    $x_new = $x_new - $x_len
                }

                if(!($x_new -in $this.max_dimensions.x)) {
                    return 0
                }
                if(!($y_new -in $this.max_dimensions.y)) {
                    return 0
                }
            }
        }

        return 1
    }

    hidden [bool] move_block_unit_vertical ($direction) {
        # Test to see if we can move this block unit vertically

        if(!($this.test_move_block_unit_vertical($direction)) -eq 1){
            $this.write_log("Unable to move block vertically!!!")
            return 0
        }
        $number_of_spaces = 1

        if($direction -eq "move_up") {
            $number_of_spaces = -1
        }

        # This will transform the block vertically, hardcoded to only allow DOWN

        $this.write_log("Attempting to move $number_of_spaces vertically...")
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $y_curr = $this.particle_dimensions.$particle.y
                $y_new = $y_curr + $number_of_spaces

                $this.particle_dimensions.$particle.y = $y_new

            }
        }

        return 1
    }

    hidden [bool] test_move_block_unit_vertical ($direction) {

        $number_of_spaces = 1

        if($direction -eq "move_up") {
            $number_of_spaces = -1
        }

        # This will transform the block vertically, hardcoded to only allow DOWN

        $this.write_log("Checking to see if we can move $number_of_spaces space vertically...")

        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $y_curr = $this.particle_dimensions.$particle.y
                $y_new = $y_curr + $number_of_spaces

                if(!($y_new -lt ($this.max_dimensions.y[-1] + 1))) {
                    return 0
                }
            }
        }

        return 1
    }


    hidden [bool] move_block_unit_horizontal ([string] $direction) {

        # Test to see if we can move this block unit horizontally
        if(!($this.test_move_block_unit_horizontal($direction)) -eq 1){
            $this.write_log("Unable to move block $direction!!!")
            return 0
        }

        # This will transform the block horizontally
        # Default direction of movement to right
        $number_of_spaces = 1

        # Check to see if we requested a direction other than default
        if($direction -eq 'left') {
            $number_of_spaces = -1
        }

        $this.write_log("Attempting to move $number_of_spaces space horizontally...")
        foreach($particle in $this.particle_dimensions.Keys){

            foreach($point in $this.particle_dimensions.$particle) {
                $x_curr = $this.particle_dimensions.$particle.x
                $x_new = $x_curr + $number_of_spaces

                $this.particle_dimensions.$particle.x = $x_new
            }
        }

        return 1
    }

    hidden [bool] test_move_block_unit_horizontal ([string] $direction) {

        # This will transform the block horizontally
        # Default direction of movement to right
        $number_of_spaces = 1

        # Check to see if we requested a direction other than default
        if($direction -eq 'left') {
            $number_of_spaces = -1
        }

        $this.write_log("Attempting to move $number_of_spaces space horizontally...")
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $x_curr = $this.particle_dimensions.$particle.x
                $x_new = $x_curr + $number_of_spaces

                if(!($x_new -in $this.max_dimensions.x)) {
                    return 0
                }
            }
        }

        return 1
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

    [bool] validate_potential_particle_position ($x_y_array) {
        # Here is where we will check to see if our new particle position is valid, one particle at a time

        return $true
    }

}

function New-BlockUnit($block_unit_id = $null)
{
    ## This function will return a new block_unit object
    $block_unit = New-Object blockUnit

    if($null -ne $block_unit_id) {
        $block_unit.set_block_unit_id($block_unit_id)
    }

    return $block_unit
}

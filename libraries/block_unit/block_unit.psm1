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
        "x" = (1..100)
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

        switch ($action) {
            "rotate_left" {
                $this.write_log("Attempting to rotate the piece left...")
                $this.rotate_block_unit("left")
            }
            "rotate_right" {
                $this.write_log("Attempting to rotate the piece left...")
                $this.rotate_block_unit("right")
            }
            "move_down" {
                $this.write_log("Attempting to move one spot down...")
                return $this.move_block_unit_down(1)
            }
        }

        return 1
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

    hidden [System.Management.Automation.PSObject] write_log ($msg) {
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
        $block_unit_particle_coordinates = New-Object 'switch[,]' $this.max_dimensions.x[-1],$this.max_dimensions.y[-1]
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $block_unit_particle_coordinates[$point.x,$point.y] = $true
            }
        }

        $this.write_log("Created block_unit_particle_coordinates for graphing")

        # Draw our piece
        $lines = @()
        $shape = $this.piece_type[0]

        foreach ($y_coord in $this.max_dimensions.y) {
            $y_coord = $y_coord - 1
            $line = @("| ")
            foreach ($x_coord in $this.max_dimensions.x) {
                $x_coord = $x_coord - 1
                if ($block_unit_particle_coordinates[$x_coord,$y_coord] -eq $true) {
                    $line = "$line`x"
                } else {
                    $line = "$line "
                }
            }
            $line = "$line |"

            $lines += @($line)
        }

        $lines | % {Write-Host $_}
    }

    hidden [void] rotate_block_unit ($direction) {

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

                $this.particle_dimensions.$particle.x = $x_new
                $this.particle_dimensions.$particle.y = $y_new
            }
        }
        Clear-Host
        $this.draw_block_unit()
    }

    [bool] move_block_unit_down ($number_of_spaces) {

        # This will transform the block down one space

        $this.write_log("Attempting to transform down one row")
        foreach($particle in $this.particle_dimensions.Keys){
            foreach($point in $this.particle_dimensions.$particle) {
                $y_curr = $this.particle_dimensions.$particle.y
                $y_new = $y_curr + $number_of_spaces

                if($y_new -lt $this.max_dimensions.y[-1]) {
                    $this.particle_dimensions.$particle.y = $y_new
                } else {
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

#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
##

proc namdConfig {args} {

# If things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
  # Set the defaults
  set inputlist ""
  #set pdbFile 0
  set prevConf "PEEK.6H07"
  set outNmae "PEEK.5H"
  set inName "PEEK.5H"
  # Parse options
  for {set argnum 0} {$argnum < [llength $args]} {incr argnum} {
    set arg [lindex $args $argnum]
    set val [lindex $args [expr $argnum + 1]]
    switch -- $arg {
      "-pdb"      { set pdbFile     $val; incr argnum; }
      "-psf"      { set psfFile     $val; incr argnum; }
      "-outName"  { set outName     $val; incr argnum; }
      "-temp"     { set temp        $val; incr argnum; }
      "-runSteps" { set runSteps    $val; incr argnum; }
      "-inName"   { set inName      $val; incr argnum; }
      "-rest"     { set restartfoo  $val; incr argnum; }
      "-par"      { set parFile     $val; incr argnum; }
      "-rfreq"    { set rFreq       $val; incr argnum; }
      "-outfreq"  { set outFreq     $val; incr argnum; }
      "-minsteps" { set minSteps    $val; incr argnum; }
      "-prevConf" { set prevConf    $val; incr argnum; }
      "-numConfFiles" { set numConfFiles  $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }
  set list2 [list $pdbFile $psfFile $outName $temp $runSteps $inName $parFile $rFreq $outFreq $minSteps $prevConf $numConfFiles]
  # Check non-default variables
  set vars [list "pdbFile" "psfFile" "outName" "temp" "runSteps" "inName" "parFile" "rFreq" "outFreq" "minSteps"]

  for {set count_var 0} {$count_var < [llength $vars]} {incr count_var} {
    set z [lindex $vars $count_var]
    set x [info exists $z]
    set y "-$z"
    if {$x < 1} {
      error "error: aggregate: need to define variable $y"
    }
  }
#  return $inputlist


set iname [lindex $list2 2]

for {set i 0} {$i < [lindex $list2 11]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 2 2 $name]
#CreateNamdConf $list2





#set outname [lindex $list2 2]
set fileid [open $name.namd w]
#puts "I am working"
puts $fileid "#############################################################\n## JOB DESCRIPTION                                         ##\n#############################################################\n\n\n#############################################################\n## ADJUSTABLE PARAMETERS                                   ##\n#############################################################\n"
puts $fileid "structure          [lindex $list2 0];
coordinates        [lindex $list2 1];
set outputname     [lindex $list2 2];
set temperature    [lindex $list2 3];
set runSteps       [lindex $list2 4];





set inputname   [lindex $list2 5];


proc get_first_ts { xscfile } {\n\n
     set fd \[open \$xscfile r\]
     gets \$fd
     gets \$fd
     gets \$fd line
     set ts \[lindex \$line 0\]
     close \$fd
     return \$ts\n
}\n "

if { $i == 0 } {
puts $fileid "
    bincoordinates     ./[lindex $list2 10].coor
    binvelocities      ./[lindex $list2 10].vel
    extendedSystem     ./[lindex $list2 10].xsc\n

    firsttimestep 0\n "

} else {
puts $fileid "
    bincoordinates     ./\$inputname.CONT.restart.coor
    binvelocities      ./\$inputname.CONT.restart.vel
    extendedSystem     ./\$inputname.CONT.restart.xsc\n

    set firsttime \[get_first_ts ./\$inputname.restart.xsc\]
    firsttimestep \$firsttime \n "

}

puts $fileid "#############################################################\n## SIMULATION PARAMETERS                                   ##\n#############################################################\n## Input\n"
puts $fileid "paraTypeCharmm      on \n
parameters [lindex $list2 6];\n# Periodic Boundary conditions\nwrapWater           off\nwrapAll             off\n"

puts $fileid "# Force-Field Parameters
exclude             scaled1-4
1-4scaling          1.0
cutoff              16.0
switching           on
switchdist          15.0
pairlistdist        17.5
margin               3\n

timestep            1.0
nonbondedFreq       2
fullElectFrequency  4
stepspercycle       20\n

#PME (for full-system periodic electrostatics)
PME                 yes
PMEGridSpacing      1.0
PMEpencils          1\n\n

# Constant Temperature Control
langevin            on   ;# do langevin dynamics
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps
langevinTemp        \$temperature
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens\n\n

# Constant Pressure Control (variable volume)
useFlexibleCell       yes
useConstantArea       no
langevinPiston        on
langevinPistonTarget  1.01325
langevinPistonPeriod  200
langevinPistonDecay   200
langevinPistonTemp    \$temperature\n"

puts $fileid "# Output
outputName          \$outputname
restartname         \$inputname.CONT.restart
dcdfile             \$outputname.dcd
xstFile             \$outputname.xst\n

restartfreq         [lindex $list2 7];
dcdfreq             [lindex $list2 8];
xstFreq             [lindex $list2 8];
outputEnergies      [lindex $list2 8];
outputPressure      [lindex $list2 8];"

puts $fileid "#############################################################\n## EXTRA PARAMETERS                                        ##\n#############################################################\n## Put here any custom parameters that are specific to\n# this job (e.g., SMD, TclForces, etc...)\n\n#############################################################\n## EXECUTION SCRIPT                                        ##\n#############################################################\n"
puts $fileid "# Minimization\n
minimize            [lindex $list2 9];
reinitvels          \$temperature; \n"

if { $i ==  0 } {
puts $fileid "run \$runSteps; \n"
} else {
puts $fileid "
set stepP \[expr \$runSteps - \$firsttime \];\n
run \$stepP ; \n"
}

close $fileid
}
}


##############################################
#          THE Main Script                   #
##############################################

# The only things that the user should put

# source namdConfiguration_2.tcl
# namdConfig -pdb file -psf file -outName file -temp 100 -runSteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -prevConf PEEK.6H07 -numConfFiles 100
# exit























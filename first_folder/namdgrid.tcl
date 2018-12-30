#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc CreateGrid {list2} {
global i
set outname [lindex $list2 3]
set fileid [open $outname.namd w]


puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n #############################################################\n 
\n 
# contract simulation\n 
\n 
#############################################################\n 
## ADJUSTABLE PARAMETERS                                   ##\n 
#############################################################\n 
\n 
set psfFile       [lindex $list2 0]; 
set pdbFile       [lindex $list2 1]; 
set parFile       [lindex $list2 2];"

if { $i == 0} {
puts $fileid " 
set previousCoor   [lindex $list2 4].coor; 
set previousVel    [lindex $list2 4].vel; 
set previousXsc    [lindex $list2 4].xsc; 
\n"
}
puts $fileid " 
set outName        [lindex $list2 3]; 
set restartName    [lindex $list2 6]; 
\n 
set temperature    [lindex $list2 5]; 
\n 
set restartFreq    [lindex $list2 7]; 
set outFreq        [lindex $list2 8]; 
\n 
set minSteps       [lindex $list2 9]; 
set mdSteps        [lindex $list2 10]; 
\n 
\n 
\n 
#############################################################\n 
## SIMULATION PARAMETERS                                   ##\n 
#############################################################\n 
\n 
# Load structure\n 
structure           \$psfFile;\n 
coordinates         \$pdbFile;\n 
\n 
\n 
# Previous simulations\n 
proc get_first_ts { xscfile } {\n 
    set fd \[open \$xscfile r\]\n 
    gets \$fd\n 
    gets \$fd\n 
    gets \$fd line\n 
    set ts \[lindex \$line 0\]\n 
    close \$fd\n 
    return \$ts\n 
}\n" 

if { $i == 0} {
puts $fileid "
bincoordinates     \$previousCoor;\n 
binvelocities      \$previousVel;\n 
extendedSystem     \$previousXsc;\n 
\n 
firsttimestep 0;\n 
\n"
 
} else {

puts $fileid "
bincoordinates     ./\$restartName.restart.coor \n
binvelocities      ./\$restartName.restart.vel \n
extendedSystem     ./\$restartName.restart.xsc \n
\n
set firsttime \[get_first_ts ./\$restartName.restart.xsc\] \n
firsttimestep \$firsttime "
}

puts $fileid "
# Parameter file \n 
paraTypeCharmm      on; \n 
parameters          \$parFile; \n 
\n 
# Periodic Boundary conditions \n 
wrapWater           off \n 
wrapAll             off \n 
\n 
\n 
# Force-Field Parameters \n 
exclude             scaled1-4 \n 
1-4scaling          1.0 \n 
cutoff              12.0 \n 
switching           on \n 
switchdist          10.0 \n 
pairlistdist        14.0 \n 
margin               3 \n 
\n 
timestep            1.0 \n 
nonbondedFreq       2 \n 
fullElectFrequency  4  \n 
stepspercycle       20 \n 
\n 
\n 
#PME (for full-system periodic electrostatics) \n 
PME                 yes \n 
PMEGridSpacing      1.0 \n 
PMEpencils          1 \n 
\n 
\n 
# Constant Temperature Control \n 
langevin            on   ;# do langevin dynamics \n 
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps \n 
langevinTemp        \$temperature \n 
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens \n 
\n  
\n
# Constant Pressure Control (variable volume) \n
useFlexibleCell       yes \n
useConstantArea       no \n
langevinPiston        on \n
langevinPistonTarget  1.01325 \n
langevinPistonPeriod  200 \n
langevinPistonDecay   200 \n
langevinPistonTemp    \$temperature \n
\n 
# Output \n 
outputName          \$outName \n 
restartname         \$restartName.restart \n 
dcdfile             \$outName.dcd \n 
xstFile             \$outName.xst \n 
\n 
restartfreq         \$restartFreq; \n 
dcdfreq             \$outFreq; \n 
xstFreq             \$outFreq; \n 
outputEnergies      \$outFreq; \n 
\n 
\n 
############################################################# \n 
## EXTRA PARAMETERS                                        ## \n 
############################################################# \n 
\n 
gridforce yes
gridforcefile [lindex $list2 11] 

gridforcecol O
gridforcechargecol B

gridforcepotfile [lindex $list2 12] 

gridforcescale 0.10 0.10 0.10

gridforcevolts no \n
gridforcecont1 no \n
gridforcecont2 no \n
gridforcecont3 no \n
\n
\n
#############################################################\n 
## EXECUTION SCRIPT                                        ##\n 
#############################################################\n 
\n 
# Minimization\n 
minimize            \$minSteps;\n 
reinitvels          \$temperature;\n 
\n 
\n 
# Dynamics\n 
\n
run \$mdSteps\n 
\n 
\n" 

close $fileid
}

#set list1 {structure coordinates outputname temperature runSteps restartfoo inputname inName parFile restartFrequency outputFrequency minSteps}
#set c 
#foreach name $list1 {

#puts -nonewline "Insert $name : "
#flush stdout
#gets stdin var

#lappend list2 $var

#}

#namdConfiguration $list2 


## Create proc to call args.

proc RecieveInput {args} {
  # If things don't work maybe the list is in the first element of args
  set args [lindex $args 0]
  # Set the defaults
  set inputlist ""
  set atommass 12
  set dFdR 0.00034
  set stride 100
  set radSquare 6400.0
  set gridforcefile "./files/PEEK.7H034.gforce"
  set gridforcepotfile "./files/PEEK10nmCNT.K0.Free.dx"
  # Parse options
  for {set argnum 0} {$argnum < [llength $args]} {incr argnum} {
    set arg [lindex $args $argnum]
    set val [lindex $args [expr $argnum + 1]]
    switch -- $arg {
      "-pdb"      { set pdbFile     $val; incr argnum; }
      "-psf"      { set psfFile     $val; incr argnum; }
      "-par"      { set parFile     $val; incr argnum; }
      "-outName"  { set outName     $val; incr argnum; }
      "-inName"   { set inName      $val; incr argnum; }
      "-temp"     { set temp        $val; incr argnum; }
      "-restartName" { set restartName  $val; incr argnum}
      "-rfreq"    { set rFreq       $val; incr argnum; }
      "-outfreq"  { set outFreq     $val; incr argnum; }
      "-minsteps" { set minSteps    $val; incr argnum; }
      "-runSteps" { set runSteps    $val; incr argnum; }
      "-atommass" { set atommass    $val; incr argnum; }
      "-dFdR" { set dFdR    $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      "-gridforcefile" { set gridforcefile     $val; incr argnum; }
      "-gridforcepotfile"   { set gridforcepotfile     $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }
  set inputlist [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile]
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
  return $inputlist
}



#set list1 {structure
#  coordinates
#  outputname
#  temperature
#  runSteps
#  restartfoo
#  inputname
#  inName
#  parFile
#  restartFrequency
#  outputFrequency
#  minSteps}
#set c
#foreach name $list1 {
#puts -nonewline "Insert $name : "
#flush stdout
#gets stdin var
#lappend list2 $var
#}
##########################################################
#   This is for preliminary usage                        #
##########################################################
puts -nonewline "Please insert the values: "
flush stdout
gets stdin defl1
#set defl [split [lindex $defl1 0]]
### In case you wnt default values
#set defl "-pdb file -psf file -par lala.par -outName file -inName file -temp 100 -restartName restart -rfreq 100 -outfreq 100 -minsteps 10 -runSteps 100"
###########################################################
###########################################################
#                  MAIN SCRIPT                            #
###########################################################

set IL [RecieveInput $defl1]

set iname [lindex $IL 3]

for {set i 0} {$i < 9} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name $outVal
set IL [lreplace $IL 3 3 $name]

CreateGrid $IL

}



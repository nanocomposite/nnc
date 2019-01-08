#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc CreateGrid {args} {

# If things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
  # Set the defaults
  set inputlist ""
  set atommass 12
  set dFdR 0.00034
  set stride 100
  set radSquare 6400.0
  set gridforcefile "./files/PEEK.7H034.gforce"
  set gridforcepotfile "./files/PEEK10nmCNT.K0.Free.dx"
  set numConfFiles 50
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
#  set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile $numConfFiles]
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

set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile $numConfFiles]




set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 13]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name $outVal
set list2 [lreplace $list2 3 3 $name]


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

############################################################# 
## SIMULATION PARAMETERS                                   ## 
############################################################# 

# Load structure 
structure           \$psfFile;
coordinates         \$pdbFile; " 

if { $i == 0} {
puts $fileid "
bincoordinates     \$previousCoor;
binvelocities      \$previousVel;
extendedSystem     \$previousXsc;

firsttimestep 0; "
 
} else {

puts $fileid "# Previous simulations 
proc get_first_ts { xscfile } {   
    set fd \[open \$xscfile r\]   
    gets \$fd   
    gets \$fd   
    gets \$fd line   
    set ts \[lindex \$line 0\]   
    close \$fd   
    return \$ts   
}

bincoordinates     ./\$restartName.restart.coor 
binvelocities      ./\$restartName.restart.vel 
extendedSystem     ./\$restartName.restart.xsc 

set firsttime \[get_first_ts ./\$restartName.restart.xsc\] 
firsttimestep \$firsttime "
}

puts $fileid "
# Parameter file  
paraTypeCharmm      on;  
parameters          \$parFile;  
 
# Periodic Boundary conditions  
wrapWater           off  
wrapAll             off  
\n 
 
# Force-Field Parameters \n 
exclude             scaled1-4  
1-4scaling          1.0  
cutoff              12.0  
switching           on  
switchdist          10.0  
pairlistdist        14.0  
margin               3  
\n 
timestep            1.0  
nonbondedFreq       2  
fullElectFrequency  4   
stepspercycle       20  
\n 
#PME (for full-system periodic electrostatics) \n 
PME                 yes  
PMEGridSpacing      1.0  
PMEpencils          1  
\n 
 
# Constant Temperature Control \n 
langevin            on   ;# do langevin dynamics  
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps  
langevinTemp        \$temperature  
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens  
\n  
# Constant Pressure Control (variable volume) \n
useFlexibleCell       yes 
useConstantArea       no 
langevinPiston        on 
langevinPistonTarget  1.01325 
langevinPistonPeriod  200 
langevinPistonDecay   200 
langevinPistonTemp    \$temperature 
\n 
# Output  
outputName          \$outName  
restartname         \$restartName.restart  
dcdfile             \$outName.dcd  
xstFile             \$outName.xst  
 
restartfreq         \$restartFreq;  
dcdfreq             \$outFreq;  
xstFreq             \$outFreq;  
outputEnergies      \$outFreq;  
\n  
#############################################################  
## EXTRA PARAMETERS                                        ##  
#############################################################  
 
gridforce yes
gridforcefile [lindex $list2 11] 

gridforcecol O
gridforcechargecol B

gridforcepotfile [lindex $list2 12] 

gridforcescale 0.10 0.10 0.10

gridforcevolts no 
gridforcecont1 no 
gridforcecont2 no 
gridforcecont3 no 
\n

#############################################################
## EXECUTION SCRIPT                                        ## 
############################################################# 

# Minimization
minimize            \$minSteps; 
reinitvels          \$temperature; 

# Dynamics 

run \$mdSteps " 

close $fileid
}
}


##############################################
#          THE Main Script                   #
##############################################

# The only things that the user should put

# source namdConfiguration_2.tcl
# CreateGrid -pdb file -psf file -par lala.par -outName file -inName file -temp 100 -restartName restart -rfreq 100 -outfreq 100 -minsteps 10 -runSteps 100  
# exit







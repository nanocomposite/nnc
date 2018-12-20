#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc CreateFC {list2 atommass cteForce stride radSquare} {
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
set restartFreq    [lindex $list 7]; 
set outFreq        [lindex $list 8]; 
\n 
set minSteps       [lindex $list 9]; 
set mdSteps        [lindex $list 10]; 
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
# Put here any custom parameters that are specific to \n 
# this job (e.g., SMD, TclForces, etc...) \n 
\n 
tclBC on;\n 
\n 
tclBCScript {\n 
    \n 
    ############## INPUT VALUES ###################\n 
    \n 
    # mass limits; all carbons\n 
    set lowMass [expr {$atommass - 0.3} ];\n 
    set highMass [expr {$atommass + 0.3} ];\n 
    \n 
    # sphere centered at (0,0,0) \n 
    set radSquare $radSquare \n 
\n 
    # cte force ( 0.0144 namdU = 1pN ) \n 
    set cteForce $cteForce \n
    \n 
    # how often clean drops \n 
    set stride $stride; \n  
    \n 
    ############## MAIN PART ################### \n
    \n 
    wrapmode cell; \n 
    \n 
    proc calcforces { step unique } { \n 
	\n 
	global lowMass highMass radSquare cteForce stride; \n 
	\n 
        # clear selection every STRIDE steps \n 
        if { \$step % \$stride == 0 } { cleardrops } \n 
        \n 
        # pick atoms of a given patch one by one \n 
        while {\[nextatom\]} { \n 
	    \n 
	    #>>>>>>>>>>>>>>>>> \n 
            # FOR DEBUG \n 
            # set atomID       \[ getid \]; \n 
            #>>>>>>>>>>>>>>>>> \n 
	    \n 
            # general info                \n 
            set atomMass     \[ getmass \]; \n 
\n 
            # condition for mass \n 
            set forceAtom 0;	 \n 
            if { \$atomMass >= \$lowMass && \$atomMass <= \$highMass } { \n 
                set forceAtom 1; \n 
            } else { \n 
            }        \n 
	    \n 
            # drop atoms outside mass condition \n 
            if { \$forceAtom  == 0 } { \n 
                dropatom; \n 
                continue;   \n 
            } else { \n 
                \n 
		# heavy atoms in this section \n 
		# ---------------------------- \n 
		\n 
		# get current coordinates \n
		set rvec \[ getcoord \] ;# get the atom's coordinates \n 
		foreach { Xcoor Ycoor Zcoor } \$rvec { break } ;# get components of the vector \n 
		unset rvec; \n 
\n 
		####################### \n 
\n 
		# get square of radial distance		\n 
		set rdist2   \[ expr ( \$Xcoor*\$Xcoor ) + ( \$Ycoor*\$Ycoor ) + ( \$Zcoor*\$Zcoor ) \]; \n 
\n 
		if { \$rdist2 < \$radSquare } { \n 
		    set condVol 1; \n 
		} else { \n 
		    set condVol 0; \n 
		} \n
\n 
		\n 
                # apply force\n 
                if { \$condVol == 1 } {\n 
\n 
		    set rdist    \[ expr sqrt(\$rdist2) \];\n 
		    \n 
		    set uVecX \[ expr \$Xcoor/\$rdist \];\n 
		    set uVecY \[ expr \$Ycoor/\$rdist \];\n 
		    set uVecZ \[ expr \$Zcoor/\$rdist \];\n 
		    \n 
		    # negative sign for inward force\n 
		    set forceX \[ expr -1.0*\$uVecX*\$cteForce \];\n 
		    set forceY \[ expr -1.0*\$uVecY*\$cteForce \];\n 
		    set forceZ \[ expr -1.0*\$uVecZ*\$cteForce \];\n 
		    \n 
		    set totalForce "\$forceX \$forceY \$forceZ";		    \n 
		    addforce \$totalForce;\n 
		    \n 
		    #>>>>>>>>>>>>>>>>>\n 
		    # FOR DEBUG               \n 
		    # print "tclBC MESSAGE : step \$step :: atom \$atomID :: mass \$atomMass :: X \$Xcoor :: Y \$Ycoor :: Z \$Zcoor :: magnitudeForce \$forceMag :: vectorForce \$totalForce";\n 
		    #>>>>>>>>>>>>>>>>>\n 
		    \n 
		    unset rdist;\n 
		    unset uVecX;\n 
		    unset uVecY;\n 
		    unset uVecZ;\n 
		    unset forceX;\n 
		    unset forceY;\n 
		    unset forceZ;\n 
		    unset totalForce;               \n 
		}\n 
\n 
		unset rdist2;\n 
		unset Xcoor;\n 
		unset Ycoor;\n 
		unset Zcoor;		\n 
		unset condVol;\n 
	    }  \n 
	    unset forceAtom;                     \n 
	    unset atomMass;                     \n 
        }               \n 
    }    \n 
}\n 
\n 
tclBCArgs { }\n 
\n 
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
# Dynamics\n" 

if { $i == 0 } {
puts $fileid "run \$mdSteps\n 
\n 
\n" 

} else {

puts $fileid "set stepP \[expr \$mdSteps - \$firsttime \] \n
run \$stepP  ;\n"

}

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

global atommass cteForce stride radSquare
  # Set the defaults
  set inputlist ""
  set atommass 12
  set cteForce 0.0144
  set stride 100
  set radSquare 6400.0
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
      "-cteForce" { set cteForce    $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }
  set inputlist [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps]
  # Check non-default variables
  set vars "pdbFile psfFile outName temp runSteps restartfoo inName parFile rFreq outFreq minSteps"
  for {set count_var 0} {$count_var < [llength $args]} {incr count_var} {
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

set IL [RecieveInput]

set name [lindex $IL 3]
set len [string length $name]
set start [expr {$len-4}]
#set count 0

for {set i 0} {$i < 9} {incr i} {

set outVal [ format "%03d" $i ];
set name [string replace $name $start $len "$outVal"]
lreplace $IL 2 2 $name
CreateFC $IL $atommass $cteForce $stride $radSquare

}



#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc namdCreateEX {args} {

# if things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
  # Set the defaults
  set inputlist ""
  set atommass 12
  set dWall 107
  set dFdR 0.00034
  set stride 100
  set radSquare 6400.0
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
      "-dWall"    { set dWall       $val; incr argnum; }
      "-dFdR"     { set dFdR        $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      "-numConfFiles" { set numConfFiles      $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }

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
set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $atommass $dWall $dFdR $stride $numConfFiles]
 


set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 15]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]

set fileid [open $name.namd w]


puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n#############################################################\n 
\n
# contract simulation\n 
\n 
############################################################# 
## ADJUSTABLE PARAMETERS                                   ## 
############################################################# 
\n 
set psfFile       [lindex $list2 0]; 
set pdbFile       [lindex $list2 1]; 
set parFile       [lindex $list2 2]; "

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
\n 
# Load structure\n 
structure           \$psfFile; 
coordinates         \$pdbFile; " 


if { $i == 0} {
puts $fileid "
bincoordinates     \$previousCoor; 
binvelocities      \$previousVel; 
extendedSystem     \$previousXsc; 
\n 
firsttimestep 0;\n 
\n"
 
} else {

puts $fileid "
# Previous simulations\n 
proc get_first_ts { xscfile } {
    set fd \[open \$xscfile r\]
    gets \$fd
    gets \$fd
    gets \$fd line
    set ts \[lindex \$line 0\]
    close \$fd
    return \$ts
}

bincoordinates     ./\$restartName.restart.coor \n
binvelocities      ./\$restartName.restart.vel \n
extendedSystem     ./\$restartName.restart.xsc \n
\n
set firsttime \[get_first_ts ./\$restartName.restart.xsc\] \n
firsttimestep \$firsttime "
}

puts $fileid "
# Parameter file \n 
paraTypeCharmm      on;  
parameters          \$parFile;
# Periodic Boundary conditions
wrapWater           off  
wrapAll             off  

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
PME                 yes \n 
PMEGridSpacing      1.0 \n 
PMEpencils          1 \n 
\n 
 
# Constant Temperature Control \n 
langevin            on   ;# do langevin dynamics 
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps 
langevinTemp        \$temperature \n 
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens
\n  
\n 
# Output 
outputName          \$outName 
restartname         \$restartName.restart 
dcdfile             \$outName.dcd 
xstFile             \$outName.xst  
\n 
restartfreq         \$restartFreq;  
dcdfreq             \$outFreq; 
xstFreq             \$outFreq;  
outputEnergies      \$outFreq;  
\n "

puts $fileid "
############################################################# 
## EXTRA PARAMETERS                                        ##  
############################################################# 
\n 
# Put here any custom parameters that are specific to
# this job (e.g., SMD, TclForces, etc...)
\n
tclBC on; 

tclBCScript { \n
    
    ############## INPUT VALUES ################### 
     
    # mass limits; all carbons 
    set lowMass [expr {[lindex $list2 11] - 0.3} ]; 
    set highMass [expr {[lindex $list2 11] + 0.3} ]; 
    
    # box limit, centered at (0,0,0) 
    set bottomWall [expr {(-1)*([lindex $list2 12])}]; 
    set topWall [lindex $list2 12]; 
    
    # linear force ( 0.0144 namdU = 1pN ) 
    # decay 1000A : 100 pN, 80A : 5 pN 
    set dFdR [lindex $list2 13]; 

    # how often clean drops 
    set stride [lindex $list2 14]; 
    
    ############## MAIN PART ################### 
    
    wrapmode cell;"

puts $fileid "    
    proc calcforces { step unique } { 

	global lowMass highMass bottomWall topWall dFdR stride; 
        # clear selection every STRIDE steps 
        if { \$step % \$stride == 0 } { cleardrops }       \n

        # pick atoms of a given patch one by one
        while {\[nextatom\]} {  \n

	    ############
            # FOR DEBUG  
            # set atomID       \[ getid \]; 
            ###########

            # general info                 \n
            set atomMass     \[ getmass \]; 
 
            # condition for mass

            set forceAtom 0;
            if { \$atomMass >= \$lowMass && \$atomMass <= \$highMass } { 
                set forceAtom 1;
            } else { 

            } "

puts $fileid "	    
            # drop atoms outside mass condition 
            if { \$forceAtom  == 0 } {
                dropatom;
                continue;  
            } else { 
               
		# heavy atoms in this section 
		# 
		
		# get current coordinates 
		set rvec \[ getcoord \] ;# get the atom's coordinates 
		foreach { Xcoor Ycoor Zcoor } \$rvec { break } ;# get components of the vector 
		unset rvec; 

		# condition  atoms inside the cuve Volume 
		set condVol 0;
		if { \$Xcoor > \$bottomWall && \$Xcoor < \$topWall &&  \$Ycoor > \$bottomWall && \$Ycoor < \$topWall && \$Zcoor > \$bottomWall && \$Zcoor < \$topWall } { 
		    set condVol 1;
		}
                # apply force 
                if { \$condVol == 1 } { 
		    set rdist2   \[ expr ( \$Xcoor*\$Xcoor ) + ( \$Ycoor*\$Ycoor ) + ( \$Zcoor*\$Zcoor ) \];
		    set rdist    \[ expr sqrt(\$rdist2) \]; 
		    set forceMag \[ expr \$dFdR*\$rdist  \]; 
		    
		    set uVecX \[ expr \$Xcoor/\$rdist \]; 
		    set uVecY \[ expr \$Ycoor/\$rdist \]; 
		    set uVecZ \[ expr \$Zcoor/\$rdist \]; 
		    
		    # negative sign for inward force 
		    set forceX \[ expr \$uVecX*\$forceMag \]; 
		    set forceY \[ expr \$uVecY*\$forceMag \]; 
		    set forceZ \[ expr \$uVecZ*\$forceMag \]; 
		    
		    set totalForce \"\$forceX \$forceY \$forceZ\";
		    addforce \$totalForce;
		    \n
		    unset rdist2; 
		    unset rdist;
		    unset forceMag;
		    unset uVecX; 
		    unset uVecY; 
		    unset uVecZ; 
		    unset forceX; 
		    unset forceY; 
		    unset forceZ; 
		    unset totalForce;
		} \n
		unset Xcoor; 
		unset Ycoor; 
		unset Zcoor;
		unset condVol;
	    }   \n
	    unset forceAtom;   
	    unset atomMass;   
        }                \n
    }     \n
} \n
 \n
tclBCArgs { } \n
############################################################# 
## EXECUTION SCRIPT                                        ## 
############################################################# 
\n 
# Minimization\n 
minimize            \$minSteps;
reinitvels          \$temperature; 


# Dynamics\n" 

if { $i == 0 } {
puts $fileid "run \$mdSteps\n 
" 

} else {

puts $fileid "set stepP \[expr \$mdSteps - \$firsttime \] \n
run \$stepP  ;"

}

close $fileid

}
}


##############################################
#          THE Main Script                   #
##############################################

# The only things that the user should put

# source namdConfiguration_2.tcl
# namdCreateEX -pdb file -psf file -outName file -temp 100 -runSteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -restartName fileres -numConfFiles 100
# exit


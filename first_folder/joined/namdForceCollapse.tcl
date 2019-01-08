#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
## 
##
## The most important variables go in list2, that is why we check if these were added
################################
proc CreateFC {args} {

  # If things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
  # Set the defaults
  set inputlist ""
  set atommass 12
  set dWall 70
  set cteForce 0.072
  set stride 100
  set restartName "FC"
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
      "-restartName" {set restartName     $val; incr argnum; }
      "-temp"     { set temp        $val; incr argnum; }
      "-rfreq"    { set rFreq       $val; incr argnum; }
      "-outfreq"  { set outFreq     $val; incr argnum; }
      "-minsteps" { set minSteps    $val; incr argnum; }
      "-runSteps" { set runSteps    $val; incr argnum; }
      "-atommass" { set atommass    $val; incr argnum; }
      "-cteForce" { set cteForce    $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      "-numConfFiles" { set numConfFiles      $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }
#set list2 [list $pdbFile $psfFile $parFile $outName $restartName $temp $rFreq $outFreq $minSteps $runSteps $atommass $dWall $cteForce $stride $numConfFiles]
# Check non-default variables
  set vars [list "pdbFile" "psfFile" "outName" "temp" "runSteps" "parFile" "rFreq" "outFreq" "minSteps"]

  for {set count_var 0} {$count_var < [llength $vars]} {incr count_var} {
    set z [lindex $vars $count_var]
    set x [info exists $z]
    set y "-$z"
    if {$x < 1} {
      error "error: aggregate: need to define variable $y"
    }
  }
set list2 [list $pdbFile $psfFile $parFile $outName $restartName $temp $rFreq $outFreq $minSteps $runSteps $atommass $dWall $cteForce $stride $numConfFiles]



set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 14]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]

set fileid [open $name.namd w]

puts $fileid "############################################################# \n## JOB DESCRIPTION                                         ## \n############################################################# \n 
 \n 
# force-collapse simulation \n 
 
#############################################################  
## ADJUSTABLE PARAMETERS                                   ##  
#############################################################  
 \n 
set psfFile       [lindex $list2 0]; 
set pdbFile       [lindex $list2 1]; 
set parFile       [lindex $list2 2]; 
set outName       [lindex $list2 3]; 

set restartName    [lindex $list2 4]; 
 
set temperature    [lindex $list2 5];
 
set restartFreq    [lindex $list2 6];  
set outFreq        [lindex $list2 7]; 
 \n 
set minSteps       [lindex $list2 8];
set mdSteps        [lindex $list2 9]; 
 \n  
#############################################################  
## SIMULATION PARAMETERS                                   ##  
#############################################################  

# Load structure \n 
structure           \$psfFile; 
coordinates         \$pdbFile; " 

if { $i > 0} {
puts $fileid "# Previous simulations \n
proc get_first_ts { xscfile } { 
    set fd \[open \$xscfile r\] 
    gets \$fd 
    gets \$fd 
    gets \$fd line 
    set ts \[lindex \$line 0\] 
    close \$fd 
    return \$ts 
 }

bincoordinates     ./\$restartName.CONT.restart.coor 
binvelocities      ./\$restartName.CONT.restart.vel 
extendedSystem     ./\$restartName.CONT.restart.xsc 

set firsttime \[get_first_ts ./\$restartName.restart.xsc\] 
firsttimestep \$firsttime "

}

puts $fileid "

# Parameter file   

paraTypeCharmm      on;  
parameters          \$parFile; "

if { $i == 0} {

puts $fileid "# temperature  
temperature         \$temperature  " 
}

puts $fileid "# Force-Field Parameters \n 
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
 
#PME (for full-system periodic electrostatics) \n 
PME                 off \n 
 
# Constant Temperature Control \n 
langevin            on   ;# do langevin dynamics  
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps  
langevinTemp        \$temperature 
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens  
 \n 
# Output \n 
outputName          \$outName  
restartname         \$restartName.CONT.restart  
dcdfile             \$outName.dcd  
xstFile             \$outName.xst  
 \n 
restartfreq         \$restartFreq;  
dcdfreq             \$outFreq; 
xstFreq             \$outFreq;  
outputEnergies      \$outFreq;  

#############################################################  
## EXTRA PARAMETERS                                        ##  
#############################################################  

# Put here any custom parameters that are specific to  
# this job (e.g., SMD, TclForces, etc...) \n 

tclBC on;  
 
tclBCScript { 
     
    ############## INPUT VALUES ################### 
    
    # mass limits; all carbons 
    set lowMass [expr {[lindex $list2 10] - 0.3} ];  
    set highMass [expr {[lindex $list2 10] + 0.3}];
    # box limit, centered at (0,0,0)
    set bottomWall [expr {(-1)*([lindex $list2 11])}];
    set topWall [lindex $list2 11];  
    # cte force ( 0.0144 namdU = 1pN ) \n 
    set cteForce [lindex $list2 12] \n 
    
    # how often clean drops 
    set stride [lindex $list2 13];
      
      
    ############## MAIN PART ###################  
     
    wrapmode cell;  
     
    proc calcforces { step unique } {  
	 
	global lowMass highMass bottomWall topWall cteForce stride;  
	 
        # clear selection every STRIDE steps 
        if { \$step % \$stride == 0 } { cleardrops }    
         
        # pick atoms of a given patch one by one \n 
        while {\[nextatom\]} {  
	     
	    #>>>>>>>>>>>>>>>>>  
            # FOR DEBUG  
            # set atomID       \[ getid \];  
            #>>>>>>>>>>>>>>>>>  
	    	    
            # general info         
            set atomMass     \[ getmass \];  

            # condition for mass \n 
            set forceAtom 0;	     
            if { \$atomMass >= \$lowMass && \$atomMass <= \$highMass } {  
                set forceAtom 1;  
            } else { \n 
            }        
	     
            # drop atoms outside mass condition \n 
            if { \$forceAtom  == 0 } {  
                dropatom;  
                continue; 
            } else { \n 
                  
		# heavy atoms in this section  
		# ----------------------------  
		 \n 
		# get current coordinates 
		set rvec \[ getcoord \] ;# get the atom's coordinates 
		foreach { Xcoor Ycoor Zcoor } \$rvec { break } ;# get components of the vector  
		unset rvec; 
		 
		# condition  atoms inside the cuve Volume \n 
		set condVol 1;		  
		if { \$Xcoor > \$bottomWall && \$Xcoor < \$topWall &&  \$Ycoor > \$bottomWall && \$Ycoor < \$topWall && \$Zcoor > \$bottomWall && \$Zcoor < \$topWall } {  
		    set condVol 0;  
		} 
		
                # apply force  
                if { \$condVol == 1 } { 
		    set rdist2   \[ expr ( \$Xcoor*\$Xcoor ) + ( \$Ycoor*\$Ycoor ) + ( \$Zcoor*\$Zcoor ) \];  
		    set rdist    \[ expr sqrt(\$rdist2) \];  
		     
		    set uVecX \[ expr \$Xcoor/\$rdist \];  
		    set uVecY \[ expr \$Ycoor/\$rdist \];  
		    set uVecZ \[ expr \$Zcoor/\$rdist \];  
		     \n 
		    # negative sign for inward force \n 
		    set forceX \[ expr -1.0*\$uVecX*\$cteForce \];  
		    set forceY \[ expr -1.0*\$uVecY*\$cteForce \];  
		    set forceZ \[ expr -1.0*\$uVecZ*\$cteForce \];  
		     \n 
		    set totalForce \"\$forceX \$forceY \$forceZ\"; 
		    addforce \$totalForce; \n 
		     \n 
		   
		     \n 
		    unset rdist2;  
		    unset rdist;  
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
        }    \n 
    }     \n 
} 

tclBCArgs { } 

#############################################################  
## EXECUTION SCRIPT                                        ##  
#############################################################  
 \n 
# Minimization \n 
minimize            \$minSteps 
reinitvels          \$temperature  

# Dynamics \n "
if { $i == 0 } {
puts $fileid "run \$mdSteps \n "
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
# CreateFC -pdb file -psf file -outName file -temp 100 -runSteps 100 -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -restartName fileres -numConfFiles 100
# exit
















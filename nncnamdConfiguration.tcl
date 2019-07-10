#!/usr/bin/tclsh
## Script to create a namd configuration file for minimization
##

proc namdCreateConfig {list2} {

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





set inputname   [lindex $list2 5]; "

if { $i == 0 } {
puts $fileid "
    bincoordinates     ./[lindex $list2 10].coor
    binvelocities      ./[lindex $list2 10].vel
    extendedSystem     ./[lindex $list2 10].xsc\n

    firsttimestep 0\n "

} else {
puts $fileid "

proc get_first_ts { xscfile } {\n\n
     set fd \[open \$xscfile r\]
     gets \$fd
     gets \$fd
     gets \$fd line
     set ts \[lindex \$line 0\]
     close \$fd
     return \$ts\n
}\n

    bincoordinates     ./\$inputname.CONT.restart.coor
    binvelocities      ./\$inputname.CONT.restart.vel
    extendedSystem     ./\$inputname.CONT.restart.xsc\n

    set firsttime \[get_first_ts ./\$inputname.CONT.restart.xsc\]
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
reinitvels          \$temperature;"

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
# namdCreateConfig -pdb file -psf file -outName file -temp 100 -runSteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -prevConf PEEK.6H07 -numConfFiles 100
# exit

###############################################################################################################################################################
## 
## 
##
## 
##
#########################################
proc namdCreateCont {list2} {

set iname [lindex $list2 3]

#set count 0

for {set i 0} {$i < [lindex $list2 15]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]


set fileid [open $name.namd w]


puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n #############################################################\n 
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
puts $fileid "set previousCoor   [lindex $list2 4].coor; 
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
############################################################# 
## SIMULATION PARAMETERS                                   ## 
############################################################# 
\n 
# Load structure\n 
structure           \$psfFile;\n 
coordinates         \$pdbFile;\n 
\n 
\n " 
################
#puts "All ok till here"


if { $i == 0} {
puts $fileid "
bincoordinates     \$previousCoor; 
binvelocities      \$previousVel;
extendedSystem     \$previousXsc; 
\n 
firsttimestep 0;
\n "
 
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
}\n 

bincoordinates     ./\$restartName.restart.coor;
binvelocities      ./\$restartName.restart.vel;
extendedSystem     ./\$restartName.restart.xsc;
\n
set firsttime \[get_first_ts ./\$restartName.restart.xsc\] \n
firsttimestep \$firsttime "
}

puts $fileid "
# Parameter file \n 
paraTypeCharmm      on; 
parameters          \$parFile; 
\n 
# Periodic Boundary conditions \n 
wrapWater           off  
wrapAll             off  
\n 
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
#PME for full-system periodic electrostatics \n 
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
# Constant Pressure Control - variable volume \n 
useFlexibleCell       yes  
useConstantArea       no  
langevinPiston        on  
langevinPistonTarget  1.01325  
langevinPistonPeriod  200  
langevinPistonDecay   200  
langevinPistonTemp    \$temperature  
\n 
# Output \n 
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


#####################################
puts $fileid "
#############################################################  
## EXTRA PARAMETERS                                        ##  
#############################################################  
\n 
# Put here any custom parameters that are specific to  
# this job e.g., SMD, TclForces, etc... \n 

tclBC on; 
\n 
tclBCScript { \n 
     
    ############## INPUT VALUES ################### \n 
     
    # mass limits; all carbons \n 
    set lowMass [expr {[lindex $list2 11] - 0.3} ]; 
    set highMass [expr {[lindex $list2 11] + 0.3} ]; 
     
    # sphere centered at (0,0,0) \n 
    set radSquare [lindex $list2 12]  
\n 
    # cte force ( 0.0144 namdU = 1pN ) \n 
    set cteForce [lindex $list2 13] 
     
    # how often clean drops \n 
    set stride [lindex $list2 14];  
    ############## MAIN PART ################### \n
     
    wrapmode cell;
    "

puts $fileid " 
    proc calcforces { step unique } { \n 
	 
	global lowMass highMass radSquare cteForce stride;  
	 
        # clear selection every STRIDE steps \n 
        if { \$step % \$stride == 0 } { cleardrops }  
        \n 
        # pick atoms of a given patch one by one \n 
        while {\[nextatom\]} {  
	    \n 
	    #>>>>>>>>>>>>>>>>>  
            # FOR DEBUG  
            # set atomID       \[ getid \];  
            #>>>>>>>>>>>>>>>>>  
	    \n 
            # general info                 
            set atomMass     \[ getmass \];  
 
            # condition for mass  
            set forceAtom 0;	  
            if { \$atomMass >= \$lowMass && \$atomMass <= \$highMass } {  
                set forceAtom 1;  
            } else { 
 
            }         
	     
            # drop atoms outside mass condition \n 
            if { \$forceAtom  == 0 } {  
                dropatom;  
                continue;    
            } else {  
                \n 
		# heavy atoms in this section  
		# ----------------------------  
		 
		# get current coordinates 
		set rvec \[ getcoord \] ;# get the atom's coordinates  
		foreach { Xcoor Ycoor Zcoor } \$rvec { break } ;# get components of the vector  
		unset rvec;  
\n "

puts $fileid " 
		#######################  
 
		# get square of radial distance 
		set rdist2   \[ expr ( \$Xcoor*\$Xcoor ) + ( \$Ycoor*\$Ycoor ) + ( \$Zcoor*\$Zcoor ) \];  
\n 
		if { \$rdist2 < \$radSquare } { 
		    set condVol 1; 
		} else { 
		    set condVol 0;  
		} 
"


#puts "ok1.1"
puts $fileid " 
		 
                # apply force\n 
                if { \$condVol == 1 } {\n 
		    set rdist    \[ expr sqrt(\$rdist2) \]; 
		    \n 
		    set uVecX \[ expr \$Xcoor/\$rdist \]; 
		    set uVecY \[ expr \$Ycoor/\$rdist \]; 
		    set uVecZ \[ expr \$Zcoor/\$rdist \]; 
		     
		    # negative sign for inward force\n 
		    set forceX \[ expr -1.0*\$uVecX*\$cteForce \]; 
		    set forceY \[ expr -1.0*\$uVecY*\$cteForce \]; 
		    set forceZ \[ expr -1.0*\$uVecZ*\$cteForce \]; 
		   "



puts $fileid "
 
		    set totalForce \"\$forceX \$forceY \$forceZ\" \n 
		    addforce \$totalForce; 
		    "




puts $fileid "
		    unset rdist;
		    unset uVecX;
		    unset uVecY;
		    unset uVecZ;
		    unset forceX;
		    unset forceY;
		    unset forceZ;
		    unset totalForce; 
		}
\n 
		unset rdist2;
		unset Xcoor;
		unset Ycoor;
		unset Zcoor;
		unset condVol;
	    }  \n 
	    unset forceAtom;
	    unset atomMass;
        }               \n 
    }    \n 
}\n "

puts $fileid " 
\n 
tclBCArgs { } \n 
\n 
#############################################################\n 
## EXECUTION SCRIPT                                        ##\n 
#############################################################\n 
\n 
# Minimization\n 
minimize            \$minSteps;
reinitvels          \$temperature;
\n 
# Dynamics\n 
" 

if { $i == 0 } {
puts $fileid "run \$mdSteps\n 
\n 

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
# namdCreateCont -pdb file -psf file -outName file -temp 100 -runSteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -numConfFiles 100 -restartName filere
# exit





#########################################################################################################
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc namdCreateEX {list2} {

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



##################################################################################################################################################
## Script to create a namd configuration file for minimization
## 
##
## The most important variables go in list2, that is why we check if these were added
################################
proc CreateFC {list2} {

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













#########################################################################################################
## Script to create a namd configuration file for minimization
## 
##
## Here I do have to put inNames, because we use the files from the Force Collapse simulations and we have to create other restart files
##
#########################################
proc CreateGrid {list2} {

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

##########################################################################################################################


package provide nanocomposite 0.1

namespace eval ::NanoComposite:: {
    namespace export nnc*



proc nncnamdConfiguration {args} {

# If things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
#### Set the defaults

 set numConfFiles 1
 set atommass 12
 set stride 100
 set radSquare 6400.0
 set gridforcefile "./files/PEEK.7H034.gforce"
 set gridforcepotfile "./files/PEEK10nmCNT.K0.Free.dx"

# To get to know the usage of namdConfiguration
 set x [info exists [lindex $args 0]]

 if { [llength $args] < 2} {
     puts "Info) usage: namdConfiguration \[options...\] \n      Indicating the type of file\n      -type configuration\n      \(also available: contract, expand, forcecollapse, grid\) "
     return 
 }
 

if { [llength $args] < 3 } {
 switch -exact -- [string tolower [lindex $args 1]] {

    "configuration"    { puts "Info) usage: namdConfiguration -type configuration \[options...\]\n      Available options:\n      -pdb; -psf; -outName; -temp; -runSteps; -inName;\n      -par; -rfreq; -outfreq; -minsteps; -prevConf; -numConfFiles"; return; }
    "contract"         { puts "Info) usage: namdConfiguration -type contract \[options...\]\n      Available options:\n      -pdb; -psf; -par; -outName; -inName; -temp;\n      -restartName; -rfreq; -outfreq; -minsteps; -runsteps; -atommass;\n      -radSquare; -cteForce; -stride; -numConfFiles"; return; }
    "expand"           { puts "Info) usage: namdConfiguration -type expand \[options...\]\n     Available options:\n      -pdb; -psf; -par; -outName; -inName; -temp;\n      -restartName; -rfreq; -outfreq; -minsteps; -runsteps; -atommass;\n      -dWall; -dFdR; -stride; -numConfFiles"; return; }
    "forcecollapse"    { puts "Info) usage: namdConfiguration -type forcecollapse \[options...\]\n      Available options:\n      -pdb; -psf; -par -outName; -restartName; -temp;\n      -rFreq; -outfreq; -minSteps; -runsteps; -atommass; -dWall;\n      -cteForce; -stride; -numConfFiles"; return; }
    "grid"             { puts "Info) usage: namdConfiguration -type grid \[options...\]\n      Available options:\n      -pdb; -psf; -par; -outName; -inName; -temp;\n      -restartName; -rfreq; -outfreq; -minsteps; -runsteps; -gridforcefile;\n      -gridforcepotfile; -numConfFiles"; return; }
    default     { error "error: incorrect argument: -type\nIndicating the type of file\n  -type configuration\n  \(also available: contract, expand, forcecollapse, grid\) "}
  }

}



  # Parse options
  for {set argnum 0} {$argnum < [llength $args]} {incr argnum} {
    set arg [lindex $args $argnum]
    set val [lindex $args [expr $argnum + 1]]
    switch -- $arg {
      "-type"     { set type        $val; incr argnum; }
      "-pdb"      { set pdbFile     $val; incr argnum; }
      "-psf"      { set psfFile     $val; incr argnum; }
      "-par"      { set parFile     $val; incr argnum; }
      "-outName"  { set outName     $val; incr argnum; }
      "-inName"   { set inName      $val; incr argnum; }
      "-temp"     { set temp        $val; incr argnum; }
      "-restartName" { set restartName  $val; incr argnum; }
      "-rfreq"    { set rFreq       $val; incr argnum; }
      "-outfreq"  { set outFreq     $val; incr argnum; }
      "-minsteps" { set minSteps    $val; incr argnum; }
      "-runsteps" { set runSteps    $val; incr argnum; }
      "-atommass" { set atommass    $val; incr argnum; }
      "-dFdR"     { set dFdR        $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      "-gridforcefile" { set gridforcefile     $val; incr argnum; }
      "-gridforcepotfile"   { set gridforcepotfile     $val; incr argnum; }
      "-prevConf" { set prevConf    $val; incr argnum; }
      "-numConfFiles" { set numConfFiles  $val; incr argnum; }
      "-cteForce" { set cteForce    $val; incr argnum; }
      "-dWall"    { set dWall       $val; incr argnum; }
      "-radSquare" { set radSquare  $val; incr argnum; }
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }
#  set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile $numConfFiles]
  # Check non-default variables, force collapsse is the only one that does not need inName


# in order to make sure that data was added 


  set vars [list "pdbFile" "psfFile" "outName" "temp" "runSteps" "parFile" "rFreq" "outFreq" "minSteps"]
  for {set count_var 0} {$count_var < [llength $vars]} {incr count_var} {
    set z [lindex $vars $count_var]
    set x [info exists $z]
    set y "-$z"
    if {$x < 1} {
      puts "error: aggregate: need to define variable $y"
      return
    }
  }

#set list2 [list $pdbFile $psfFile $outName $temp $runSteps $inName $parFile $rFreq $outFreq $minSteps $prevConf $numConfFiles ] 
###############################################################################################################################
# Here you can put specific variables for every type of file, we use this part to create the files according to the -type option
  switch -exact -- [string tolower $type] {

   "configuration"    { set prevConf "PEEK.6H07"; set outNmae "PEEK.5H"; set inName "PEEK.5H" ; set list2 [list $pdbFile $psfFile $outName $temp $runSteps $inName $parFile $rFreq $outFreq $minSteps $prevConf $numConfFiles ]; namdCreateConfig $list2; }
   "contract"         { set cteForce 0.0144; set inName "contract"; set restartName "contract" ; set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $atommass $radSquare $cteForce $stride $numConfFiles]; namdCreateCont   $list2; } 
   "expand"           { set dWall 107; set dFdR 0.00034; set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $atommass $dWall $dFdR $stride $numConfFiles]; namdCreateEX     $list2; }
   "forcecollapse"    { set dWall 70; set cteForce 0.072; set restartName "FC"; set list2 [list $pdbFile $psfFile $parFile $outName $restartName $temp $rFreq $outFreq $minSteps $runSteps $atommass $dWall $cteForce $stride $numConfFiles]; CreateFC         $list2; }
   "grid"             { set dFdR 0.00034; set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $restartName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile $numConfFiles]; CreateGrid       $list2; }
   default     { error "error: incorrect argument: -type"}
  }

}


#From namespace
}

##########################################################################
#                   Some preliminary options                             #
##########################################################################

# CONFIGURATION 
# namdConfiguration -type configuration -pdb file -psf file -outName file -temp 100 -runsteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -prevConf PEEK.6H07 -numConfFiles 100

# CONTRACT
# namdConfiguration -type contract -pdb file -psf file -outName file -temp 100 -runsteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -numConfFiles 100 -restartName filere

# EXPAND
# namdConfiguration -type expand -pdb file -psf file -outName file -temp 100 -runsteps 100 -inName file -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -restartName fileres -numConfFiles 100

# FORCECOLLAPSE
# namdConfiguration -type forcecollapse -pdb file -psf file -outName file -temp 100 -runsteps 100 -par lala.par -rfreq 100 -outfreq 100 -minsteps 10 -restartName fileres -numConfFiles 100

# GRID
# namdConfiguration -type grid -pdb file -psf file -par lala.par -outName file -inName file -temp 100 -restartName restart -rfreq 100 -outfreq 100 -minsteps 10 -runsteps 100













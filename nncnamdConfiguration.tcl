#!/usr/bin/tclsh
## Script to create a namd configuration file for equilibration
# and Annealing
# Available ensembles: NPT, NVT, NVE
# If other words are typed no file will be generated

proc namdCreateConfig {list2} {
global default1

set iname [lindex $list2 2]

# To get the ensemble

if {[lindex $list2 12] == "NPT" }    {
set ensemble 0
} elseif {[lindex $list2 12] == "NVT"} {
set ensemble 1

} elseif {[lindex $list2 12] == "NVE"} {
set ensemble 2
} else {
puts "Ensemble not available\nAvailable ensembles: NPT, NVT, NVE"
return
}


for {set i 0} {$i < [lindex $list2 11]} {incr i} {

set outVal [ format "%03d" $i ];

set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 2 2 $name]

if { ($i >= 1)  && ( $default1 == 1)  } {
set inval [ format "%03d" [expr {$i -1}] ];

set namein $iname
append namein "."
append namein $inval
set list2 [lreplace $list2 5 5 $namein]
}

#set outname [lindex $list2 2]
set fileid [open $name.namd w]
#puts "I am working"
puts $fileid "#############################################################\n## JOB DESCRIPTION                                         ##\n#############################################################\n\n\n#############################################################\n## ADJUSTABLE PARAMETERS                                   ##\n#############################################################\n"
puts $fileid "structure          [lindex $list2 1];
coordinates        [lindex $list2 0];
set outputname     [lindex $list2 2];
set temperature    [lindex $list2 3];
set runSteps       [lindex $list2 4];
\n"

if { $i == 0 } {

if { [lindex $list2 10] == "" } {

if { [lindex $list2 18] != "" } {
puts $fileid "

extendedSystem     ./[lindex $list2 18]\n

temperature \$temperature

firsttimestep 0\n
"
} else {

puts $fileid "

temperature \$temperature

firsttimestep 0\n"
}
} else {

puts $fileid "
bincoordinates     ./[lindex $list2 10].coor
binvelocities      ./[lindex $list2 10].vel
extendedSystem     ./[lindex $list2 10].xsc\n

firsttimestep 0\n"

}

if { ([lindex $list2 13] != 0) && ([lindex $list2 14] != 0) && ([lindex $list2 15] != 0) } {
puts $fileid "
#Periodic boundary conditions
cellBasisVector1     [lindex $list2 13]     0.    0.
cellBasisVector2      0.    [lindex $list2 14]    0.
cellBasisVector3      0.     0.   [lindex $list2 15]
cellOrigin            0.     0.    0.\n"
}


} else {
puts $fileid "

set inputname   [lindex $list2 5];\n
proc get_first_ts { xscfile } {\n\n
     set fd \[open \$xscfile r\]
     gets \$fd
     gets \$fd
     gets \$fd line
     set ts \[lindex \$line 0\]
     close \$fd
     return \$ts\n
}\n

    bincoordinates     ./\$inputname.restart.coor
    binvelocities      ./\$inputname.restart.vel
    extendedSystem     ./\$inputname.restart.xsc\n

    set firsttime \[get_first_ts ./\$inputname.restart.xsc\]
    firsttimestep \$firsttime \n "

}


if { [lindex $list2 16] == 0} {

puts $fileid "
wrapWater           off
wrapAll             off
"
} else {
puts $fileid "
wrapWater           on
wrapAll             on
"
}



puts $fileid "#############################################################\n## SIMULATION PARAMETERS                                   ##\n#############################################################\n## Input\n"
puts $fileid "paraTypeCharmm      on \n
parameters [lindex $list2 6];

"

puts $fileid "# Force-Field Parameters

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
stepspercycle       20\n"

# For NPT ensembles
if { $ensemble == 0} {

puts $fileid "


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

}


# For NVT ensembles
if { $ensemble == 1 } {
puts $fileid "

#PME (for full-system periodic electrostatics) \n 
PME                 yes \n
PMEGridSpacing      1.0 \n
PMEpencils          1 \n

# Constant Temperature Control \n 
langevin            on   ;# do langevin dynamics 
langevinDamping     5     ;# damping coefficient (gamma) of 5/ps 
langevinTemp        \$temperature \n
langevinHydrogen    no    ;# don't couple langevin bath to hydrogens
\n"


}
 
# For NVE ensembles
if { $ensemble == 2 } {

puts $fileid "


#useGroupPressure yes ;# needed for rigidBonds
useFlexibleCell no
useConstantArea no\n
"


} 


puts $fileid "\n# Output
outputName          \$outputname
restartname         \$outputname.restart
dcdfile             \$outputname.dcd
xstFile             \$outputname.xst\n

restartfreq         [lindex $list2 7];
dcdfreq             [lindex $list2 8];
xstFreq             [lindex $list2 8];
outputEnergies      [lindex $list2 8];
outputPressure      [lindex $list2 8];"

if { [lindex $list2 17] != "" } {
puts $fileid "
constraints on
consref [lindex $list2 17]
conskfile [lindex $list2 17]
conskcol B
# Harmonic constant of 1 kcal/molA
constraintScaling 1.0 \n"

}


puts $fileid "#############################################################\n## EXTRA PARAMETERS                                        ##\n#############################################################\n## Put here any custom parameters that are specific to\n# this job (e.g., SMD, TclForces, etc...)\n\n#############################################################\n## EXECUTION SCRIPT                                        ##\n#############################################################\n"



if { $i ==  0 } {

puts $fileid "# Minimization\n
minimize            [lindex $list2 9];
reinitvels          \$temperature;"

puts $fileid "run \$runSteps; \n"
} else {
puts $fileid "
set stepP \[expr \$runSteps - \$firsttime \];\n
run \$stepP ; \n"
}

close $fileid
}
}



######################################
##           Contraction            ##                                    
######################################

proc namdCreateCont {list2} {
global default1

set iname [lindex $list2 3]


for {set i 0} {$i < [lindex $list2 15]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]

if { ($i >= 1)  && ( $default1 == 1)  } {
set inval [ format "%03d" [expr {$i -1}] ];

set namein $iname
append namein "."
append namein $inval
set list2 [lreplace $list2 6 6 $namein]
}


set fileid [open $name.namd w]


puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n #############################################################\n 
\n 
# contract simulation\n 
\n 
############################################################# 
## ADJUSTABLE PARAMETERS                                   ## 
############################################################# 
\n 
set psfFile       [lindex $list2 1]; 
set pdbFile       [lindex $list2 0]; 
set parFile       [lindex $list2 2]; "

if { $i == 0} {
puts $fileid "set previousCoor   [lindex $list2 4].coor; 
set previousVel    [lindex $list2 4].vel; 
set previousXsc    [lindex $list2 4].xsc; 
\n"
}
puts $fileid " 
set outName        [lindex $list2 3]; 
\n 
set temperature    [lindex $list2 5]; 
\n 
set restartFreq    [lindex $list2 7]; 
set outFreq        [lindex $list2 8]; 
\n 
set minSteps       [lindex $list2 9]; 
set runSteps        [lindex $list2 10]; 
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

set restartName    [lindex $list2 6]; 
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
firsttimestep \$firsttime\n"
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
restartname         \$outName.restart  
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
" 

if { $i ==  0 } {

puts $fileid "# Minimization\n
minimize            \$minSteps;
reinitvels          \$temperature;"

puts $fileid "run \$runSteps; \n"
} else {
puts $fileid "
set stepP \[expr \$runSteps - \$firsttime \];\n
run \$stepP ; \n"
}


close $fileid
}
}

#############################################
##            Expand                       ##
#############################################

proc namdCreateEX {list2} {
global default1

set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 15]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]

if { ($i >= 1)  && ( $default1 == 1)  } {
set inval [ format "%03d" [expr {$i -1}] ];

set namein $iname
append namein "."
append namein $inval
set list2 [lreplace $list2 6 6 $namein]
}

# Start writing the file
set fileid [open $name.namd w]

puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n#############################################################\n 
\n
# Expand simulation\n 
\n 
############################################################# 
## ADJUSTABLE PARAMETERS                                   ## 
############################################################# 
\n 
set psfFile       [lindex $list2 1]; 
set pdbFile       [lindex $list2 0]; 
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

set temperature    [lindex $list2 5]; 
\n 
set restartFreq    [lindex $list2 7]; 
set outFreq        [lindex $list2 8]; 
\n 
set minSteps       [lindex $list2 9]; 
set runSteps        [lindex $list2 10]; 
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

set restartName    [lindex $list2 6]; 

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
restartname         \$outName.restart 
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
    set bottomWall [expr {(-1)*([lindex $list2 12]/2.0)}]; 
    set topWall [ expr {[lindex $list2 12]/2.0}]; 
    
    # linear force ( 0.0144 namdU = 1pN ) 
    # decay 1000A : 100 pN, 80A : 5 pN
    # dFdR=(2*fe)/Lexpand 
    set dFdR [expr { ([lindex $list2 13]*2)/[lindex $list2 12] } ]; 
    #set dFdR [lindex $list2 13]; 

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

# Dynamics\n" 

if { $i ==  0 } {

puts $fileid "# Minimization\n
minimize            \$minSteps;
reinitvels          \$temperature;"

puts $fileid "run \$runSteps; \n"
} else {
puts $fileid "
set stepP \[expr \$runSteps - \$firsttime \];\n
run \$stepP ; \n"
}

close $fileid

}
}


#####################################
##        Force Collapse           ##
#####################################
# forcecollapse

proc CreateFC {list2} {
global default1

set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 14]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]

if { ($i >= 1)  && ( $default1 == 1)  } {
set inval [ format "%03d" [expr {$i -1}] ];

set namein $iname
append namein "."
append namein $inval
set list2 [lreplace $list2 4 4 $namein]
}

set fileid [open $name.namd w]

puts $fileid "############################################################# \n## JOB DESCRIPTION                                         ## \n############################################################# \n 
 \n 
# force-collapse simulation \n 
 
#############################################################  
## ADJUSTABLE PARAMETERS                                   ##  
#############################################################  
 \n 
set psfFile       [lindex $list2 1]; 
set pdbFile       [lindex $list2 0]; 
set parFile       [lindex $list2 2]; 
set outName       [lindex $list2 3]; 
 
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
puts $fileid "\nset restartName    [lindex $list2 4]; 
# Previous simulations \n
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
restartname         \$outName.restart  
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
    set bottomWall [expr {(-1)*([lindex $list2 11]/2)}];
    set topWall [expr {[lindex $list2 11]/2}];  
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


########################################
##           Grid                     ##
########################################

proc CreateGrid {list2} {
global default1

set iname [lindex $list2 3]

for {set i 0} {$i < [lindex $list2 13]} {incr i} {

set outVal [ format "%03d" $i ];
set name $iname
append name "."
append name $outVal
set list2 [lreplace $list2 3 3 $name]
set outname [lindex $list2 3]

if { ($i >= 1)  && ( $default1 == 1)  } {
set inval [ format "%03d" [expr {$i -1}] ];

set namein $iname
append namein "."
append namein $inval
set list2 [lreplace $list2 6 6 $namein]
}

set fileid [open $outname.namd w]


puts $fileid "#############################################################\n##JOB DESCRIPTION                                         ##\n #############################################################\n 

# Grid simulation\n 
\n 
#############################################################\n 
## ADJUSTABLE PARAMETERS                                   ##\n 
#############################################################\n 
\n 
set psfFile       [lindex $list2 1]; 
set pdbFile       [lindex $list2 0]; 
set parFile       [lindex $list2 2];"

if { $i == 0} {
puts $fileid " 
set previousCoor   [lindex $list2 4].coor; 
set previousVel    [lindex $list2 4].vel; 
set previousXsc    [lindex $list2 4].xsc;\n"
}
puts $fileid " 
set outName        [lindex $list2 3]; 

set temperature    [lindex $list2 5]; 

set restartFreq    [lindex $list2 7]; 
set outFreq        [lindex $list2 8]; 

set minSteps       [lindex $list2 9]; 
set runSteps        [lindex $list2 10]; 

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

puts $fileid "
set restartName    [lindex $list2 6]; 
# Previous simulations 
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
restartname         \$outName.restart  
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
gridforcechecksize off
gridforcefile [lindex $list2 11] 

gridforcecol O
gridforcechargecol B

gridforcepotfile [lindex $list2 12] 

gridforcescale [lindex $list2 13] [lindex $list2 13] [lindex $list2 13]

gridforcevolts no 
gridforcecont1 no 
gridforcecont2 no 
gridforcecont3 no 
\n

#############################################################
## EXECUTION SCRIPT                                        ## 
############################################################# 
"
if { $i ==  0 } {

puts $fileid "# Minimization\n
minimize            \$minSteps;
reinitvels          \$temperature;"

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



package provide nanocomposite 0.1

namespace eval ::NanoComposite:: {
    namespace export nnc*



proc nncnamdConfiguration {args} {
global default1
# If things don't work maybe the list is in the first element of args
#  set args [lindex $args 0]
#### Set the defaults

 set wrap 0
 set a 0
 set b 0
 set c 0
 set minSteps 10000
 set runSteps 1000000
 set numConfFiles 1
 set atommass 12
 set stride 100
 set radSquare 6400.0
 set gridforcefile "./files/PEEK.7H034.gforce"
 set gridforcepotfile "./files/PEEK10nmCNT.K0.Free.dx"
# fe = 0.0288 namd units = 2pN as default
 set fe 0.0288 
 set ensemble "NPT"
 set inName ""
 set cteForce ""
 set dWall ""
 set temp 310
 set numConfFiles 10
 set rFreq 10000
 set outFreq 100000
 set prevConf ""
 set hrestraint ""
 set sfactor 0.10
 set xsc ""
 
# To get to know the usage of namdConfiguration
 set x [info exists [lindex $args 0]]

 if { [llength $args] < 2} {
     puts "Info) usage: namdConfiguration \[options...\] \n      Indicating the type of file\n      -type equilibration\n      \(also available: contract, expand, forcecollapse, grid\) "
     return 
 }
 

if { [llength $args] < 3 } {
 switch -exact -- [string tolower [lindex $args 1]] {

    "equilibration"    { puts "Info) usage: namdConfiguration -type equilibration \[options...\]\n      Available options:\n      -coor; -psf; -outName; -temp; -runsteps; -inName;\n      -par; -rfreq; -outfreq; -minsteps; -prevConf; -numConfFiles;\n -ensemble; -a; -b; -c; -wrap; -restraint; -xsc"; return; }
    "contract"         { puts "Info) usage: namdConfiguration -type contract \[options...\]\n      Available options:\n      -coor; -psf; -par; -outName; -inName; -temp;\n      -prevConf; -rfreq; -outfreq; -minsteps; -runsteps; -atommass;\n      -radSquare; -cteForce; -stride; -numConfFiles"; return; }
    "expand"           { puts "Info) usage: namdConfiguration -type expand \[options...\]\n     Available options:\n      -coor; -psf; -par; -outName; -inName; -temp;\n      -prevConf; -rfreq; -outfreq; -minsteps; -runsteps; -atommass;\n      -dWall; -fe; -stride; -numConfFiles"; return; }
    "forcecollapse"    { puts "Info) usage: namdConfiguration -type forcecollapse \[options...\]\n      Available options:\n      -coor; -psf; -par -outName; -inName; -temp;\n      -rFreq; -outfreq; -minSteps; -runsteps; -atommass; -dWall;\n      -cteForce; -stride; -numConfFiles"; return; }
    "grid"             { puts "Info) usage: namdConfiguration -type grid \[options...\]\n      Available options:\n      -coor; -psf; -par; -outName; -inName; -temp;\n      -prevConf; -rfreq; -outfreq; -minsteps; -runsteps; -gridforcefile;\n      -gridforcepotfile; -numConfFiles; -sfactor"; return; }
    default     { error "error: incorrect argument: -type\nIndicating the type of file\n  -type equilibration\n  \(also available: contract, expand, forcecollapse, grid\) "}
  }

}

  # Parse options
  for {set argnum 0} {$argnum < [llength $args]} {incr argnum} {
    set arg [lindex $args $argnum]
    set val [lindex $args [expr $argnum + 1]]
    switch -- $arg {
      "-type"     { set type        $val; incr argnum; }
      "-coor"      { set pdbFile     $val; incr argnum; }
      "-psf"      { set psfFile     $val; incr argnum; }
      "-par"      { set parFile     $val; incr argnum; }
      "-outName"  { set outName     $val; incr argnum; }
      "-inName"   { set inName      $val; incr argnum; }
      "-temp"     { set temp        $val; incr argnum; }
      "-rfreq"    { set rFreq       $val; incr argnum; }
      "-outfreq"  { set outFreq     $val; incr argnum; }
      "-minsteps" { set minSteps    $val; incr argnum; }
      "-runsteps" { set runSteps    $val; incr argnum; }
      "-atommass" { set atommass    $val; incr argnum; }
      "-fe"     { set fe        $val; incr argnum; }
      "-stride"   { set stride      $val; incr argnum; }
      "-gridforcefile" { set gridforcefile     $val; incr argnum; }
      "-gridforcepotfile"   { set gridforcepotfile     $val; incr argnum; }
      "-prevConf" { set prevConf    $val; incr argnum; }
      "-numConfFiles" { set numConfFiles  $val; incr argnum; }
      "-cteForce" { set cteForce    $val; incr argnum; }
      "-dWall"    { set dWall       $val; incr argnum; }
      "-radSquare" { set radSquare  $val; incr argnum; }
      "-ensemble"  { set ensemble   [string toupper $val]; incr argnum; }
      "-a"         { set a $val; incr argnum; }
      "-b"         { set b $val; incr argnum; }
      "-c"         { set c $val; incr argnum; }
      "-wrap"       { set wrap $val; incr argnum; }
      "-hrestraint" { set hrestraint $val; incr argnum; }
      "-sfactor" { set sfactor $val; incr argnum; }
      "-xsc" { set xsc $val; incr argnum; } 
      default     { error "error: aggregate: unknown option: $arg"}
    }
#    lappend inputlist $val
  }

  # Check non-default variables, force collapsse is the only one that does not need inName


# in order to make sure that data was added 
  set vars [list "pdbFile" "psfFile" "outName" "parFile" "runSteps"]
  for {set count_var 0} {$count_var < [llength $vars]} {incr count_var} {
    set z [lindex $vars $count_var]
    set x [info exists $z]
    set y "-$z"
    if {$x < 1} {
      puts "error: aggregate: need to define variable $y"
      return
    }
  }


###########################################
# Here you can put specific variables for every type of file, we use this part to create the files according to the -type option

# the variable default1 helps us to tell if the default option for -inName is being used
  set default1 0
  if { $inName == "" } {set default1 1; set inName $outName};

# for Force Collapse, if no "dWall" is input, the default is the edge of a box that gives a density of 1 g/cc

  switch -exact -- [string tolower $type] {

   "equilibration"    { if { $a == "calculate" || $b == "calculate" || $c == "calculate" } {mol load psf $psfFile namdbin $prevConf.coor; set sel [atomselect 0 all]; set v1 [measure minmax $sel]; unset sel; mol delete 0; set a [ expr { [lindex $v1 0 0] - [lindex $v1 1 0]  }]; set b [ expr { [lindex $v1 0 1] - [lindex $v1 1 1]  }]; set c [ expr { [lindex $v1 0 2] - [lindex $v1 1 2]  }]}; set list2 [list $pdbFile $psfFile $outName $temp $runSteps $inName $parFile $rFreq $outFreq $minSteps $prevConf $numConfFiles $ensemble $a $b $c $wrap $hrestraint $xsc]; namdCreateConfig $list2; }
   "contract"         { if { $cteForce == "" } {set cteForce 0.0144}; set list2 [list $pdbFile $psfFile $parFile $outName $prevConf $temp $inName $rFreq $outFreq $minSteps $runSteps $atommass $radSquare $cteForce $stride $numConfFiles]; namdCreateCont   $list2; } 
   "expand"           { if { $dWall == "" } {set dWall 70}; set list2 [list $pdbFile $psfFile $parFile $outName $prevConf $temp $inName $rFreq $outFreq $minSteps $runSteps $atommass $dWall $fe $stride $numConfFiles]; namdCreateEX     $list2; }
   "forcecollapse"    { if { $dWall == "" } {mol load psf $psfFile pdb $pdbFile; set sel [atomselect 0 all]; set m1 [measure sumweights $sel weight mass]; unset sel; mol delete 0; set dWall [expr { pow(($m1*(10)/(6.022)), 1/(3.0))  }]; unset m1 }; if { $cteForce == "" } {set cteForce 0.072}; set list2 [list $pdbFile $psfFile $parFile $outName $inName $temp $rFreq $outFreq $minSteps $runSteps $atommass $dWall $cteForce $stride $numConfFiles]; CreateFC         $list2; }
   "grid"             { set list2 [list $pdbFile $psfFile $parFile $outName $prevConf $temp $inName $rFreq $outFreq $minSteps $runSteps $gridforcefile $gridforcepotfile $numConfFiles $sfactor]; CreateGrid       $list2; }
   default     { error "error: incorrect argument: -type"}
  }

}


#From namespace
}

##########################################################################
#                   Some preliminary options                             #
##########################################################################

# CONFIGURATION 
# nnc namdConfiguration -type equilibration -coor melt.pdb -psf melt.psf -outName equilibrate -temp 310 -runsteps 100 -par parameter.par -rfreq 100 -outfreq 100 -minsteps 10 -prevConf previousfile -numConfFiles 5 -ensemble NPT

# FORCECOLLAPSE
# nnc namdConfiguration -type forcecollapse -coor melt.pdb -psf melt.psf -par parameters.par -outName forcecol -temp 1000 -rfreq 100 -outfreq 100 -minsteps 10 -runsteps 100 -atommass 12 -dWall 70 -cteForce 0.072 -stride 100 -numConfFiles 5 

# EXPAND
# nnc namdConfiguration -type expand -coor melt.pdb -psf melt.psf -par parameter.par -outName expand -prevConf previousfile -temp 310 -rfreq 100 -outfreq 100 -minsteps 10 -runsteps 100 -atommass 12 -dWall 107 -fe 0.0288 -stride 100 -numConfFiles 5

# CONTRACT
# nnc namdConfiguration -type contract -coor melt.pdb -psf melt.psf -par parameter.par -outName output -prevConf previousfile -temp 310 -rfreq 100 -outfreq 100 -minsteps 10 -runsteps 100 -atommass 12 -radSquare 6400.0 -cteForce 0.0144 -stride 100 -numConfFiles 5

# GRID
# nnc namdConfiguration -type grid -coor melt.pdb -psf melt.psf -par parameter.par -outName grid -temp 700K -prevConf bulk -rfreq 100 -outfreq 100 -minsteps 0 -runsteps 100 -gridforcefile ./files/PEEK.7H034.gforce -gridforcepotfile ./files/PEEK10nmCNT.K0.Free.dx -numConfFiles 5


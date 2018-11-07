############################################################
#
#

package provide nanocomposite 0.1

namespace eval ::NanoComposite:: {
    namespace export nnc*


proc nncgeoCollapse { args } {
    
    # Set the defaults
    set strideDist 10;
    set strideAngle -1;
    set trj -1;
    set vortixPoint "0 0 0"
   
    # Parse options
    for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	set arg [ lindex $args $argnum ]
	set val [ lindex $args [expr $argnum + 1]]
	switch -- $arg {
	    "-psf"         { set psfFile       $val; incr argnum; }
	    "-coor"        { set pdbFile       $val; incr argnum; }
	    "-rp"          { set refPointsFile $val; incr argnum; }
	    "-gapLength"   { set strideDist    $val; incr argnum; }
	    "-scanAngle"   { set strideAngle   $val; incr argnum; }
	    "-vortixPoint" { set vortixPoint   $val; incr argnum; }
	    "-trj"         { set trj              0; incr argnum; }
	    "-outName"     { set outName       $val; incr argnum; }
	    default { error "error: aggregate: unknown option: $arg" }
	}
    }

    
    # check non-default variables    
    set checkPSF         [ info exists psfFile ];
    set checkPDB         [ info exists pdbFile ];
    set checkRP          [ info exists refPointsFile ];
    set checkOUTNAME     [ info exists outName ];
    
    if { $checkPSF < 1 } {
	error "error: aggregate: need to define variable -psf"
    }    
    if { $checkPDB < 1 } {
	error "error: aggregate: need to define variable -coor"
    }
    if { $checkRP < 1 } {
	error "error: aggregate: need to define variable -rp"
    }    
    if { $checkOUTNAME < 1 } {
	error "error: aggregate: need to define variable -outName"
    }
    



    # -----------------
    # start procedures
    # -----------------
    
    proc readRefPoints { refPointsFile } {
	set inStream [ open $refPointsFile r ];
        
	foreach line [split [read $inStream] \n] {	
	    set nameVar [ lindex $line 0 ];	
	    if { $nameVar == "newRefPoints" } {
		set refPoints [ lrange $line 2 end ];
	    }	
	}
	
	close  $inStream;
	return $refPoints;
    }
    

    proc doTheMove { molID selection strideWithin  pointOrigin vortixPoint iFrame } {
	# 0.- preliminary calculations
	set selIndex [ $selection get index ];
		
	# 1.- Procedures
	proc emptyLength { molID selection strideWithin } {
	    # selection to index
	    set selIndex [ $selection get index ];
	    
	    # maximum search distance - ten micrometer
	    set distThreshold 100000;
	    
	    # initialize loop
	    set numNeighbor 0;
	    set distJump 0;
	    set currentWithin $strideWithin;
   
	    while { $numNeighbor == 0 && $distJump < $distThreshold } {
		# number of neightbors within shell
		set selShell [ atomselect $molID "(all within $currentWithin of index $selIndex) and not index $selIndex" ];
		set numNeighbor [ $selShell num ];
		$selShell delete;
		
		if { $numNeighbor == 0 } {
		    # no neighbors, increase shell. 
		    set currentWithin [ expr $currentWithin + $strideWithin ];
		} else {
		    # neighbors, take distance : lastShell - stride.
		    set distJump [ expr $currentWithin - (2 * $strideWithin) ];
		    if { $distJump < 0 } {
			set distJump -1;
		    }
		}
	    }	    
	    unset selIndex;
	    unset distThreshold;
	    unset numNeighbor;
	    unset currentWithin;
	    
	    return $distJump;
	}
	
        
	# 2.- moving direction
	set currentCenter $pointOrigin;
	set vecPush       [ vecsub $vortixPoint $currentCenter ];
	set vecPushLength [ veclength $vecPush ];
	
	# conditional needed if you are at the center
	if { $vecPushLength > 0 }  {
	    
	    # 3.- displacement moves
	    set unitVecPush   [ vecnorm $vecPush ];
	    
	    set keepMoving 1;
	    while { $keepMoving == 1 } {
		
		# empty distance for jump
		set distEmpty [ emptyLength $molID $selection $strideWithin ];
		
		if { $distEmpty > 0 } {		    
		    # vector move
		    set currentMove [ vecscale $distEmpty $unitVecPush ];
		    
		    # currentMove must be smaller than distance from center box to center molecule
		    set vecMol2Vortix  [ vecsub    $vortixPoint $currentCenter ];
		    set distMol2Vortix [ veclength $vecMol2Vortix ];
		    
		    if { $distEmpty > $distMol2Vortix } {
			set currentMove $vecMol2Vortix;
			set keepMoving 0;
		    } else {
		    }
		    
		    # do the move!
		    set sel [ atomselect $molID "index $selIndex" ];
		    $sel moveby $currentMove;
		    $sel delete;	
		    
		    # move reference point
		    set currentCenter [ vecadd $currentCenter $currentMove ];
		    
		    # print frames
		    if { $iFrame >= 0 } {
			set all [ atomselect $molID all ];
			#>>>>$all writenamdbin $iFrame.coor;
			animate write namdbin ./$iFrame.coor sel $all waitfor all $molID;
			$all delete;
			incr iFrame
		    }
		    
		} else {	
		    set keepMoving 0;
		}
	    }		
	}
	
	unset vecPush;
	unset vecPushLength;
	unset selIndex;
	
	set outLine {}
	lappend outLine $currentCenter;
	lappend outLine $iFrame;
	
	return $outLine
    }



    proc doTheTwist { molID selection pointOrigin pointAxis pointPlane strideAngle strideWithin iFrame } {

	# CLEANING NEEDED FOR RHO AND DIRECTIONAXIS VARIABLES
	
	# -----------
	# procedures
	# -----------
	
	proc emptyAngle { molID selection pointOrigin pointAxis pointPlane strideAngle strideWithin } {
	    
	    # -----------
	    # procedures
	    # -----------
	    
	    proc emptyLength { molID selection strideWithin } {
		# selection to index
		set selIndex [ $selection get index ];
		
		# maximum search distance - ten micrometer
		set distThreshold 100000;
		
		# initialize loop
		set numNeighbor 0;
		set distJump 0;
		set currentWithin $strideWithin;
		
		while { $numNeighbor == 0 && $distJump < $distThreshold } {
		    # number of neightbors within shell
		    set selShell [ atomselect $molID "(all within $currentWithin of index $selIndex) and not index $selIndex" ];
		    set numNeighbor [ $selShell num ];
		    $selShell delete;
		    
		    if { $numNeighbor == 0 } {
			# no neighbors, increase shell. 
			set currentWithin [ expr $currentWithin + $strideWithin ];
		    } else {
			# neighbors, take distance : lastShell - stride.
			set distJump [ expr $currentWithin - (2 * $strideWithin) ];
			if { $distJump < 0 } {
			    set distJump -1;
			}
		    }
		}	    
		unset selIndex;
		unset distThreshold;
		unset numNeighbor;
		unset currentWithin;
		
		return $distJump;
	    }
	    
	    
	    proc moveSel { selection pointOrigin pointAxis pointPlane newOrigin new3Dcompass } {
		
		# -----------
		# procedures
		# -----------
		
		proc getSphericalCoor { xyzCoor } {
		    
		    # spherical coordinates according to wolfram
		    # http://mathworld.wolfram.com/SphericalCoordinates.html
		    
		    # previous calculations
		    # set rad2deg  [ expr 360.0/(2*3.14159265359) ];
		    set rad2deg 57.29577951307855;
		    
		    # get radius
		    set radiusXYZ  [ veclength $xyzCoor ];	
		    
		    # unitary vector
		    set unitVector [ vecnorm $xyzCoor ];	
		    set uX  [ lindex $unitVector 0 ];
		    set uY  [ lindex $unitVector 1 ];
		    set uZ  [ lindex $unitVector 2 ];	
		    set uX2   [ expr $uX*$uX*1.0 ];
		    set uY2   [ expr $uY*$uY*1.0 ];
		    set sqrtUXY2 [ expr sqrt($uX2+$uY2) ];
		    
		
		    # compute phi
		    # ------------	
		    set posUZ  [ expr abs($uZ) ];
		    
		    if { $posUZ > 0 } {
			set tanPhi [ expr $sqrtUXY2/$posUZ ];
			set phi    [ expr atan($tanPhi) ];
			set phi    [ expr $phi*$rad2deg ];
		    } else {
			set phi 90;
		    }
		    
		    # changing value according to quadrant
		    if { $uZ < 0  } {        
			set phi [ expr 180.0 - $phi  ];
		    }	
		    
		    
		    # compute theta
		    # --------------	
		    set posUX [ expr abs($uX) ];
		    set posUY [ expr abs($uY) ];
		    
		    if { $posUX > 0 } {
			set tanTheta [ expr $posUY/$posUX ];
			set theta    [ expr atan($tanTheta)];
			set theta    [ expr $theta*$rad2deg ];
		    } else {
			if { $posUY > 0 } {
			    set theta 90;
			} else {
			    set theta 0;
			}
		    }
		    
		    
		    # changing value according to quadrant
		    if { $uX >= 0 && $uY >= 0 } {
		    }	
		    if { $uX < 0  && $uY >= 0 } {
			set theta [ expr 180.0 - $theta  ];
		    }	
		    if { $uX < 0  && $uY < 0  } {
			set theta [ expr 180 + $theta ];
		    }	
		    if { $uX >= 0  && $uY < 0 } {
			set theta [ expr 360 - $theta  ];
		    }
		    
		    
		    # out values
		    # -----------	
		    set out {}
		    lappend out $radiusXYZ;
		    lappend out $theta;
		    lappend out $phi;
		    
		    return  $out;
		}
		
		
		proc rotSel { selection axis degrees }  {
		    # Compute Sin and Cos
		    set PI 3.14159265
		    set rad2degrees [ expr ( $degrees * 2.0 * $PI ) / 360.0 ];
		    set sinAngle [ expr sin($rad2degrees) ];
		    set cosAngle [ expr cos($rad2degrees) ];
		    set minusSinAngle [ expr -1.0 * $sinAngle ];
		    set minusCosAngle [ expr -1.0 * $cosAngle ];
		    
		    # Rotation Matrix
		    set rotMatrix {};
		    
		    if { ( $axis == "x" ) || ( $axis == "X" ) } {	    
			lappend rotMatrix  "1 0 0 0";
			lappend rotMatrix  "0 $cosAngle  $minusSinAngle 0";
			lappend rotMatrix  "0 $sinAngle  $cosAngle 0";
			lappend rotMatrix  "0 0 0 1";
		    } elseif { ( $axis == "y" ) || ( $axis == "Y" ) } {	    
			lappend rotMatrix  "$cosAngle  0 $sinAngle 0";
			lappend rotMatrix  "0 1 0 0";
			lappend rotMatrix  "$minusSinAngle 0 $cosAngle 0";
			lappend rotMatrix  "0 0 0 1";	    
		    } elseif { ( $axis == "z" ) || ( $axis == "Z" ) } {
			lappend rotMatrix  "$cosAngle $minusSinAngle 0 0";
			lappend rotMatrix  "$sinAngle $cosAngle 0 0";
			lappend rotMatrix  "0 0 1 0";
			lappend rotMatrix  "0 0 0 1";	    
		    } else {
			error "error: rotXYZ tcl procedure: choose x, y or z, not random letters"
		    }	
		    # Rotate
		    $selection move $rotMatrix;
		    unset rotMatrix;
		}
		
		# ----------------
		# end procedures
		# ----------------

		
		set directionAxis [ vecsub $pointAxis $pointOrigin ];
		
		foreach { oldRadius oldTheta oldPhi } [ getSphericalCoor $directionAxis ] { break };
		
		
		# align with Z-axis and origin position
		# ======================================
		$selection moveby [ vecscale -1 $pointOrigin ];
		
		# align with XZ plane : zero Phi
		set rotPhi [ expr -1.0*$oldPhi ];
		rotSel $selection z $rotPhi;
		
		# align with Z axis : zero Theta
		set rotTheta [ expr -1.0*$oldTheta ];
		rotSel $selection y $rotTheta;
		
		#>>>> align main axis rotation : zero Rho
		#>>>> set rotRho [ expr -1.0*$oldRho ];
		#>>>> rotXYZ $molID z $rotRho;
		
		
		# move to new position
		# =====================
		foreach { newRho newTheta newPhi } $new3Dcompass { break };
		
		#>>>> rotXYZ $selection z $newRho;
		rotSel $selection y $newTheta;
		rotSel $selection z $newPhi;
		
		$selection moveby $newOrigin; 
	    }
	    
	    
	    # ---------------
	    # end procedures
	    # ---------------
	    
	    
	    set selIndex [ $selection get index ];
	    
	    # keep original coordinates 
	    set selSegname [ atomselect $molID "index $selIndex" ];
	    set keepX   [ $selSegname get x ];
	    set keepY   [ $selSegname get y ];
	    set keepZ   [ $selSegname get z ];
	    $selSegname delete;
	    
	    # initialize loop
	    # does not do Rho spin rotations, Rho = 0    
	    set listTheta {};
	    set listPhi {};
	    set listEmptyLength {};
	    
	    # rotate angles
	    set iTheta 0;
	    while { $iTheta <= 180 } {
		
		set iPhi 0;
		while { $iPhi < 360 } {
		    
		    # do the move
		    set selMove [ atomselect $molID "index $selIndex" ];
		    set new3Dcompass "0 $iTheta $iPhi";
		    moveSel $selMove $pointOrigin $pointAxis $pointPlane $pointOrigin $new3Dcompass
		    
		    # compute emptyLentgh, store results
		    lappend listEmptyLength [ emptyLength $molID $selMove $strideWithin ];
		    lappend listTheta $iTheta;
		    lappend listPhi   $iPhi;
		    
		    # move back
		    $selMove set x $keepX;
		    $selMove set y $keepY;
		    $selMove set z $keepZ;
		    $selMove delete;
		    
		    set iPhi [ expr $iPhi + $strideAngle ];	
		}
		set iTheta [ expr $iTheta + $strideAngle ];
	    }
	    
	    
	    # find maximum and return angles and maximum displacement
	    set maxVal 0;
	    set lengthList [ llength $listEmptyLength ];
	    
	    set iAngle 0;
	    
	    set i 0;
	    while { $i < $lengthList } {
		
		set tmpVal [ lindex $listEmptyLength $i ];
		
		if { $tmpVal > $maxVal }  {
		    set maxVal $tmpVal;
		    set iAngle $i;
		} else {
		}
		
		incr i;
	    }
	    
	    set theta4max [ lindex $listTheta $iAngle ];
	    set phi4max   [ lindex $listPhi   $iAngle ];
	    
	    # clean
	    unset selIndex;
	    
	    # out values
	    return "0 $theta4max $phi4max $maxVal";    
	}
	
	
	proc moveSel { selection pointOrigin pointAxis pointPlane newOrigin new3Dcompass } {
	    
	    # -----------
	    # procedures
	    # -----------
	    
	    proc getSphericalCoor { xyzCoor } {
		
		# spherical coordinates according to wolfram
		# http://mathworld.wolfram.com/SphericalCoordinates.html
		
		# previous calculations
		# set rad2deg  [ expr 360.0/(2*3.14159265359) ];
		set rad2deg 57.29577951307855;
		
		# get radius
		set radiusXYZ  [ veclength $xyzCoor ];	
		
		# unitary vector
		set unitVector [ vecnorm $xyzCoor ];	
		set uX  [ lindex $unitVector 0 ];
		set uY  [ lindex $unitVector 1 ];
		set uZ  [ lindex $unitVector 2 ];	
		set uX2   [ expr $uX*$uX*1.0 ];
		set uY2   [ expr $uY*$uY*1.0 ];
		set sqrtUXY2 [ expr sqrt($uX2+$uY2) ];
		
		
		# compute phi
		# ------------	
		set posUZ  [ expr abs($uZ) ];
		
		if { $posUZ > 0 } {
		    set tanPhi [ expr $sqrtUXY2/$posUZ ];
		    set phi    [ expr atan($tanPhi) ];
		    set phi    [ expr $phi*$rad2deg ];
		} else {
		    set phi 90;
		}
		
		# changing value according to quadrant
		if { $uZ < 0  } {        
		    set phi [ expr 180.0 - $phi  ];
		}	
		
		
		# compute theta
		# --------------	
		set posUX [ expr abs($uX) ];
		set posUY [ expr abs($uY) ];
		
		if { $posUX > 0 } {
		    set tanTheta [ expr $posUY/$posUX ];
		    set theta    [ expr atan($tanTheta)];
		    set theta    [ expr $theta*$rad2deg ];
		} else {
		    if { $posUY > 0 } {
			set theta 90;
		    } else {
			set theta 0;
		    }
		}
		
		
		# changing value according to quadrant
		if { $uX >= 0 && $uY >= 0 } {
		}	
		if { $uX < 0  && $uY >= 0 } {
		    set theta [ expr 180.0 - $theta  ];
		}	
		if { $uX < 0  && $uY < 0  } {
		    set theta [ expr 180 + $theta ];
		}	
		if { $uX >= 0  && $uY < 0 } {
		    set theta [ expr 360 - $theta  ];
		}
		
		
		# out values
		# -----------	
		set out {}
		lappend out $radiusXYZ;
		lappend out $theta;
		lappend out $phi;
		
		return  $out;
	    }
	    
	    
	    proc rotSel { selection axis degrees }  {
		# Compute Sin and Cos
		set PI 3.14159265
		set rad2degrees [ expr ( $degrees * 2.0 * $PI ) / 360.0 ];
		set sinAngle [ expr sin($rad2degrees) ];
		set cosAngle [ expr cos($rad2degrees) ];
		set minusSinAngle [ expr -1.0 * $sinAngle ];
		set minusCosAngle [ expr -1.0 * $cosAngle ];
		
		# Rotation Matrix
		set rotMatrix {};
		
		if { ( $axis == "x" ) || ( $axis == "X" ) } {	    
		    lappend rotMatrix  "1 0 0 0";
		    lappend rotMatrix  "0 $cosAngle  $minusSinAngle 0";
		    lappend rotMatrix  "0 $sinAngle  $cosAngle 0";
		    lappend rotMatrix  "0 0 0 1";
		} elseif { ( $axis == "y" ) || ( $axis == "Y" ) } {	    
		    lappend rotMatrix  "$cosAngle  0 $sinAngle 0";
		    lappend rotMatrix  "0 1 0 0";
		    lappend rotMatrix  "$minusSinAngle 0 $cosAngle 0";
		    lappend rotMatrix  "0 0 0 1";	    
		} elseif { ( $axis == "z" ) || ( $axis == "Z" ) } {
		    lappend rotMatrix  "$cosAngle $minusSinAngle 0 0";
		    lappend rotMatrix  "$sinAngle $cosAngle 0 0";
		    lappend rotMatrix  "0 0 1 0";
		    lappend rotMatrix  "0 0 0 1";	    
		} else {
		    error "error: rotXYZ tcl procedure: choose x, y or z, not random letters"
		}	
		# Rotate
		$selection move $rotMatrix;
		unset rotMatrix;
	    }
	    
	    # ----------------
	    # end procedures
	    # ----------------
	    
	    
	    foreach { oldRadius oldTheta oldPhi } [ getThetaPhi $pointOrigin $pointAxis $pointPlane ] { break };
	    
	    
	    # align with Z-axis and origin position
	    # ======================================
	    $selection moveby [ vecscale -1 $pointOrigin ];
	    
	    # align with XZ plane : zero Phi
	    set rotPhi [ expr -1.0*$oldPhi ];
	    rotSel $selection z $rotPhi;
	    
	    # align with Z axis : zero Theta
	    set rotTheta [ expr -1.0*$oldTheta ];
	    rotSel $selection y $rotTheta;
	    
	    # align main axis rotation : zero Rho
	    set rotRho [ expr -1.0*$oldRho ];
	    rotXYZ $molID z $rotRho;
	    
	    
	    # move to new position
	    # =====================
	    foreach { newRho newTheta newPhi } $new3Dcompass { break };
	    
	    rotXYZ $selection z $newRho;
	    rotSel $selection y $newTheta;
	    rotSel $selection z $newPhi;
	    
	    $selection moveby $newOrigin; 
	}
        
	# ---------------
	# end procedures
	# ---------------
	
	
	################ MAIN #################
	
	
	# selection to index
	set selIndex [ $selection get index ];
        
	# scan angle with best empty space    
	foreach { rho4max theta4max phi4max maxVal } [ emptyAngle $molID $selection $pointOrigin $pointAxis $pointPlane $strideAngle $strideWithin ] { break };
	
	
	if { $maxVal > $strideWithin } {	
	    # found an angle with empty space
	    # --------------------------------
	    
	    # set new angular position
	    set new3Dcompass "$rho4max $theta4max $phi4max";
	    
	    # do the move!
	    set selection2  [ atomselect $molID "index $selIndex" ];
	    moveSel $selection2 $pointOrigin $pointAxis $pointPlane $pointOrigin $new3Dcompass;
	    $selection2 delete;
	    
	    # print frames
	    if { $iFrame >= 0 } {
		set all [ atomselect $molID all ];		
		animate write namdbin ./$iFrame.coor sel $all waitfor all $molID;
		$all delete;
		incr iFrame
	    }    
	    
	} else { 
	    
	}
	
	unset selIndex;
	return $iFrame;
    }    
                
    
    # ---------------
    # end procedures
    # ---------------

    

    ############### MAIN ###############

    
    # structures
    # -----------
    set tmpPSF $psfFile;
    set tmpPDB $pdbFile;
    
        
    # order segnames according to distance to vertix point
    # -----------------------------------------------------

    # get centers and segnames
    set listSegCen [ readRefPoints $refPointsFile ];
    set segList    {};
    set originList {};
    set pAxisList  {};
    set pPlaneList {};
    
    foreach line $listSegCen {
	lappend segList    [ lindex $line 0 ];
	lappend originList [ lindex $line 1 ];	
	lappend pAxisList  [ lindex $line 2 ];	
	lappend pPlaneList [ lindex $line 3 ];	
    }
    
    # compute distance to vertix point
    set listDist2Vortix "";    
    foreach oneOrigin $originList {
	set vec2vortix  [ vecsub $vortixPoint $oneOrigin ];
	set dist2vortix [ veclength $vec2vortix ];

	lappend listDist2Vortix $dist2vortix;
	
	unset vec2vortix;
	unset dist2vortix;
    }
    
    # order according to distance
    set listIndexOrder [ lsort -indices -real $listDist2Vortix ];
    
    set orderSegname {};
    set orderOrigin  {};
    set orderPaxis   {};
    set orderPplane  {};
    
    foreach item $listIndexOrder {
	lappend orderSegname [ lindex $segList $item ];
	lappend orderOrigin  [ lindex $originList $item ];
	lappend orderPaxis   [ lindex $pAxisList $item ];
	lappend orderPplane  [ lindex $pPlaneList $item ];
    }    
    set numSegname [ llength $orderSegname ];


    
    # do the moves
    # -------------
    
    # load molecule
    set molID [ mol new $tmpPSF type psf waitfor all ];
    mol addfile $tmpPDB waitfor all;    
   
    set i 1;
    set iFrame $trj;
    
    foreach eachSeg $orderSegname eachOrigin $orderOrigin eachPaxis $orderPaxis eachPplane $orderPplane {	
	puts "segname $eachSeg moved :: $i of $numSegname segnames";	
	set selection [ atomselect $molID "segname $eachSeg" ];
	
	# linear displacement
	puts "initial displacement :: segname $eachSeg :: $i of $numSegname :: iFrame $iFrame";
	foreach { currCen iFrame } [ doTheMove $molID $selection $strideDist $eachOrigin $vortixPoint $iFrame ] { break }; 	

	
	########### ROTATION ###########
	if { $strideAngle > 0 } {	    
	    set vecDisp    [ vecsub $currCen $eachOrigin ];
	    set currPaxis  [ vecadd $vecDisp $eachPaxis ];
	    set currPplane [ vecadd $vecDisp $eachPplane ];
	    
	    puts "rotation :: segname $eachSeg :: $i of $numSegname :: iFrame $iFrame";
	    set iFrame [ doTheTwist $molID $selection $currCen $currPaxis $currPplane $strideAngle $strideDist $iFrame ];	    	    
	
	    # final displacement
	    puts "final displacement :: segname $eachSeg :: $i of $numSegname :: iFrame $iFrame";
	    foreach { currCen iFrame } [ doTheMove $molID $selection $strideDist $eachOrigin $vortixPoint $iFrame ] { break }; 
	}

	$selection delete;	
	incr i;   
    }
    
    set all [ atomselect $molID all ];
    animate write namdbin ./$outName.coor sel $all waitfor all $molID;
    $all delete;


    # write DCD trajectory    
    if { $trj >= 0 } {
	set iDCD $trj;
	
	set molID1 [ mol new $tmpPSF type psf waitfor all ];
	
	while { $iDCD < $iFrame } {
	    mol addfile $iDCD.coor waitfor all;
	    file delete $iDCD.coor;
	    incr iDCD;
	}	
	animate write dcd $outName.dcd waitfor all skip 1 $molID1;
	mol delete $molID1;
    }

    
    # clean
    mol delete $molID;
    unset tmpPSF;
    unset tmpPDB;        
}


}






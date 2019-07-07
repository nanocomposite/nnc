############################################################
#
#

package provide nanocomposite 0.1

namespace eval ::NanoComposite:: {
    namespace export nnc*

proc nncrandomGrid  { args } {
    
    #
    # This script create a cube of polymers for annealing 
    #
    # 1st. Make grid centers, grid angles.
    # 2nd. Create temporal PSF/PDB files
    # 3rd. Move temporal PSF/PDB files
    # 4th. Concatenate all PSF/PDB and erase temporal PSF/PDB
    # 5th. Log file for used parameters
    #
    
    # initial syntax : makeGrid  $psfFile $pdbFile $lengthGrid $iGrid $jGrid $kGrid $seed $outName 
    # now changed for package nnc
    
    #####################
    #####################
    
    # Set the defaults
    set lengthGrid 10;
    set iGrid 1;
    set jGrid 1;
    set kGrid 1;
    set seed [ pid ];
    #set outName "testGrid";

    
    # !!!!!!!!!! MOVE THIS PROC TO BOTTOM LATER !!!!!!!!! #
    # proc for random number generator - see bottom    
    proc randomInit { seed } {
	global rand	
	set rand(ia) 9301;
	set rand(ic) 49297;
	set rand(im) 233280;
	set rand(seed) $seed;	
    }
    
    proc random {} {
	global rand
	set rand(seed) [ expr ($rand(seed)*$rand(ia) + $rand(ic)) % $rand(im) ];
	return [ expr $rand(seed)/double($rand(im)) ];	
    }
    
    proc randomRange { range } {
	expr int([random]*$range)
    }
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
    
    
    # Parse options
    for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	set arg [ lindex $args $argnum ]
	set val [ lindex $args [expr $argnum + 1]]
	switch -- $arg {
	    "-psf"        { set psfFile    $val; incr argnum; }
	    "-coor"       { set pdbFile    $val; incr argnum; }
	    "-lengthGrid" { set lengthGrid $val; incr argnum; }
	    "-iGrid"      { set iGrid      $val; incr argnum; }
	    "-jGrid"      { set jGrid      $val; incr argnum; }
	    "-kGrid"      { set kGrid      $val; incr argnum; }
	    "-seed"       { set seed       $val; incr argnum; }
	    "-outName"    { set outName    $val; incr argnum; }
	    default { error "error: randomGrid: unknown option: $arg" }
	}
    }


    # check non-default variables
    
    set checkPSF     [ info exists psfFile ];
    set checkPDB     [ info exists pdbFile ];
    set checkOUTNAME [ info exists outName ];
        
    if { $checkPSF < 1 } {
	error "error: randomGrid: need to define variable -psf"
    }
    
    if { $checkPDB < 1 } {
	error "error: randomGrid: need to define variable -coor"
    }
    
    if { $checkOUTNAME < 1 } {
	error "error: randomGrid: need to define variable -outName"
    }
    

   
    ##################################
    # 0.- procedures
    ##################################
    
    # script for renaming segnames
    proc chainNameGMX { numChain0 } {
	
	# procedure to return chain name for a number
	proc chainName3 { numChain2 } {
	    
	    # 18277 = ZZZ
	    # more numbers require new design
	    
	    # ==========
	    # procedures
	    # ==========
	    proc chainName { numChain } {		
		# template names
		set listTemplate "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z";
		set lengthTemplate 26;
		
		set chainName [ lindex $listTemplate  [ expr $numChain%26 ] ];
		
		set prefixIndex [ expr ($numChain/26) - 1 ];
		set prefix [ lindex $listTemplate $prefixIndex ];
		
		return "$prefix$chainName"		
	    }
	    
	    # =============
	    # compute names
	    # =============
	    if { $numChain2 <= 701 } {		
		chainName $numChain2;		
	    } else {		
		set num1 [ expr $numChain2 - 702 ];
		set perNum [ expr 702 - 26 ];
		set num2 [ expr $num1/$perNum ];
		set num3  [ expr $num1 - ( $num2 * $perNum ) + 26 ];
		
		set preLeft [ chainName $num2 ];
		set preRight [ chainName $num3 ];
		
		return "$preLeft$preRight";		
	    }	
	}
		    
	# get chain name
	set tmpChainName [ chainName3 $numChain0 ];
	
	# invert letter order
	set outChainName [ string reverse $tmpChainName ];
	        
	return $outChainName;
    }
    
        
    
    proc moveBody { molID pointOrigin pointAxis pointPlane newOrigin new3Dcompass } {
	
	# tcl procedures
	# ===============
	
	proc getOrthogonalSystem { pointOrigin pointAxis pointPlane } {
	    
	    # given 3 points, return cartesian orthogonal axis
	    # $pointOrigin $pointAxis defines the main axis
	    # $pointOrigin $pointPlane a plane for the second axis
	    # cross product is used for the thrid axis
	    
	    # axis vectors
	    set vecAxis  [ vecsub $pointAxis  $pointOrigin ];
	    set vecPlane [ vecsub $pointPlane $pointOrigin ];
	    
	    # unitary vectors
	    set uAxis  [ vecnorm $vecAxis ];
	    set uPlane [ vecnorm $vecPlane ];
	    
	    # dot product 
	    set cosAlpha [ vecdot $uAxis $uPlane ];
	    
	    # 2nd axis : move uPlane to an orthogonal position
	    set moveUplane [ vecscale $cosAlpha $uAxis ];
	    set uAxisOrth  [ vecsub $uPlane $moveUplane ];
	    set uAxisOrth  [ vecnorm $uAxisOrth ];
	    
	    # 3rd axis
	    set uAxisPlaneOrth [ veccross $uAxis $uAxisOrth ];
	    
	    # out values
	    set out {}
	    lappend out $uAxis;
	    lappend out $uAxisOrth;
	    lappend out $uAxisPlaneOrth;
	    
	    return  $out
	    
	}
	
	
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
	    
	    return  $out
	}
	
    	
	proc rotXYZ { molID axis degrees }  {	    
	    # Compute Sin and Cos
	    set PI 3.14159265
	    set rad2degrees [ expr ( $degrees * 2.0 * $PI ) / 360.0 ];
	    set sinAngle [ expr sin($rad2degrees) ];
	    set cosAngle [ expr cos($rad2degrees) ];
	    set minusSinAngle [ expr -1.0 * $sinAngle ];
	    set minusCosAngle [ expr -1.0 * $cosAngle ];
	    
	    # Rotation Matrix
	    set rotMatrix {};
	    
	    if { ( $axis == "x" ) || ( $axis == "X" )  } {	    
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
	    set allRot [ atomselect $molID all ];
	    $allRot move $rotMatrix;
	    $allRot delete;
	    unset rotMatrix;
	}
	
	
	
	# get orientation of molecule
	# ============================	
	set allInfo [ getOrthogonalSystem $pointOrigin $pointAxis $pointPlane ];
	
	# spherical coordinates for main axis
	set oldUnitVector [ lindex $allInfo 0 ];
	foreach { oldRadius oldTheta oldPhi } [ getSphericalCoor $oldUnitVector ] { break };
	
	# rotation around main axis
	set oldUnitOrth [ lindex $allInfo 1 ];
	set oldRho [ lindex [ getSphericalCoor $oldUnitOrth ] 1 ];
	
	# main axis position
	set oldStartPoint $pointOrigin;
	
	
	
	# align with Z-axis and origin position
	# ======================================
	
	# align with origin
	set allSel [ atomselect $molID all ];
	$allSel moveby [ vecscale -1 $oldStartPoint ];
	
	# align with XZ plane : zero Phi
	set rotPhi [ expr -1.0*$oldPhi ];
	rotXYZ $molID z $rotPhi;
	
	# align with Z axis : zero Theta
	set rotTheta [ expr -1.0*$oldTheta ];
	rotXYZ $molID y $rotTheta;
	
	# align main axis rotation : zero Rho
	set rotRho [ expr -1.0*$oldRho ];
	rotXYZ $molID z $rotRho;
	
	
	
	# move to new position
	# =====================
	
	foreach { newRho newTheta newPhi } $new3Dcompass { break };
	
	rotXYZ $molID z $newRho;
	rotXYZ $molID y $newTheta;
	rotXYZ $molID z $newPhi;
	
	$allSel moveby $newOrigin;
	$allSel delete;
	
	
	
	proc RhoThePhi2refPoints { rho phi theta } {    
	    
	    # NOTE : if phi = 0, theta and rho are the same.
	    #        maybe set an assert condition, to exclude phi=0 & theta != 0
	    #        INDEED, ADD THIS CONDITION!!!
	    
	    # 1.- preliminary calculations and constants
	    # -------------------------------------------
	    
	    # rho from 0 to 2pi
	    # phi from 0 to pi
	    # theta from 0 to 2pi
	    
	    # convert angle to radians
	    set angle2rad [ expr 3.14159265359/180.0 ];
	    
	    set rhoRad [ expr $rho*$angle2rad ];
	    set phiRad   [ expr $phi*$angle2rad ];
	    set thetaRad [ expr $theta*$angle2rad ];
	    
	    set zAxis "0 0 1";
	    
	    	    
	    # 2.- quick scan for orthogonal axes positions and X-Y plane
	    # ------------------------------------------------------------
	    
	    set condOrth 1
	    
	    if { $phi == 0  } {
		set pointAxis  "0 0 1";
		set movedXaxis "1 0 0";				
	    } elseif { $phi == 90 } {		
		if { $theta == 0 } {
		    set pointAxis "1 0 0";
		} elseif { $theta == 90 } {
		    set pointAxis "0 1 0";
		} elseif { $theta == 180 } {
		    set pointAxis "-1 0 0";
		} elseif { $theta == 270 } {
		    set pointAxis "0 -1 0";
		} elseif { $theta == 360 } {
		    set pointAxis "1 0 0";
		} else {
		    set xPointAxis [ expr cos($thetaRad) ];
		    set yPointAxis [ expr sin($thetaRad) ] ;
		    set zPointAxis 0;
		    set pointAxis "$xPointAxis $yPointAxis $zPointAxis" ;
		}		
		set movedXaxis "0 0 -1";		
	    } elseif { $phi == 180 } {
		set pointAxis "0 0 -1";
		set movedXaxis "-1 0 0";		
	    } else {
		set condOrth 0;
	    }
	    
	    	    
	    # 3.- pointAxis for non-orthogonal and non-XYplane
	    # -------------------------------------------------- 	    
	    if { $condOrth == 0 } {		
		# 3.1.- from theta/phi to cartesian coordinate
		# -----------------------------------------------
		# http://mathworld.wolfram.com/SphericalCoordinates.html
		set newX [ expr cos($thetaRad)*sin($phiRad) ];
		set newY [ expr sin($thetaRad)*sin($phiRad) ];
		set newZ [ expr cos($phiRad) ];
		
		# these three points also define a plane orthogonal to pointAxis
		set pointAxis "$newX $newY $newZ";
				
		# 3.2.- plane between Z-axis and pointAxis
		# -----------------------------------------	
		# cross product : pointAxis X [ 0 0 1 ]
		set planePointAxisZ  [ veccross $pointAxis $zAxis ];
				
		# 3.3.- X-axis (1 0 0) moved to align with theta angle
		# ----------------------------------------------------	
		# X-axis moved to align with the line determined 
		# by two intersecting planes : pointAxis and planePointAxisZ
		# cross product :  pointAxis X planePointAxisZ 
		
		set movedXaxis  [ veccross $pointAxis $planePointAxisZ ];		
	    }
	    
	    
	    # 4.- vector orthogonal to pointAxis and movedAxis
	    # -------------------------------------------------	    
	    set orthPointMovedX [ veccross  $pointAxis $movedXaxis ];
	    
	    
	    # 5.- rho rotation
	    # -------------------	    
	    # normalize vectors
	    set pointAxis  [ vecnorm $pointAxis ];
	    set movedXaxis [ vecnorm $movedXaxis  ];
	    set orthPointMovedX [ vecnorm $orthPointMovedX ];
	    
	    # pointPlane
	    set cosRho [ expr cos($rhoRad) ];
	    set sinRho [ expr sin($rhoRad) ];	    
	    set vec1stAxis [ vecscale $cosRho $movedXaxis ];
	    set vec2ndAxis [ vecscale $sinRho $orthPointMovedX ];	    
	    set pointPlane [ vecadd $vec1stAxis $vec2ndAxis ];	    
	    
	    
	    # 6.- output
	    # -------------------	    
	    set pointOrigin "0 0 0";	    
	    lappend out $pointOrigin;
	    lappend out $pointAxis; 
	    lappend out $pointPlane;
	    
	    return $out;	    
	}
    
	set newRefPoints [ RhoThePhi2refPoints $newRho $newTheta $newPhi ];
	
	#set newPointOrigin [ lindex $newRefPoints 0 ]; # this is 0 0 0, no need	
	set newPointAxis   [ lindex $newRefPoints 1 ];
	set newPointAxis   [ vecadd $newOrigin $newPointAxis ];
	set newPointPlane  [ lindex $newRefPoints 2 ];	
	set newPointPlane  [ vecadd $newOrigin $newPointPlane ];

	set outNewRefPoint {};
	lappend outNewRefPoint $newOrigin;
	lappend outNewRefPoint $newPointAxis;
	lappend outNewRefPoint $newPointPlane;

	return $outNewRefPoint;
    }
    
    
    
    proc psfgenCOOR { psfList coorList outName } {	
	# check same number of items
	# ---------------------------
	set lenPSF  [ llength $psfList  ];
	set lenCOOR [ llength $coorList ];	
	if { $lenPSF != $lenCOOR } {
	    error "error: psfgenCOOR: different number of PSF and COOR : $psfList $coorList";
	} 	
	
	# create temporary files
	# -----------------------
	file mkdir $outName.COOR;
	
	set i 0;
	foreach eachPSF $psfList eachCOOR $coorList {
	    # load molecule
	    set molID0 [ mol new $eachPSF type psf waitfor all ];
	    mol addfile $eachCOOR waitfor all;
	    
	    # write tmp psf/pdb/coor
	    set selAll [ atomselect $molID0 all ];
	    animate write psf     ./$outName.COOR/$i.psf  sel $selAll waitfor all $molID0;
	    animate write namdbin ./$outName.COOR/$i.coor sel $selAll waitfor all $molID0;
	    $selAll set x 0;
	    $selAll set y 0;
	    $selAll set z 0;
	    animate write pdb     ./$outName.COOR/$i.pdb  sel $selAll waitfor all $molID0;
	    
	    # clean
	    $selAll delete;
	    mol delete $molID0;
	    incr i;
	}
		
	# join structures
	# ----------------
	package require psfgen;
	resetpsf;
	
	set j 0;
	while { $j < $lenPSF } {    
	    readpsf  ./$outName.COOR/$j.psf;
	    coordpdb ./$outName.COOR/$j.pdb;
	    incr j;
	}
    
	writepsf ./$outName.COOR/$outName.psf;
	writepdb ./$outName.COOR/$outName.pdb;
	resetpsf;
	
	# remap coordinates
	# ------------------    
	set molID1 [ mol new ./$outName.COOR/$outName.psf type psf waitfor all ];
	mol addfile ./$outName.COOR/$outName.pdb waitfor all;
	
	set k 0;
	while { $k < $lenPSF } {    	
	    # coor files
	    set molID2 [ mol new ./$outName.COOR/$k.psf type psf waitfor all ];
	    mol addfile ./$outName.COOR/$k.coor waitfor all;
	    
	    set selOneSeg [ atomselect $molID2 all ];
	    set segName   [ lsort -unique [ $selOneSeg get segname ] ];
	    
	    set xOneSeg [ $selOneSeg get x ];
	    set yOneSeg [ $selOneSeg get y ];
	    set zOneSeg [ $selOneSeg get z ];
	    
	    # large structure
	    set selLarge [ atomselect $molID1 "segname $segName" ];
	    $selLarge set x $xOneSeg;
	    $selLarge set y $yOneSeg;
	    $selLarge set z $zOneSeg;
	    
	    # clean
	    $selLarge  delete;
	    $selOneSeg delete;
	    mol delete $molID2;    
	    incr k;
	}
        
	# write big structure
	set selAll [ atomselect $molID1 all ];
	animate write namdbin ./$outName.COOR/$outName.coor sel $selAll waitfor all $molID1;
	file rename ./$outName.COOR/$outName.coor ./$outName.coor
	file rename ./$outName.COOR/$outName.psf  ./$outName.psf
	
	# clean
	mol delete $molID1;
	file delete -force ./$outName.COOR;  
    }
    

       

    ############## MAIN ############
    
    
    ##################################
    # 1st
    ##################################
    
    # random orientations
    randomInit $seed;
    
    for { set i 1 } { $i <= $iGrid } { incr i } {	
	for { set j 1 } { $j <= $jGrid } { incr j } {	    
	    for { set k 1 } { $k <= $kGrid } { incr k } {		
		set x [ expr $i*$lengthGrid ];
		set y [ expr $j*$lengthGrid ];
		set z [ expr $k*$lengthGrid ];		
		set gridXYZ($i,$j,$k) "$x $y $z";
		
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		# NOTE: include options to read orientation
		#       so you can create aligned structures
		# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		# rho from 0 to 2pi - internal rotation
		# theta from 0 to 2pi - spherical coordinates
		# phi from 0 to pi    - spherical coordinates		
		# documentation for spherical coordinates taken from mathematica
		# http://mathworld.wolfram.com/SphericalCoordinates.html
		
		set rho   [ randomRange 360 ];
		set theta [ randomRange 360 ];
		set phi   [ randomRange 180 ];
		
		set gridAngles($i,$j,$k) "$rho $theta $phi";

		unset rho;
		unset theta;
		unset phi;		
	    }	    
	}	
    }    
    set lengthGrid [ array size gridAngles ];        
    
    
    ##################################
    # 2nd
    ##################################
        
    # temporal working directory
    file mkdir $outName;
        
    # temporal PSF and PDB files with unique segnames  
    for { set tmp 0 } { $tmp < $lengthGrid } { incr tmp } {	
	set molID0 [ mol new $psfFile type psf waitfor all ];
	mol addfile $pdbFile waitfor all;
		
	# define unique chain name
	set chainName [ chainNameGMX $tmp ];
	
	# create PDB with unique chain name  	
	set selAll [ atomselect $molID0 all ];
	$selAll set segname $chainName;
	$selAll delete;
	    
	# write tmp structure
	animate write psf     ./$outName/$tmp.psf  waitfor all $molID0;
	animate write namdbin ./$outName/$tmp.coor waitfor all $molID0;

	mol delete $molID0;	
    }
        
    
    
    
    ##################################
    # 3rd
    ##################################
    
    set tmp 0;
    set listRefPoints {};
    set listPSF  {};
    set listCOOR {};
        
    for { set i 1 } { $i <= $iGrid } { incr i } {	
	for { set j 1 } { $j <= $jGrid } { incr j } {	   
	    for { set k 1 } { $k <= $kGrid } { incr k } {
		set molID1 [ mol new ./$outName/$tmp.psf type psf waitfor all ];
		mol addfile ./$outName/$tmp.coor waitfor all;		
		       		
		set pointOrigin "0 0 0";
		set pointAxis   "0 0 1";
		set pointPlane  "1 0 0";
	      
		set newOrigin    $gridXYZ($i,$j,$k);
		set new3Dcompass $gridAngles($i,$j,$k);
		
		set eachNewRefPoint [ moveBody $molID1 $pointOrigin $pointAxis $pointPlane $newOrigin $new3Dcompass ]; 
		
		set all [ atomselect $molID1 all ];
		set segTMP [ lsort -unique [ $all get segname ] ];
		animate write namdbin ./$outName/$tmp.coor sel $all waitfor all $molID1;
		$all delete;

		# for log (RP) file
		lappend listRefPoints "$segTMP $eachNewRefPoint";

		# lists for psfgenCOOR
		lappend listPSF       ./$outName/$tmp.psf;
		lappend listCOOR      ./$outName/$tmp.coor;
		
		# clean
		mol delete $molID1;
		incr tmp;		
	    }
	}
    }        
    
    
    ##################################
    # 4th ConcatDCD and erase
    ##################################

    # join structures
    psfgenCOOR $listPSF $listCOOR $outName;
    
    # center molecule
    set molID2 [ mol new ./$outName.psf type psf waitfor all ];
    mol addfile ./$outName.coor waitfor all;		
        
    set selAll [ atomselect $molID2 all ];
    set shiftCenter [ vecscale -1 [ measure center $selAll ] ];
    $selAll moveby  $shiftCenter;

    animate write namdbin ./$outName.coor sel $selAll waitfor all $molID2;
    
    $selAll delete;    
    mol delete $molID2;
    
    # as the molecule was centered, need to move the reference points too!
    set movedRefPoints {};
    
    foreach oneLine $listRefPoints {	
	set item0 [ lindex $oneLine 0 ];
	set item1 [ lindex $oneLine 1 ];
	set item2 [ lindex $oneLine 2 ];
	set item3 [ lindex $oneLine 3 ];

	set item1 [ vecadd $item1 $shiftCenter ];
	set item2 [ vecadd $item2 $shiftCenter ];
	set item3 [ vecadd $item3 $shiftCenter ];

	set tmpList {}
	lappend tmpList $item0;
	lappend tmpList $item1;
	lappend tmpList $item2;
	lappend tmpList $item3;	
	lappend movedRefPoints $tmpList;
	unset tmpList;
    }
    
    # clean
    file delete -force ./$outName;
            
    
    ##################################
    # 5th logfile
    ##################################    
    set outLog [ open $outName.rp w ];
    
    puts $outLog "lengthGrid   :: $lengthGrid ";
    puts $outLog "iGrid        :: $iGrid";
    puts $outLog "jGrid        :: $jGrid";
    puts $outLog "kGrid        :: $kGrid";
    puts $outLog "outName      :: $outName";
    puts $outLog "seed         :: $seed";
    puts $outLog "gridAngIJK   :: [ array get gridAngles ]";
    #puts $outLog "newRefPoints :: $listRefPoints";
    puts $outLog "newRefPoints :: $movedRefPoints";
    close $outLog;

}


# close namespace
}

############################################################
#
#
#
#
# 
#
#
#

package provide nanocomposite 0.1

namespace eval ::NanoComposite:: {
    namespace export nnc*

proc nncphantomVolume { args } {

    # Set the defaults
    set shellXYZ 5.0;
    set dxGrid 2.0;

    # Parse options
    for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	set arg [ lindex $args $argnum ]
	set val [ lindex $args [expr $argnum + 1]]
	switch -- $arg {
	    "-psf"     { set psfFile  $val; incr argnum; }
	    "-pdb"     { set pdbFile  $val; incr argnum; }
	    "-within"  { set shellXYZ $val; incr argnum; }
	    "-dxRes"   { set dxGrid   $val; incr argnum; }
	    "-outName" { set outName  $val; incr argnum; }
	    default { error "error: phantomVolume: unknown option: $arg" }
	}
    }

    # check non-default variables    
    set checkPSF         [ info exists psfFile ];
    set checkPDB         [ info exists pdbFile ];
    set checkOUTNAME     [ info exists outName ];

    if { $checkPSF < 1 } {
        error "error: phantomVolume: need to define variable -psf"
    }
    if { $checkPDB < 1 } {
        error "error: phantomVolume: need to define variable -pdb"
    }
    if { $checkOUTNAME < 1 } {
        error "error: phantomVolume: need to define variable -outName"
    }



    
    # -----------------
    # start procedures
    # -----------------
    
    proc dummyBlock { args } {	

	# Parse options
	for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	    set arg [ lindex $args $argnum ]
	    set val [ lindex $args [expr $argnum + 1]]
	    switch -- $arg {
		"-psf"         { set psfFile       $val; incr argnum; }
		"-pdb"         { set pdbFile       $val; incr argnum; }
		"-shellXYZ"    { set shellXYZ      $val; incr argnum; }
		"-outName"     { set outName       $val; incr argnum; }
		default { error "error: phantomVolume: unknown option: $arg" }
	    }
	}
	
	
	# ------------
	# procedures
	# ------------
	
	# put a number, get a chain name
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
	
	
	proc uCell4block { outName } {
	    # PSF unit cell
	    set outPSF [ open $outName.UnitCell.psf w ];
	    puts $outPSF "PSF";
	    puts $outPSF " ";
	    puts $outPSF "       1 !NTITLE";
	    puts $outPSF " REMARKS VMD-generated NAMD/X-Plor PSF structure file";
	    puts $outPSF " ";
	    puts $outPSF "       8 !NATOM";
	    puts $outPSF "       1 XYZ  1    XYZ  X00  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       2 XYZ  1    XYZ  X01  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       3 XYZ  1    XYZ  X02  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       4 XYZ  1    XYZ  X03  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       5 XYZ  1    XYZ  X04  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       6 XYZ  1    XYZ  X05  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       7 XYZ  1    XYZ  X06  XYZ    0.000000        0.0000           0";
	    puts $outPSF "       8 XYZ  1    XYZ  X07  XYZ    0.000000        0.0000           0";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NBOND: bonds";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NTHETA: angles";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NPHI: dihedrals";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NIMPHI: impropers";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NDON: donors";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NACC: acceptors";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       0 !NNB";
	    puts $outPSF " ";
	    puts $outPSF "       0       0       0       0       0       0       0       0";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    puts $outPSF "       1       0 !NGRP";
	    puts $outPSF "       0       0       0";
	    puts $outPSF " ";
	    puts $outPSF " ";
	    close $outPSF;
	    
	    # PDB unit cell
	    set outPDB [ open $outName.UnitCell.pdb w ];
	    puts $outPDB "CRYST1    2.000    2.000    2.000  90.00  90.00  90.00 P 1           1"
	    puts $outPDB "ATOM      1  X00 XYZ X   1       0.000   0.000   0.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      2  X01 XYZ X   1       1.000   0.000   0.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      3  X02 XYZ X   1       0.000   1.000   0.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      4  X03 XYZ X   1       1.000   1.000   0.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      5  X04 XYZ X   1       0.000   0.000   1.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      6  X05 XYZ X   1       1.000   0.000   1.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      7  X06 XYZ X   1       0.000   1.000   1.000  0.00  0.00      XYZ   "
	    puts $outPDB "ATOM      8  X07 XYZ X   1       1.000   1.000   1.000  0.00  0.00      XYZ   "
	    puts $outPDB "END"
	    puts $outPDB " "
	    close $outPDB;
	}
	
	# ---------------
	# end procedures
	# ---------------
	
	
	############# MAIN #############
	
	
	# structure minmax
	# -----------------
	mol load psf $psfFile pdb $pdbFile;
	set molID0 [ molinfo top ];
	
	set selCrystal [ atomselect $molID0 all ]
	set xyzMinMax  [ measure minmax $selCrystal ];
	
	$selCrystal delete;    
	mol delete $molID0;
        
	# number of repeats
	# ------------------
	foreach { xyzMin xyzMax } $xyzMinMax { break };
	foreach { xMin yMin zMin } $xyzMin { break };
	foreach { xMax yMax zMax } $xyzMax { break };
	
	# make block 1.5*shellXYZ larger, to smooth a fine grid.
	set shellXYZ3 [ expr 3.0*$shellXYZ ];
	set xLength   [ expr $xMax - $xMin + $shellXYZ3 ];
	set yLength   [ expr $yMax - $yMin + $shellXYZ3 ];
	set zLength   [ expr $zMax - $zMin + $shellXYZ3 ];
	
	set shellXYZ1_5   [ expr 1.5*$shellXYZ ];
	set bottomCornerX [ expr $xMin - $shellXYZ1_5 ];
	set bottomCornerY [ expr $yMin - $shellXYZ1_5 ];
	set bottomCornerZ [ expr $zMin - $shellXYZ1_5 ];
	set bottomCorner  "$bottomCornerX $bottomCornerY $bottomCornerZ";
	
	set xRepeat [ expr int( ceil($xLength/2.0) ) ]
	set yRepeat [ expr int( ceil($yLength/2.0) ) ]
	set zRepeat [ expr int( ceil($zLength/2.0) ) ]
        
	# unit cell
	# ----------
	uCell4block $outName;    
	set ucPdbFile $outName.UnitCell.pdb;
	set ucPsfFile $outName.UnitCell.psf;
	
	# periodic vectors
	# -----------------
	set movePerX "2.0 0.0 0.0";
	set movePerY "0.0 2.0 0.0";
	set movePerZ "0.0 0.0 2.0";
        
	# repeat unit cell
	# ------------------
	file mkdir $outName.BLOCK
	
	set numPDBPSF [ expr $xRepeat *$yRepeat *$zRepeat  ];
	
	set pdbCounter 0;
	set resCounter 0;
	set segCounter 0;
	
	set zCounter 0;
	while { $zCounter < $zRepeat } {
	    
	    set yCounter 0;
	    while { $yCounter < $yRepeat } {
		
		set xCounter 0;
		while { $xCounter < $xRepeat } {
		    
		    if { $resCounter > 9999 } {
			set resCounter 0;
			incr segCounter;
		    } else {
		    }
		    
		    # load structure
		    mol load psf $ucPsfFile pdb $ucPdbFile;
		    set molID02 [ molinfo top ];
		    
		    # set resid-segid-segname
		    set all02   [ atomselect $molID02 all ];
		    $all02 set resid  $resCounter;
		    set segName [ chainName3 $segCounter ];
		    $all02 set segname $segName;
		    $all02 set segid   $segName;
		    
		    # displacement vector
		    set moveX   [ vecscale $xCounter $movePerX ];
		    set moveY   [ vecscale $yCounter $movePerY ];
		    set moveZ   [ vecscale $zCounter $movePerZ ];
		    set moveAll [ vecadd   $moveX $moveY $moveZ ];	    
		    
		    # move unit cell
		    $all02 moveby   $moveAll;
		    $all02 writepdb $outName.BLOCK/$outName.$pdbCounter.pdb;
		    $all02 writepsf $outName.BLOCK/$outName.$pdbCounter.psf;
		    $all02 delete;
		    mol delete $molID02;
		    
		    incr pdbCounter;
		    incr resCounter;
		    incr xCounter;
		}
		incr yCounter;
	    }    
	    incr zCounter;  
	}
        
	# join structures
	# ----------------    
	package require psfgen;
	resetpsf;
	
	set numCells $pdbCounter;
	set pdbCounter 0;
	
	while { $pdbCounter < $numCells } {	
	    readpsf  $outName.BLOCK/$outName.$pdbCounter.psf;
	    coordpdb $outName.BLOCK/$outName.$pdbCounter.pdb;	
	    incr pdbCounter;
	}
	
	writepsf $outName.BLOCK.psf;
	writepdb $outName.BLOCK.pdb;
	resetpsf;
        
	# move to bottom corner
	# ----------------------    
	mol load psf $outName.BLOCK.psf pdb $outName.BLOCK.pdb;
	set molID3 [ molinfo top ];
	set selBlock [ atomselect $molID3 all ];
	
	set minmaxBlock [ measure minmax $selBlock ];
	foreach { minBlock maxBlock } $minmaxBlock { break };
	set moveVec [ vecsub $bottomCorner $minBlock ]
	$selBlock moveby $moveVec;
	
	$selBlock writepsf $outName.BLOCK.psf;
	$selBlock writepdb $outName.BLOCK.pdb;
        
	# clean
	# ------
	$selBlock delete;
	mol delete $molID3;
	file delete -force ./$outName.BLOCK;
	file delete $outName.UnitCell.pdb;
	file delete $outName.UnitCell.psf;
    }
    
    

    proc str2block { args } {
	
	# Set the defaults
	set massRad 2.0;

	# Parse options
	for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	    set arg [ lindex $args $argnum ]
	    set val [ lindex $args [expr $argnum + 1]]
	    switch -- $arg {
		"-psfTarget" { set psfTarget $val; incr argnum; }
		"-pdbTarget" { set pdbTarget $val; incr argnum; }
		"-psfBlock"  { set psfBlock  $val; incr argnum; }
		"-pdbBlock"  { set pdbBlock  $val; incr argnum; }	    
		"-shellXYZ"  { set shellXYZ  $val; incr argnum; }
		"-massRad"   { set massRad   $val; incr argnum; }
		"-outName"   { set outName   $val; incr argnum; }
		default { error "error: str2block: unknown option: $arg" }
	    }
	}
	
        
	# ------------
	# procedures
	# ------------
	proc addNum2List { num2add listNum } {	
	    set outList "";	
	    foreach eachNum $listNum {
		lappend outList [ expr $eachNum + $num2add ];
	    }	
	    return $outList;
	}
	
	package require psfgen;
	
	# ---------------
	# end procedures
	# ---------------
	
	
	################ MAIN #################
	
	# 2.- combine Target and Block
	# ============================    
	resetpsf;	
	readpsf  $psfTarget;
	coordpdb $pdbTarget;	
	readpsf  $psfBlock;
	coordpdb $pdbBlock;
	
	writepsf $outName.TMP1.psf
	writepdb $outName.TMP1.pdb
	
	resetpsf;
	psfcontext reset;		
    
	# 3.- data from Target
	# ======================
	
	# load Target structure
	set molID00 [ mol new $psfTarget type psf waitfor all ];
	mol addfile $pdbTarget waitfor all;
	
	# dimensions
	set selAll [ atomselect $molID00 all ];
	foreach { xCen yCen zCen } [ measure center $selAll ] { break };
	
	set indexTarget [ $selAll get index ];
	
	# clean
	$selAll delete;
	mol delete $molID00;
		
	# 4.- small structure 
	# ====================
	
	# load merged structure
	set molID01 [ mol new $outName.TMP1.psf type psf waitfor all ];
	mol addfile $outName.TMP1.pdb waitfor all;
	
	# select beads near Target
	set nearSel [ atomselect $molID01 "(all within $shellXYZ of index $indexTarget) and not (index $indexTarget)" ];
	$nearSel set beta 0;
	$nearSel set occupancy 0;
	
	# write out selection
	animate write psf $outName.TMP2.psf sel $nearSel $molID01;
	animate write pdb $outName.TMP2.pdb sel $nearSel $molID01;
	
	# clean
	$nearSel delete;
	mol delete $molID01;
	file delete $outName.TMP1.psf;
	file delete $outName.TMP1.pdb;
			
	# 5.- reset masses
	# =================	
	set molID02 [ mol new $outName.TMP2.psf type psf waitfor all ];
	mol addfile $outName.TMP2.pdb waitfor all;
	
	set selAll [ atomselect $molID02 all ];
	$selAll set mass 1.0;
	
	set condMass 0;
	set iMass 1;
	set prevNum 0;
	
	while { $condMass == 0 } {
	    
	    set currRad [ expr $iMass * $massRad ];
	    
	    set selCurrRing [ atomselect $molID02 "((x-$xCen)*(x-$xCen))  + ((y-$yCen)*(y-$yCen)) + ((z-$zCen)*(z-$zCen)) < ($currRad*$currRad)" ];
	    
	    set currNum [ $selCurrRing num ];
	    set diffNum [ expr abs($currNum - $prevNum )];
	    
	    if { $diffNum > 0 } {
		set prevNum $currNum;
		
		# new masses
		set massList [ $selCurrRing get mass ];
		set massList [ addNum2List 1.0 $massList];	
		$selCurrRing set mass $massList	    
	    } else {
		set condMass 1;
	    }
	    
	    $selCurrRing delete;	
	    incr iMass;	
	}	    
    
	# 6.- comon properties
	# =====================    
	set selAll [ atomselect $molID02 all ];
	$selAll set type X;
	$selAll set name X;
	$selAll set element X;
	$selAll set resname GRID;
	$selAll set charge 0.0;
	
	# 7.- write PSF/PDB structures
	# =============================
	
	# write out selection
	animate write psf $outName.GRID.psf sel $selAll $molID02;
	animate write pdb $outName.GRID.pdb sel $selAll $molID02;
	
	# 8.- clean
	# ==========
	$selAll delete;
	mol delete $molID02;
	file delete $outName.TMP2.psf;
	file delete $outName.TMP2.pdb;        
    }


    ################ MAIN ##################

    # 1.- create block 
    dummyBlock -psf $psfFile -pdb $pdbFile -shellXYZ $shellXYZ -outName $outName;

    # 2.- assign masses in radial form
    str2block -psfTarget $psfFile -pdbTarget $pdbFile -psfBlock $outName.BLOCK.psf -pdbBlock $outName.BLOCK.pdb -shellXYZ $shellXYZ -outName $outName

    # 3.- write DX file
    set molID [ mol new $outName.GRID.psf type psf waitfor all ];
    mol addfile $outName.GRID.pdb waitfor all;
    
    set selAll [ atomselect $molID all ];
    volmap density  $selAll  -res $dxGrid -weight mass -mol $molID -o $outName.dx;
    
    # 4.- clean
    $selAll delete;
    mol delete $molID;
    file delete $outName.BLOCK.psf;
    file delete $outName.BLOCK.pdb;
    file delete $outName.GRID.psf;
    file delete $outName.GRID.pdb;
    
}

}


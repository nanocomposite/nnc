
package provide nanocomposite 0.1


proc nnc { args } {

    proc usage {} {
	vmdcon -info {usage: nnc <command> [args...]
	    
	    Create grid:
	     randomGrid [options...]
	    
	    Collapse grid to a point:
	     geoCollapse [options...]

            Create exclusion region:
             phantomBody [options...]

            Create NAMD configuration file:
             namdConf [options...]	    
	}

	return
    }

    
    if { [llength $args] < 1 } then { usage; return }
    set command [ lindex $args 0 ]
    set args [lrange $args 1 end]
    set fullcommand "::NanoComposite::nnc$command"

    
    if { [ string length [namespace which -command $fullcommand]] } then {
	eval "$fullcommand $args"
    } else { usage; return }

}




# nanocomposite


**nanocomposite**  is a computational tool to build nanocomposites of increasing complexity using annealing MD cycles.  Some examples of the structures created with **nanocomposite** are available at:

https://github.com/nanocomposite/Structures


**nanocomposite**  is integrated into a TCL-package to be used with [VMD](https://www.ks.uiuc.edu/Research/vmd/).   It employs the VMD-plugins PSFGEN and VOLMAP to create grid structures and exclusion grids, respectively.  It also prepares configuration files to carry out a variety of MD simulations with the molecular dynamics (MD) program [NAMD](https://www.ks.uiuc.edu/Research/namd/).  Thus, in order to use **nanocomposite**, it is required to have a working knowledge of VMD and NAMD.  To ease the usage of **nanocomposite**, a tutorial with the basic examples is available at:

https://github.com/nanocomposite/nncTutorial


The installation of **nanocomposite** proceeds as follows:

* Download from

  https://github.com/nanocomposite/nnc
   
* Open VMD, then the TK window and specify the location by typing:

  lappend ::auto_path $DIR

  where \$DIR is the path to the {\bf nanocomposite} directory in your local computer

* Load:

   package require nanocomposite



The path for the **nanocomposite** directory can also be saved in the .vmdrc file,  by adding the line:

* lappend ::auto_path $DIR


Once loaded, the different routines can be called using the prefix **nnc** as follows:

* **nnc** *command [ -options ]*


Currently, **nanocomposite** provides four commands:

* *randomGrid* : creates a spaced grid of randomly oriented structures.
* *geoCollapse* : aggregates the grid structures by using translations and rotations.
* *phantomVolume* : maps an exclusion grid with the shape of a molecule.
* *namdConfiguration* : writes NAMD configution files to perform MD simulations.

Each command provides different options.  For the most common tasks, default options are included; for example, during the geometric collapse step (**nnc** *geoCollapse*), the aggregated structures end up separated by a default distance of 1~nm.    Such distance can be changed using the flag *-gapLength* to aggregate the grid structures either closer or further apart.  Detailed descriptions of the different **nanocomposite** options are provided in the [tutorial](https://github.com/nanocomposite/nncTutorial).

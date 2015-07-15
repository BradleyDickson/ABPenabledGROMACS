# ABPenabledGROMACS
A hacked, hardwired GROMACS-4.5.5 that runs mABP, well-tempered metadynamics, or a SHUS-based tempered metadynamics for alanine dipeptide. 

This code is modified for the following functions:

- Compute Phi-Psi free energy via mABP

- Compute Phi-Psi free energy via well-tempered metadynamics

- Compute Phi-Psi free energy via an alternate tempered metadynamics

**This is not standard gromacs, don't use it for anything outside of alanine dipeptide unless you modify md.c and hellof.f to match your application!**

The biasing code can be found [here]. There are comments and the code is easy to read if you can stomach going back to 1985. You wont need a DeLorean.

All the things required for building simulation inputs are also included in the [ALANINEsystem] sub directory.

# To Build:
1. Go to the ABPenabledGROMACS directory.

2. Run the ./configure command with whatever options you need to use. Use --prefix=PATH-TO-YOUR-ABPenabledGROMACS to install the executable to the location expected by the Run-mABP/ Run-WTmetaD/ and Run-SHUSish directories.

3. Run make clean

4. cd to src/kernel and compile hello.f with gfortran -O3 -fbounds-check -c hello.f The file hello.f is a fortran routine written very transparently so that each method can be cleanly compared to the other.

5. Edit src/kernel/Makefile as follows:
 - Line 144 should read: md_openmm.$(OBJEXT) hello.o
 - Line 232 should read: LIBS = -lnsl -lm -lgfortran

6. Run make install from the ABPenabledGROMACS directory

# To run simulations of alanine dipeptide
1. Go to ABPenabledGROMACS/ALANINEsystem and build a new tpr file:
 - ../bin/grompp -f md.mdp -c isob.gro -t isob.cpt -o ala.tpr

2. Copy this ala.tpr file into the run directories: Run-mABP Run-WTmetaD Run-SHUSish and edit the params.in file to your liking

3. Simulations can be launched within these run directories with ./mdrun -v -deffnm ala 

4. You can adjust the parameters and see how things change. 

# Outputs

1. The simulations will write a file named "freeE" that contains the current free energy estimate. The Phi-Psi angles are given in the first two columns, the free energy estimate is given in the third column.

2. Simulations also write a file named "fort.88" The first column is timestep, second and third columns are collective variables (angles), the fourth column is the convergence metric (equation 31 in the paper)

[here]: https://github.com/BradleyDickson/ABPenabledGROMACS/blob/master/ABPenabledGROMACS/src/kernel/hello.f
[ALANINEsystem]: https://github.com/BradleyDickson/ABPenabledGROMACS/tree/master/ABPenabledGROMACS/ALANINEsystem

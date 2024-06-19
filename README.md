# src/ 
- contains the source codes for the CM1 v21.0
- The code is modified to accomodate online time-averaging, passive tracer, and more terrain choices.

The main modifications are:
- in tmea.F: online time-averaging routine developed by Jan Weinkaemmerer, adapted to v20.3 by Ivan Basic
- in solve1.F and solve2.F: passive tracer flux added (ptflux)
- in init_terrain.F: more terrain choices

To quickly find the modifications, search "Ivan Basic" or "Jan Weinkaemmerer" to see the changes.

The code can be run in its original form as well, just by setting the following switches in namelist.input:

iptra = 0,
dotmea = .false.

# RUN_CM1
- contains the scripts to run the simulation and/or to submit a recursive run utilising restarts (used for longer simulations).
- see README the instructions on how to use it.

For any additional quetsions, fire an email to: basic@iau.uni-frankfurt.de

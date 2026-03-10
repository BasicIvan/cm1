## src/ 
Contains the source codes for the CM1 v21.1, with expanded functionality and important bug fixes for LES simulations.

### The added functionalities are:
- in tmea.F: online time-averaging routine developed by Jan Weinkaemmerer, adapted to v20.3, v21.0 and v21.1  by Ivan Basic
- passive tracer: it is possible to load a NetCDF with passive tracer ground fluxes (time,x,y,npt)
- in init_terrain.F: more terrain choices and it is possible to load custom NetCDF with terrain (z,x,y)
- init_surface.F: custom landuse index map by loading a NetCDF (x,y)

To quickly find the modifications, search "Ivan Basic" (or such) to see the changes.

To run with all settings, set the switches in the namelist.input:
- iptra = 1 (or more)
- dotmea = .true.
- itern = 12
- initsfc = 5

## RUN_CM1/
- contains the scripts to run the simulation and/or to submit a recursive run utilising restarts (used for longer simulations).
- see README on how to use it.

For any additional questions, fire an email to: basic@iau.uni-frankfurt.de

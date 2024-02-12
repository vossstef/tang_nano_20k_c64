#!/bin/bash

if [ ! -d sim ]
then
 mkdir sim
fi

if [ -d sim/work ]
then
 rm -Rf sim/work
fi

if [ -f sim/sim.mpf ]
then
 rm -Rf sim/sim.mpf
fi

vsim -do sim_c64.do



rmdir /s /q sim
if not exist sim\ mkdir sim

#vsim -do sim_dualshock.do
vsim -do sim_vlg_dualshock.do

rmdir /s /q sim
if not exist sim\ mkdir sim
vsim -do sim_c64.do

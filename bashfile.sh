#!/bin/bash
shopt -s expand_aliases
# 1 is ILP, 2 is BBC
for F in 0 7 31 183
do
	for id in {13}
	do
		julia -t 4 src/RRSP_script.jl 1 $id 3 $F |& tee -a ./debug/blossom/SaveConsole_alpha3_ILP.txt
		julia -t 4 src/RRSP_script.jl 2 $id 3 $F |& tee -a ./debug/blossom/SaveConsole_alpha3_BBC.txt
		julia -t 4 src/RRSP_script.jl 1 $id 5 $F |& tee -a ./debug/blossom/SaveConsole_alpha5_ILP.txt
		julia -t 4 src/RRSP_script.jl 2 $id 5 $F |& tee -a ./debug/blossom/SaveConsole_alpha5_BBC.txt
		julia -t 4 src/RRSP_script.jl 1 $id 7 $F |& tee -a ./debug/blossom/SaveConsole_alpha7_ILP.txt
		julia -t 4 src/RRSP_script.jl 2 $id 7 $F |& tee -a ./debug/blossom/SaveConsole_alpha7_BBC.txt
	done
done
for id in {1..13} 
	do julia -t auto src/RRSP_script.jl 2 $id 3 |& tee -a ./debug/explore_F/SaveConsole_Explore_F.txt
done


for F in 7 31 183
do
	julia -J 1-R-RSPSysImageEnv/1-R-RSPSysimage.so -t 4 src/RRSP_script.jl 1 13 3 $F |& tee -a ./debug/blossom/SaveConsole_alpha3_ILP.txt
	julia -J 1-R-RSPSysImageEnv/1-R-RSPSysimage.so -t 4 src/RRSP_script.jl 2 13 3 $F |& tee -a ./debug/blossom/SaveConsole_alpha3_BBC.txt
done
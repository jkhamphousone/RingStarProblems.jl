Scripting:

for i in 0 1 2 4; do j7 src/RhoRSP_script.jl 1 5 $i 500; done ; for i in 2000 10000; do j7 src/RhoRSP_script.jl 1 5 4 $i ; done

rsync

# LONGCHAMP
dTCode ; rsync -avr --rsh='ssh -p 5022' RhoRSP/ jkhamphousone@ssh.lamsade.dauphine.fr:mnt/RhoRSP/RhoRSP
dTCode ; rsync -avr --rsh='ssh -p 5022' RRSP/ jkhamphousone@ssh.lamsade.dauphine.fr:mnt/RRSP/RRSP

# VM
dTCode ; rsync -avr --rsh='ssh -p 5022' RhoRSP/ jkhamphousone@ssh.lamsade.dauphine.fr:mnt/RhoRSP
dTCode ; rsync -avr --rsh='ssh -p 5022' RRSP/ jkhamphousone@ssh.lamsade.dauphine.fr:mnt/RRSP

------------------------------------------------------------
      α parameter —— instance name —— instance nb. of nodes
------------------------------------------------------------

——————— Date of running ——————— nb of run ———————
ILP ——— Nb of hubs in best solution found
time          ——— total ILP time (TL value indicated if Time Limit reached)       
gap           ——— relative gap computed by solver     
opt/best_bd   ——— best objective value found and best objective bound found
subtour       ——— nb of subtour cuts

BD  ——— Nb of hubs in best solution found
time                ——— total BD time (TL value indicated if Time Limit reached)
gap                 ——— relative gap computed by solver       
opt/best_bd         ——— best objective value found and best objective bound found
subtour             ——— nb of subtour cuts
SP time             ——— Subproblem time
cuts                ——— nb of optimality cuts  
Master time         ——— Master time
inst transformation ——— 0 is no instance transformation
                        1 is inst. trans. objective_transformation_3.pdf page 3
                        2 is inst. trans. objective_transformation_3.pdf page 5
SP method           ——— Alg pure algorithmic method
                        Hybrid

------------------------------------------------------------
EXEMPLE             α=5 —— tiny_instance_7_2 —— 7 nodes
------------------------------------------------------------

——————— Wed, 01 Dec 2021 13:38:13 ——————— 1 run ———————
ILP ——— 5 hubs
time 1.62           gap 0.0      opt/best_bd 2455.0/2455.0   subtour 2.0

BD  ——— 5 hubs
total time   3.67            gap                  0.0
opt/best_bd  2455.0/2455.0   subtour              8.0
SP time      1.93            cuts                 77.0
Master time  1.73            inst transformation  1
SP method    Hybrid

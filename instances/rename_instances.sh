#!/bin/bash
position=20

for f in *dat; do
   mv -- "$f" "${f:0:$position-1}${f:$position}"
done

exit

#!/bin/bash
rm -i output.file output_temp.file summary
outer=1             # Set outer loop counter.

# Beginning of outer loop.
for a in 2 
do
  inner=1           # Reset inner loop counter.
  echo "\n===========================================OUTER : $a =======================================\n" >> output.file
  echo "\n===========================================OUTER : $a =======================================\n" >> summary

  # ===============================================
  # Beginning of inner loop.
  for b in range(2,20) 
  do

  	echo "\n-------------------------------------------------------INNER : $b --------------------------------\n" >> output.file
  	echo "\n-------------------------------------------------------INNER : $b --------------------------------\n" >> summary
	time sudo mn --switch ovsk --controller ref --topo tree,depth=$a,fanout=$b --test pingall 2>&1 | tee output_temp.file
	echo "time sudo mn --switch ovsk --controller ref --topo tree,depth=$a,fanout=$b --test pingall 2>&1 | tee output_temp.file" >> output.file
	echo "time sudo mn --switch ovsk --controller ref --topo tree,depth=$a,fanout=$b --test pingall 2>&1 | tee output_temp.file" >> summary
	cat output_temp.file >> output.file
	tail -n 3 output.file >> summary
		
	#let "inner+=1"  # Increment inner loop counter.
  done
  # End of inner loop.
  # ===============================================

  #let "outer+=1"    # Increment outer loop counter. 
  echo              # Space between output blocks in pass of outer loop.
done 

echo "\n\n\n====================All Experiments Finished==================\n"

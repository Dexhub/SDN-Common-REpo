#!/bin/bash
for i in 100 
do


		
	perl start_latest_new.pl 16 8 0 $1 navid_16_8_0_$1_initial 1 $3_20_d0_e$i.txt
	perl start_latest_new.pl 16 8 0 $1 navid_16_8_0_$1_d1 0 $3_20_d0_e$i.txt
	perl multi_path_routing.pl navid_16_8_0_$1_d1 routing_navid_16_8_0_$1_d1
	perl clean_topo.pl navid_16_8_0_$1_d1 navid_16_8_0_$1_d1_c
	./$4 navid_16_8_0_$1_d1_c routing_navid_16_8_0_$1_d1 $3 20 $i $5 > data/results_navid_16_8_0_$1_d1_$3_20_e$i$5.txt
	perl store_traffic_matrix.pl data/results_navid_16_8_0_$1_d1_$3_20_e$i.txt $3_20_d12_e$i$5.txt


done




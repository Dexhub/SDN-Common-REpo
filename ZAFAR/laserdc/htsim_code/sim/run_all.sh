# The first number is the number of tors and the second number is the number of steiner switches
if [ "$#" -ne 5 ]; then
    echo "Arguments: #ToRs #Steiner_jellyfish hotspot/uniform executable(htsim_30mbps or htsim_256_1g) hotspot(proportioni, < 1)"
    exit
fi

# Genereta an arbitrary matrix as input to FSO(0)
perl generate_arbitrary_traffic_matrix.pl $1

# Runs FSO(0) and FSO(16)
./run_sim.sh $1 $2 $3 $4 $5
# Runs Jellyfish
./run_steiner.sh $1 $2 $3 $4 $5
# Runs FSO(8)
./run_sim_navid_other.sh $1 $2 $3 $4 $5



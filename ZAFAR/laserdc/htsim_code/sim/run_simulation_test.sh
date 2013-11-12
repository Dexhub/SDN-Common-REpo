# Created by zafar
# Arg#1: topology Arg#2: switch degree Arg#3 No of switches

EXPECTED_ARGS=3
E_BADARGS=65


# Total simulatin time is 55
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: Arg#1=topology,  Arg#2=switch degree,  Arg#3=No of switches"
  exit $E_BADARGS
fi

cd ../generate_configs/htsim_sim/

# Generate config files based on the topology
perl createdcntopo.pl $1 $2 $3
perl buildtopo.pl $1$2
perl routingdcn.pl $1$2 routing$1$2
perl create_traffic.pl routing$1$2
cp main.cpp ../../sim/
cd ../../sim

# Run the simulation
make
./htsim > result$1$2$3.txt

# Do post processing
#cd ../analysis
#`./runR.sh`
#perl parse_analysis.pl analysis.Rout results.$1$2$3
#`cat results.$1$2$3 | awk '{print (((\$2*1000*8)/(1000000))/55)}' > flowtpt.$1$2$3 `
#perl parse_results_rack.pl results.$1$2$3 rack.$1$2$3
#`cat rack.$1$2$3 | awk '{print (((\$2*1000*8)/(1000000))/55)}' > rackparsed.$1$2$3 `
#cp flowtpt.$1$2$3 ../plots/
#cp rackparsed.$1$2$3 ../plots/

# Plot the results using gnuplot: two cdfs: per-flow thrpt and per-server thrpt
#cd ../plots/
#perl pure_cdf.pl flowtpt.$1$2$3 > flowtptcdf.$1$2$3
#perl pure_cdf.pl rackparsed.$1$2$3 > rackparsedcdf.$1$2$3
#./plot_per_flow_thrpt.gp flow$1$2$3.eps flowtptcdf.$1$2$3
#./plot_per_rack_thrpt.gp rack$1$2$3.eps rackparsedcdf.$1$2$3
 


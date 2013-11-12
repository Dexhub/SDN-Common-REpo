 #!/usr/bin/perl
 use POSIX;

if ($#ARGV < 4)
{
	die "usage: k(# of servers) D(flexible degree) C(# of steiner switches) R(# of racks) outputfile  \n";
}
 
 
 
 
 my @outList;
 {
  my @fixedTopology;
  my @dynamicTopology;
  my @currentTopology;
  my $initState=0;
  my $serversPerRack;
  my $dynamicLinks;
  my $Racks;
  my $TotalSwitches;
  my $SteinerSwitches;
  my @graphDegree;
  
  my @graphDegreeDynamic;
  
  my $maxFixedRackDegree;
  my $maxFixedSteinerDegree;
  
  my @trafficMatrix;
  my $totalDynamicLinks;
  my $totalDynamicLinksCounter;
  my $totalStaticLinks;
  my $currentDynamicLinks;
  
  my @path;
  my @checked0;
  my @checked1;
  my $pathLen;
  my @queue0;
  my @queue1;
  my $queue0Start;
  my $queue0Counter;
  my $queue1Start;
  my @queue0Parent;
  my @queue1Parent;
  my $queue0End;
  my @marked;
  my $queue1End;
  my @trafficLinks;
  
  my $i;
  my $counter;
  my $counter2;
  my $source;
  my $sink;
  my $cur;
  

    sub checkDegreeDynamic {
      if ($_[0]<$Racks) {
            return $graphDegree[$_[0]]<$dynamicLinks;
      } else {
            return $graphDegree[$_[0]]<$dynamicLinks*2;
      }
  }
  
  sub AugmentedBFSDynamic{
      my $notFound=1;
      while ($notFound) {
            while ($queue0Start<$queue0End) {
                  $cur=$queue0[$queue0Start];
                  for ($i=0;$i<$TotalSwitches;$i++) {
                        if ($dynamicTopology[$cur][$i]==0)  {
                              if (checkDegreeDynamic($i)) {
                                    return $i;
                              }
                              if ($checked1[$i]==0) {
                                    $checked1[$i]=1;
                                    $queue1[$queue1End]=$i;
                                    $queue1Parent[$queue1End]=$queue0Start;
                                    $queue1End++;
                             }
                        }
                  }
                  $queue0Start++;
            }
            while ($queue1Start<$queue1End) {
                  $cur=$queue1[$queue1Start];
                  for ($i=0;$i<$TotalSwitches;$i++) {
                        if ($dynamicTopology[$cur][$i]==1)  {
                              if ($checked0[$i]==0) {
                                    $checked0[$i]=1;
                                    $queue0[$queue0End]=$i;
                                    $queue0Parent[$queue0End]=$queue1Start;
                                    $queue0End++;
                              }
                        }
                  }
                  $queue1Start++;
            }
      }
  }
  
  

  sub addAugmentingPathDynamic {
      my $count=0;
      for ($i=0;$i<$Racks;$i++)       {
            if ($graphDegreeDynamic[$i]<$dynamicLinks) {
                  $count++;
            }
      }
      for (;$i<$TotalSwitches;$i++)       {
            if ($graphDegreeDynamic[$i]<$dynamicLinks*2) {
                  $count++;
            }
      }
      $listOfNodes[$count-1]=0;
      $count=0;
      for ($i=0;$i<$Racks;$i++)       {
            if ($graphDegreeDynamic[$i]<$dynamicLinks) {
                  $listOfNodes[$count]=$i;
                  $count++;
            }
      }
      for (;$i<$TotalSwitches;$i++)       {
            if ($graphDegreeDynamic[$i]<2*$dynamicLinks) {
                  $listOfNodes[$count]=$i;
                  $count++;
            }
      }
      for ($count=$TotalSwitches-1;$count>=0;$count--) {
           $path[$count]=0;
      }
            $source=$listOfNodes[int(rand($count))];
            initAugmentedPathDynamic($source);
      
  }

  sub initAugmentedPathDynamic {
      $source=$_[0];
      $sink=$_[1];
      
            for ($i=0;$i<$TotalSwitches;$i++) {
                  $checked0[$i]=0;
                  $checked1[$i]=0;
                  $queue0[$i]=0;
                  $queue1[$i]=0;
                  $queue0Parent[$i]=0;
                  $queue1Parent[$i]=0;
 #                 $dynamicTopology[$i][$i]=3;
            }
      $queue0Start=0;
      $queue1Start=0;
      $queue0End=1;
      $queue1End=0;
      $pathlen=0;
      $path[$pathlen]=$source;
      $queue0[0]=$source;
#      $checked0[$source]=1;
      $checked1[$source]=1;
      $graphDegreeDynamic[$source]++;
      $sink=AugmentedBFSDynamic();
      $cur=$queue0[$queue0Start];
      if ($dynamicTopology[$cur][$sink]==1) {
            die "critical error, Error in computing augmenting path, send the dump to navid";
      }
      $totalDynamicLinksCounter++;
      $dynamicTopology[$cur][$sink]=1;
      $dynamicTopology[$sink][$cur]=1;
      $graphDegreeDynamic[$sink]++;
      my $traceQueue=$queue0Start;
      my $curSink=$queue0[$traceQueue];
      my $curSinkParent;
      my $curMid;
      my $curMidParent;
      my $curSource;
      while ($source!=$curSink) {
            $curSink=$queue0[$traceQueue];
            $curSinkParent=$queue0Parent[$traceQueue];
            
            $curMid=$queue1[$curSinkParent];
            $curMidParent=$queue1Parent[$curSinkParent];
            
            $curSource=$queue0[$curMidParent];
            $traceQueue=$curMidParent;
            
            if ($dynamicTopology[$curSink][$curMid]==0) {
                  die "critical error, Error in computing augmenting path, send the dump to navid";
            }
      
            $dynamicTopology[$curSink][$curMid]=0;
            $dynamicTopology[$curMid][$curSink]=0;

            if ($dynamicTopology[$curSource][$curMid]==1) {
                  die "critical error, Error in computing augmenting path, send the dump to navid";
            }
            $dynamicTopology[$curSource][$curMid]=1;
            $dynamicTopology[$curMid][$curSource]=1;
            $curSink=$queue0[$traceQueue];
      }
      
  }
  
  
  
  
  
  

  sub canGetLink {
      my $source=$_[0];
      my $sink=$_[1];
      if  ($fixedTopology[$source][$sink]==1) {
            return 1;
      }
      if  ($dynamicTopology[$source][$sink]==1) {
            return 1;
      }
      if (($graphDegreeDynamic[$sink]<$dynamicLinks) && ($graphDegreeDynamic[$source]+$marked[$source]<$dynamicLinks)) {
            if ($graphDegreeDynamic[$sink]==3) {
                  print "deep shit";
            }
            if ($graphDegreeDynamic[$source]==3) {
                  print "deep shit";
            }
      
            
            return 1;
      }
      return 0;
  }
  
  sub canGetLink2 {
      my $source=$_[0];
      my $sink=$_[1];
      if  ($fixedTopology[$source][$sink]==1) {
            $marked[$sink]=0;
            return 1;
      }
      if  ($dynamicTopology[$source][$sink]==1) {
            $marked[$sink]=0;
            return 1;
      }
      return 0;
  }

  
  sub dynamicBFS{
      my $notFound=1;
#      print $queue0Start,"  ",$queue0End;
      my $sink=$_[0];
      while ($queue0Start<$queue0End) {
                  $cur=$queue0[$queue0Start];
                  if (canGetLink($cur, $sink)==1) {
                        return 1;
                  }
                  for ($i=0;$i<$TotalSwitches;$i++) {
                        if (($checked0[$i]==0) || ($marked[$i]==0)) {
                              if (($checked0[$i]==0)) {
                                    if (canGetLink($cur, $sink)==1)  {
                                          $checked0[$i]=1;
                                          $queue0[$queue0End]=$i;
                                          $queue0Parent[$queue0End]=$queue0Start;
                                          $queue0End++;
                                          $marked[$i]=1;

                                   }
                              } else {
                                    if (($marked[$i]==0)) {
                                          if (canGetLink2($cur, $sink)==1)  {
                                                $checked0[$i]=1;
                                                $queue0[$queue0End]=$i;
                                                $queue0Parent[$queue0End]=$queue0Start;
                                                $queue0End++;
                                         }
                                    }
                              }
                                  
                        }
                  }
                  $queue0Start++;
            }
            return 0;
      }
  
  
  
  
  sub addShortestPath {
      my $source=$_[0];
      my $sink=$_[1];
      for ($i=0;$i<$TotalSwitches;$i++) {
            $checked0[$i]=0;
            $queue0[$i]=0;
            $queue0Parent[$i]=0;
            $marked[$i]=0;
 #                 $fixedTopology[$i][$i]=3;
      }
      $queue0Start=0;
      $queue0End=1;

      $queue0[0]=$source;
      $checked0[$source]=1;
      $checked1[$source]=1;
      #$graphDegreeDynamic[$source]++;
      
      if (dynamicBFS($sink)==1) {
            my $traceQueue=$queue0Start;
            while ($source!=$sink) {
                  $cur=$queue0[$traceQueue];
                  $traceQueue=$queue0Parent[$traceQueue];
                  if (($fixedTopology[$cur][$sink]==0) && ($dynamicTopology[$cur][$sink]==0)) {
                              $graphDegreeDynamic[$cur]++;
                              $graphDegreeDynamic[$sink]++;
                              $totalDynamicLinksCounter++;
                              if (($graphDegreeDynamic[$sink]>$dynamicLinks) || ($graphDegreeDynamic[$cur]>$dynamicLinks)) {
                                    print @queue0;
                                    print @queue0Parent;
                                    canGetLink($cur, $sink);
                                    die "Dynamic links are crossing their limits, please contact Navid";
                              }
                              $dynamicTopology[$cur][$sink]=1;
                              $dynamicTopology[$sink][$cur]=1;
                  }
                  $sink=$cur;
            }
      }
  }


  sub findMaxLink2{
      my $max=0;
      my @link;
      $link[0]=0; $link[1]=0;
      for ($i=0;$i<$Racks;$i++) {
            for ($j=0;$j<$Racks;$j++) {
                  if ($trafficMatrix[$i][$j]>$max) {
                  #if ($trafficMatrix[$i][$j]>0) {
                        $link[0]=$i;
                        $link[1]=$j;
                        $max=$trafficMatrix[$i][$j];
                        #return @link;
                  }
            }
      }
      return @link;
}
  
  {
      my $counter=0;
      sub findMaxLink{
            $link[0]=$trafficLinks[$counter][1]; $link[1]=$trafficLinks[$counter][2];
            $counter++;
            if ($counter==$Racks*($Racks-1)/2) {
                  $counter--;
            }
            return @link;
      }
  }


  sub setMaxLink {
      
      
      my $max=0;
      
      my $num=$Racks*($Racks-1)/2-1;
      $trafficLinks[$num][2]=0;
      
      for ($i=0;$i<$Racks;$i++) {
            for ($j=$i+1;$j<$Racks;$j++) {
                  $trafficMatrix[$i][$j]+=$trafficMatrix[$j][$i];
                  $trafficMatrix[$j][$i]=$trafficMatrix[$i][$j];
            }
      }
      my $count=0;
      for ($i=0;$i<$Racks;$i++) {
            for ($j=$i+1;$j<$Racks;$j++) {
                  $trafficLinks[$count][2]=$j;
                  $trafficLinks[$count][1]=$i;
                  $trafficLinks[$count][0]=$trafficMatrix[$i][$j];
                  $count++;
            }
            
      }
      @trafficLinks = sort { $b->[0] <=> $a->[0] } @trafficLinks;
      #print @trafficLinks[0];
}


  
  
  

  sub fillRandom {
        my $counter=$totalDynamicLinksCounter;
        my $counter2=0;
        #print $counter, "\n";
        while ($counter<$totalDynamicLinks) {
            addAugmentingPathDynamic();
            $counter++;
            #print $counter, " ";
        }
        #say $counter,"  ", $totalDynamicLinks, "\n";
  
  }

  sub MakeDynamicMatrix {
      my $traffic=$_[0];
      #$$traffixMatrix[0][1];
      @dynamicTopology=qw(1 2);
      my $matSize=scalar(@$traffic);
      if ($matSize!=$Racks) {
            die "matrix size doesn't fit the initialization size, forgot to initializa"
      }
      my $i;my $j;
      for ($i=0;$i<$Racks;$i++) {
            $matSize=scalar(@{$traffic->[$i]});
            if ($matSize!=$Racks) {
                  die "matrix size doesn't fit the initialization size, forgot to initializa"
            }
      }
      for ($i=0;$i<$TotalSwitches;$i++) {
              $graphDegreeDynamic[$i]=0;
      }

      for ($i=0;$i<$Racks;$i++) {
            for ($j=0;$j<$Racks;$j++) {
                  $trafficMatrix[$i][$j]=$$traffic[$i][$j];
            }
      }
      for ($i=0;$i<$TotalSwitches;$i++) {
              $graphDegreeDynamic[$i]=0;
              $trafficMatrix[$i][$i]=0;
      }
      
      my @link;
      $count=0;
      my $count2=0;
      $totalDynamicLinksCounter=0;
      setMaxLink();
      
      while ($count<0.9*$totalDynamicLinks) {
            @link=findMaxLink();
            if ($trafficMatrix[$link[0]][$link[1]]==0) {
                  fillRandom();
                  return;
            }
            #print $count," ";
            $trafficMatrix[$link[1]][$link[0]]=0;
            $trafficMatrix[$link[0]][$link[1]]=0;
            if ($link[0]!=$link[1]) {
                  addShortestPath(@link);
#                  $count++;
                  $count=$totalDynamicLinksCounter;
            }
      }
      fillRandom();
      
      print $totalDynamicLinks;
   }
  
  
  sub checkDegree {
      if ($_[0]<$Racks) {
            return $graphDegree[$_[0]]<$maxFixedRackDegree;
      } else {
            return $graphDegree[$_[0]]<$maxFixedSteinerDegree;
      }
  }
  
  sub AugmentedBFS{
      my $notFound=1;
      while ($notFound) {
            while ($queue0Start<$queue0End) {
                  $cur=$queue0[$queue0Start];
                  for ($i=0;$i<$TotalSwitches;$i++) {
                        if ($fixedTopology[$cur][$i]==0)  {
                              if (checkDegree($i)) {
                                    return $i;
                              }
                              if ($checked1[$i]==0) {
                                    $checked1[$i]=1;
                                    $queue1[$queue1End]=$i;
                                    $queue1Parent[$queue1End]=$queue0Start;
                                    $queue1End++;
                             }
                        }
                  }
                  $queue0Start++;
            }
            while ($queue1Start<$queue1End) {
                  $cur=$queue1[$queue1Start];
                  for ($i=0;$i<$TotalSwitches;$i++) {
                        if ($fixedTopology[$cur][$i]==1)  {
                              if ($checked0[$i]==0) {
                                    $checked0[$i]=1;
                                    $queue0[$queue0End]=$i;
                                    $queue0Parent[$queue0End]=$queue1Start;
                                    $queue0End++;
                              }
                        }
                  }
                  $queue1Start++;
            }
      }
  }
  
  sub initAugmentedPath {
      $source=$_[0];
      $sink=$_[1];
      
            for ($i=0;$i<$TotalSwitches;$i++) {
                  $checked0[$i]=0;
                  $checked1[$i]=0;
                  $queue0[$i]=0;
                  $queue1[$i]=0;
                  $queue0Parent[$i]=0;
                  $queue1Parent[$i]=0;
 #                 $fixedTopology[$i][$i]=3;
            }
      $queue0Start=0;
      $queue1Start=0;
      $queue0End=1;
      $queue1End=0;
      $pathlen=0;
      $path[$pathlen]=$source;
      $queue0[0]=$source;
#      $checked0[$source]=1;
      $checked1[$source]=1;
      $graphDegree[$source]++;
      $sink=AugmentedBFS();
      $cur=$queue0[$queue0Start];
      if ($fixedTopology[$cur][$sink]==1) {
            die "critical error, Error in computing augmenting path, send the dump to navid";
      }
      $fixedTopology[$cur][$sink]=1;
      $fixedTopology[$sink][$cur]=1;
      $graphDegree[$sink]++;
      my $traceQueue=$queue0Start;
      my $curSink=$queue0[$traceQueue];
      my $curSinkParent;
      my $curMid;
      my $curMidParent;
      my $curSource;
      while ($source!=$curSink) {
            $curSink=$queue0[$traceQueue];
            $curSinkParent=$queue0Parent[$traceQueue];
            
            $curMid=$queue1[$curSinkParent];
            $curMidParent=$queue1Parent[$curSinkParent];
            
            $curSource=$queue0[$curMidParent];
            $traceQueue=$curMidParent;
            
            if ($fixedTopology[$curSink][$curMid]==0) {
                  die "critical error, Error in computing augmenting path, send the dump to navid";
            }
      
            $fixedTopology[$curSink][$curMid]=0;
            $fixedTopology[$curMid][$curSink]=0;

            if ($fixedTopology[$curSource][$curMid]==1) {
                  die "critical error, Error in computing augmenting path, send the dump to navid";
            }
            $fixedTopology[$curSource][$curMid]=1;
            $fixedTopology[$curMid][$curSource]=1;
            $curSink=$queue0[$traceQueue];
      }
      
  }
  
  
  sub addAugmentingPath {
      $count=0;
      for ($i=0;$i<$Racks;$i++)       {
            if ($graphDegree[$i]<$maxFixedRackDegree) {
                  $count++;
            }
      }
      for (;$i<$TotalSwitches;$i++)       {
            if ($graphDegree[$i]<$maxFixedSteinerDegree) {
                  $count++;
            }
      }
      $listOfNodes[$count-1]=0;
      $count=0;
      for ($i=0;$i<$Racks;$i++)       {
            if ($graphDegree[$i]<$maxFixedRackDegree) {
                  $listOfNodes[$count]=$i;
                  $count++;
            }
      }
      for (;$i<$TotalSwitches;$i++)       {
            if ($graphDegree[$i]<2*$serversPerRack-2*$dynamicLinks) {
                  $listOfNodes[$count]=$i;
                  $count++;
            }
      }
      for ($count=$TotalSwitches-1;$count>=0;$count--) {
           $path[$count]=0;
      }
            $source=$listOfNodes[int(rand($count))];
            initAugmentedPath($source);
      
  }
  
  sub initTopology {
        $serversPerRack=$_[0];
        $dynamicLinks=$_[1];
        $SteinerSwitches=$_[2];
        $Racks=$_[3];
        my $initState=1;
        $TotalSwitches=$SteinerSwitches+$Racks;
        $maxFixedRackDegree=$serversPerRack-$dynamicLinks;
        $maxFixedSteinerDegree=2*$maxFixedRackDegree;
        for ($count=$TotalSwitches-1;$count>=0;$count--) {
            $graphDegree[$count]=0;
            $path[$count]=0;
                for ($count2=$TotalSwitches-1;$count2>=0;$count2--) {
                        $fixedTopology[$count][$count2]=0;
                }
        }
        for ($i=0;$i<$TotalSwitches;$i++) {
            $fixedTopology[$i][$i]=3;
        }
        
        $totalLinks=$maxFixedRackDegree*$Racks+$maxFixedSteinerDegree*$SteinerSwitches;
        $totalLinks=$totalLinks/2;
      
        $totalDynamicLinks=$dynamicLinks*$Racks+$dynamicLinks*2*$SteinerSwitches;
        $totalDynamicLinks=$totalDynamicLinks/2;
        
        $totalStaticLinks=$totalLinks;
        #print $totalStaticLinks;

        
        my $counter=0;
        my $counter2=0;
        if ($Racks!=$TotalSwitches) {
            while (($counter2<30000) && ($counter<$totalLinks)) {
                  do {
                        $source=int(rand($TotalSwitches));
                        if ($source<$Racks) {
                              $sink=int(rand($SteinerSwitches))+$Racks;
                        } else { $sink=int(rand($TotalSwitches));}
                  } while ($source==$sink);
                  $firstValid=0;
                  $secondValid=0;
                  if ($source<$Racks) {
                        if ($graphDegree[$source]<$maxFixedRackDegree) {
                              $firstValid=1;
                        }
                  } else {
                        if ($graphDegree[$source]<$maxFixedSteinerDegree) {
                              $firstValid=1;
                        }
                  }
                  if ($sink<$Racks) {
                        if ($graphDegree[$sink]<$maxFixedRackDegree) {
                              $secondValid=1;
                        }
                  } else {
                        if ($graphDegree[$sink]<$maxFixedSteinerDegree) {
                              $secondValid=1;
                        }
                  }
                  if ($source>=$TotalSwitches) {
                        $firstValid=0;
                  }
                  
                  if ($sink>=$TotalSwitches) {
                        $secondValid=0;
                  }
                  if (($firstValid==1) && ($secondValid==1) && ($fixedTopology[$source][$sink]==0)) {
                        $graphDegree[$source]++;
                        $graphDegree[$sink]++;
                        $fixedTopology[$source][$sink]=1;
                        $fixedTopology[$sink][$source]=1;
                        $counter++;
                        $counter2=0;
                  } else {$counter2++;}
              }  #endof While$graphDegree\
                  
        }
        $counter2=0;
        if ($counter<0.9*$totalLinks){
            while (($counter2<30000) && ($counter<$totalLinks)) {
                  do {
                        $source=int(rand($TotalSwitches));
                        $sink=int(rand($TotalSwitches));
                  } while ($source==$sink);
            
                  $firstValid=0;
                  $secondValid=0;
                  if ($source<$Racks) {
                        if ($graphDegree[$source]<$maxFixedRackDegree) {
                              $firstValid=1;
                        }
                  } else {
                        if ($graphDegree[$source]<$maxFixedSteinerDegree) {
                              $firstValid=1;
                        }
                  }
                  if ($sink<$Racks) {
                        if ($graphDegree[$sink]<$maxFixedRackDegree) {
                              $secondValid=1;
                        }
                  } else {
                        if ($graphDegree[$sink]<$maxFixedSteinerDegree) {
                              $secondValid=1;
                        }
                  }
                  if (($firstValid==1) && ($secondValid==1) && ($fixedTopology[$source][$sink]==0)) {
                        $graphDegree[$source]++;
                        $graphDegree[$sink]++;
                        $fixedTopology[$source][$sink]=1;
                        $fixedTopology[$sink][$source]=1;
                        $counter++;
                        $counter2=0;
                  } else {$counter2++;}
              }  #endof While$graphDegree\
        }
        
        
        print $counter, "\n";
        while ($counter<$totalLinks) {
            addAugmentingPath();
            $counter++
        }
        print $counter, "\n";
  }

  sub getOutputList() {
      my $count=0;
      for (my $i=0;$i<$TotalSwitches;$i++) {
            for (my $j=0;$j<$TotalSwitches;$j++) {
                  if ($fixedTopology[$i][$j]) {
                        $count++;
                  }
                  if ($dynamicTopology[$i][$j]) {
                        $count++;
                  }
            }
      }
      $count=$count/2;
      for ($i=0;$i<$count;$i++) {
            $outList[$i][4]=0;
      }
      $count=0;
      for (my $i=0;$i<$TotalSwitches;$i++) {
            for (my $j=$i+1;$j<$TotalSwitches;$j++) {
                  if ($fixedTopology[$i][$j]) {
                        $outList[$count][0]=$i;
                        $outList[$count][1]=$j;
                        if ($i<$Racks) {
                              $outList[$count][2]=1;
                        } else {$outList[$count][2]=0;}

                        if ($j<$Racks) {
                              $outList[$count][3]=1;
                       } else {$outList[$count][3]=0;}
                        $outList[$count][4]=0;
                        
                        
                        $count++;
                  }
                  if ($dynamicTopology[$i][$j]) {
                        $outList[$count][0]=$i;
                        $outList[$count][1]=$j;
                        
                        if ($i<$Racks) {
                              $outList[$count][2]=1;
                        } else {$outList[$count][2]=0;}

                        if ($j<$Racks) {
                              $outList[$count][3]=1;
                        } else {$outList[$count][3]=0;}
                        $outList[$count][4]=1;
                        $count++;
                  }
            }
      }
  }
}
  



  


my @matrix;
$rack=$ARGV[3];
$matrix[$rack-1][0]= 00;

my $i;my $j;

for ($i=0;$i<$rack;$i++) {
      for ($j=0;$j<$rack;$j++) {
            $matrix[$i][$j]= 100000;
      }
 }






#initTopology (k, d, number of steiner swithces, number of racks)
# number of steiner swiches could be zero;
# if k<D it is going to crash
#D could be zero
initTopology($ARGV[0],$ARGV[1],$ARGV[2],$rack);
#make dynamic graph based on traffic
MakeDynamicMatrix(\@matrix);

#put output in outList variable the format is a list of links with the following format
# for link i we have
# outList[$i][0] and outList[$i][1] are the source and destination of the link.
# outList[$i][2] is 1 if source is a Tor Switches 0 if it is a steiner switch
# outList[$i][3] is 1 if sink is a Tor Switches 0 if it is a steiner switch
# outList[$i][4] is 0 if it is an static link and 1 if it is dynamic

getOutputList();


# Added by zafar
my $filename = $ARGV[4] ;
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
$i = 0;
my $NumSwitches = $ARGV[2] + $rack;
my $NumHosts = $rack;
print $fh "NUMSWITCHES=$NumSwitches \n";
print $fh "NUMHOSTNODES=$NumHosts \n";

my @tor = ();
my $index1 = 0;
my $index2 = 0;

# Add links to virtual hosts from each ToR switch
my $k = 1;

while (exists $outList[$i][2])
{
	print "$outList[$i][0] $outList[$i][1] $outList[$i][2] $outList[$i][3] $outList[$i][4]\n";
	if(($outList[$i][2] == 1) and ($outList[$i][3] == 1))
	{
		$index1 = $outList[$i][0] + 1;
		$index2 = $outList[$i][1] + 1;
		if (!(grep {$_ eq $index1} @tor)) {
  			push(@tor, $index1);
			print $fh "S$index1 H$k 1 \n";
			$k++;
		}
		if (!(grep {$_ eq $index2} @tor)) {
  			push(@tor, $index2);
			print $fh "S$index2 H$k 1 \n";
			$k++;
		}
			
		print $fh "S$index1 S$index2 1 \n";

	}
	if(($outList[$i][2] == 1) and ($outList[$i][3] == 0))
	{
		$index1 = $outList[$i][0] + 1;
		$index2 = $outList[$i][1] + 1;	
		if (!(grep {$_ eq $index1} @tor)) 
		{
  			push(@tor, $index1);
			print $fh "S$index1 H$k 1 \n";
			$k++;


		}
		if (!(grep {$_ eq $index2} @tor)) {
  			push(@tor, $index2);
			print $fh "S$index2 H$k 1 \n";
			$k++;



		}

		print $fh "S$index1 C$index2 1 \n";
	}

	if(($outList[$i][2] == 0) and ($outList[$i][3] == 1))
	{
		$index1 = $outList[$i][0] + 1;
		$index2 = $outList[$i][1] + 1;	
		if (!(grep {$_ eq $index1} @tor)) 
		{
  			push(@tor, $index1);
			print $fh "S$index1 H$k 1 \n";
			$k++;


		}
		if (!(grep {$_ eq $index2} @tor)) {
  			push(@tor, $index2);
			print $fh "S$index2 H$k 1 \n";
			$k++;


		}

		print $fh "C$index1 S$index2 1 \n";
	}

	if(($outList[$i][2] == 0) and ($outList[$i][3] == 0))
	{
		$index1 = $outList[$i][0] + 1;
		$index2 = $outList[$i][1] + 1;	
		if (!(grep {$_ eq $index1} @tor)) 
		{
  			push(@tor, $index1);
			print $fh "S$index1 H$k 1 \n";
			$k++;


		}
		
		if (!(grep {$_ eq $index2} @tor)) {
  			push(@tor, $index2);
			print $fh "S$index2 H$k 1 \n";
			$k++;


		}

		print $fh "C$index1 C$index2 1 \n";
		
	}
	$i++;



} 
close $fh;






print "\n";


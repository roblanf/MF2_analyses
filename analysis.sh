base=/data/rob/mf2/analyses/test/Endicot_2008/
iqtree=/data/rob/mf2/analyses/test/iqtree-2.2.0-beta/bin/iqtree2
pf2=/data/rob/mf2/partitionfinder-2.1.1/PartitionFinder.py
aln=/alignment.phy
iqparts=/partitions.nex
pfcfg=/partition_finder.cfg
threads=32
seed=123456742
results='results.tsv'

# lots of MF2 analyses

algo_array=( "greedy" "rcluster" "rclusterf" "kmeans" )
model_array=( "1" "4" "ALL" )
rate_array=( "E" "I+G" "E,G,I+G" "E,G,I,R,I+G,I+R" )

# set up results file
echo -e "Software\tThreads\tDataset\tFolder\tAlgorithm\tmerge_model\tmerge-rate\tCommandline\tTotal_execution_time\tPeak_memory\tPercent_CPU\tBIC\tN_partitions" > results.tsv

for algo in "${algo_array[@]}" ; do
	for model in "${model_array[@]}" ; do
		for rate in "${rate_array[@]}" ; do
			echo "\n\n***NEW ANALYSIS***"
			echo $model $algo $rate

			# no commas or plusses in folder names
			ratef=`echo $rate | tr ',' '-'`
			ratef=`echo $ratef | tr '+' 'n'` 

			fldr="MF2_""$model""_""$algo""_""$ratef""_""$threads"
			echo $fldr
			mkdir $fldr
			cd $fldr
			cp "$base$aln" "$base$fldr$aln"
			cp "$base$iqparts" "$base$fldr$iqparts"
			/usr/bin/time -o monitoring.txt -v $iqtree -s "$base$fldr$aln" -spp "$base$fldr$iqparts" -m TESTMERGEONLY -mset ALL -mrate "E,G,I,R,I+G,I+R" --merge-model "$model" --merge-rate "$rate" --merge "$algo"  -nt $threads --seed $seed
			cd $base
			echo "***ANALYSIS DONE***"
			echo ""
			echo ""

			# now we extract the results
			Commandline=Commandline=$(sed '1q;d' "$fldr""monitoring.txt" | cut -d ':' -f 2)
			Total_execution_time=$(sed '5q;d' "$fldr""monitoring.txt" | cut -d ')' -f 3 | cut -d ' ' -f 2)
			Peak_memory=$(sed '10q;d' "$fldr""monitoring.txt" | cut -d ':' -f 2)
			Percent_CPU=$(sed '4q;d' "$fldr""monitoring.txt" | cut -d ':' -f 2)
			Percent_CPU=${Percent_CPU::-1}
			BIC=grep 'Bayesian information criterion (BIC)' "$fldr""partitions.nex.iqtree" | cut -d ':' -f 2 | sed 's/ //g'
			N_partitions=$(wc -l "$fldr""partitions.nex.best_scheme" | cut -c 1)
			Dataset=$(basename $base)
			
			echo -e "MF2\t$threads\t$Dataset\t$fldr\t$algo\t$model\t$rate\t$Commandline\t$Total_execution_time\t$Peak_memory\t$Percent_CPU\t$BIC\t$N_partitions" >> results.tsv



		done
	done
done



# only MF2 stuff for now
exit 1

# MF2/PF2 timing comparison


#Greedy, raxml models. This is for direct comparison with what should be the same 
# analysis in PF2

threads_array=( 1 2 4 8 16 32 )

for threads in "${threads_array[@]}" ; do
	echo "$threads"

	fldr="MF2_greedy_raxml_$threads"
	mkdir $fldr
	cd $fldr
	cp "$base$aln" "$base$fldr$aln"
	cp "$base$iqparts" "$base$fldr$iqparts"
	$iqtree -s "$base$fldr$aln" -spp "$base$fldr$iqparts" -m TESTMERGEONLY -mset GTR -mrate E,I,G,I+G,R --merge-model GTR --merge-rate E,G,I+G --merge greedy  -nt $threads --seed $seed
	cd $base

	# 2. PF2 Greedy, raxml models. 
	fldr="PF2_greedy_raxml_$threads"
	mkdir $fldr
	cd $fldr
	cp "$base$aln" "$base$fldr$aln"
	cp "$base$pfcfg" "$base$fldr$pfcfg"
	python $pf2 "$base$fldr$pfcfg" --raxml -p $threads --no-ml-tree
	cd $base

done



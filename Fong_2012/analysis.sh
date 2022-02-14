base=/data/rob/mf2/MF2_analyses/Fong_2012/
iqtree=/data/rob/mf2/iqtree-2.1.2-Linux/bin/iqtree2
pf2=/data/rob/mf2/partitionfinder-2.1.1/PartitionFinder.py
aln=/alignment.phy
iqparts=/partitions.nex
pfcfg=/partition_finder.cfg
threads=128
seed=123456742
results='results.tsv'


# set up results file
echo -e "Group\tSoftware\tThreads\tDataset\tFolder\tAlgorithm\tmerge-model\tmerge-rate\tCommandline\tTotal_execution_time\tPeak_memory\tPercent_CPU\tBIC\tN_partitions" > results.tsv


# these are the settings we compare for MF2 analyses
algo_array=( "greedy" "rcluster" "rclusterf" "kmeans" )
model_array=( "JC" "HKY" "GTR" "JC,HKY,GTR" "ALL" )
rate_array=( "E" "I+G" "E,G,I+G" "E,G,I,R,I+G,I+R" )




# MF2/PF2 timing comparison

#Greedy, raxml models. This is for direct comparison with what should be the same 
# analysis in PF2

threads_array=( 8 16 32 64 128 )

$algo="greedy"
$model="GTR"
$rate="E,G,I+G"

for threads in "${threads_array[@]}" ; do
	echo "$threads"

	fldr="MF2_GTRmods_$threads"


	if [ -d $fldr ] 
	then
	    echo "Directory $fldr exists. Skipping this analysis" 
	else
		mkdir $fldr
		cd $fldr
		cp "$base$aln" "$base$fldr$aln"
		cp "$base$iqparts" "$base$fldr$iqparts"
	    /usr/bin/time -o monitoring.txt -v $iqtree -s "$base$fldr$aln" -spp "$base$fldr$iqparts" -m TESTMERGEONLY -mset $model -mrate $rate --merge-model $model --merge-rate $rate --merge $algo  -nt $threads --seed $seed
	fi


	cd $base
	

	# now we extract the results
	Commandline=Commandline=$(sed '1q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Total_execution_time=$(sed '5q;d' "$fldr/""monitoring.txt" | cut -d ')' -f 3 | cut -d ' ' -f 2)
	Peak_memory=$(sed '10q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Percent_CPU=$(sed '4q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Percent_CPU=${Percent_CPU::-1}
	BIC=$(grep 'Bayesian information criterion (BIC)' "$fldr/""partitions.nex.iqtree" | cut -d ':' -f 2 | sed 's/ //g')
	N_partitions=$(wc -l "$fldr/""partitions.nex.best_scheme" | cut -c 1)
	Dataset=$(basename $base)

	echo -e "MF2vPF2\tMF2\t$threads\t$Dataset\t$fldr\t$algo\t$model\t$rate\t$Commandline\t$Total_execution_time\t$Peak_memory\t$Percent_CPU\t$BIC\t$N_partitions" >> results.tsv

	# 2. PF2 Greedy, raxml models. 
	fldr="PF2_GTRmods_$threads"
	
	if [ -d $fldr ] 
	then
	    echo "Directory $fldr exists. Skipping this analysis" 
	else
		mkdir $fldr
		cd $fldr
		cp "$base$aln" "$base$fldr$aln"
		cp "$base$pfcfg" "$base$fldr$pfcfg"
		/usr/bin/time -o monitoring.txt -v python $pf2 "$base$fldr$pfcfg" --raxml -p $threads
	fi



	cd $base


	# now we extract the results
	Commandline=Commandline=$(sed '1q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Total_execution_time=$(sed '5q;d' "$fldr/""monitoring.txt" | cut -d ')' -f 3 | cut -d ' ' -f 2)
	Peak_memory=$(sed '10q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Percent_CPU=$(sed '4q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
	Percent_CPU=${Percent_CPU::-1}
	BIC=$(grep 'Scheme BIC        ' "$fldr/analysis/""best_scheme.txt" | cut -d ':' -f 2 | sed 's/ //g')
	N_partitions=$(grep 'Number of subsets' "$fldr/analysis/""best_scheme.txt" | cut -d ':' -f 2 | sed 's/ //g')
	Dataset=$(basename $base)

	echo -e "MF2vPF2\tPF2\t$threads\t$Dataset\t$fldr\t$algo\t$model\t$rate\t$Commandline\t$Total_execution_time\t$Peak_memory\t$Percent_CPU\t$BIC\t$N_partitions" >> results.tsv


done



# lots of MF2 analyses


for algo in "${algo_array[@]}" ; do
	for model in "${model_array[@]}" ; do
		for rate in "${rate_array[@]}" ; do

			echo $model $algo $rate

			# no commas or plusses in folder names
			ratef=`echo $rate | tr ',' '-'`
			ratef=`echo $ratef | tr '+' 'n'` 
			modelf=`echo $model | tr ',' '-'`
			modelf=`echo $modelf | tr '+' 'n'`

			fldr="MF2_""$modelf""_""$algo""_""$ratef""_""$threads"

			if [ -d $fldr ] 
			then
			    echo "Directory $fldr exists. Skipping this analysis" 
			else

				echo $fldr
				mkdir $fldr
				cd $fldr
				cp "$base$aln" "$base$fldr$aln"
				cp "$base$iqparts" "$base$fldr$iqparts"
				/usr/bin/time -o monitoring.txt -v $iqtree -s "$base$fldr$aln" -spp "$base$fldr$iqparts" -m TESTMERGEONLY -mset ALL -mrate "E,G,I,R,I+G,I+R" --merge-model "$model" --merge-rate "$rate" --merge "$algo"  -nt $threads --seed $seed
			fi

			cd $base

			# now we extract the results
			Commandline=Commandline=$(sed '1q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
			Total_execution_time=$(sed '5q;d' "$fldr/""monitoring.txt" | cut -d ')' -f 3 | cut -d ' ' -f 2)
			Peak_memory=$(sed '10q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
			Percent_CPU=$(sed '4q;d' "$fldr/""monitoring.txt" | cut -d ':' -f 2)
			Percent_CPU=${Percent_CPU::-1}
			BIC=$(grep 'Bayesian information criterion (BIC)' "$fldr/""partitions.nex.iqtree" | cut -d ':' -f 2 | sed 's/ //g')
			N_partitions=$(wc -l "$fldr/""partitions.nex.best_scheme" | cut -c 1)
			Dataset=$(basename $base)
			
			echo -e "MF2_comparisons\tMF2\t$threads\t$Dataset\t$fldr\t$algo\t$model\t$rate\t$Commandline\t$Total_execution_time\t$Peak_memory\t$Percent_CPU\t$BIC\t$N_partitions" >> results.tsv

		done
	done
done




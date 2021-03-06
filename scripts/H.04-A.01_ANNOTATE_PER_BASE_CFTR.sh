# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -10

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

	set

	echo

# INPUT VARIABLES

	ALIGNMENT_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	CFTR_BED=$5

START_PER_BASE=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# convert the per base report in DEPTH_OF_COVERAGE/CODING_PADDED into a bed file with the depth
# intersect with the annotated CFTR region file.
# CFTR_BED file is the cftr target region annotated with upstream, utr, exon, intron and downstream

	awk 'BEGIN {FS=","; OFS="\t"} NR>1 \
		{split($1,BASE,":"); print BASE[1],BASE[2]-1,BASE[2],$2}' \
	$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/DEPTH_OF_COVERAGE/CFTR/$SM_TAG"_CFTR.EveryBase.csv" \
		| singularity exec $ALIGNMENT_CONTAINER bedtools \
			intersect \
			-a $CFTR_BED \
			-b - \
			-wb \
		| awk '{OFS="\t"} BEGIN {print "#CHROM" "\t" "POS" "\t" "GENE" "\t" "TRANSCRIPT" "\t" "EXON" "\t" "STRAND" "\t" "DEPTH" "\t" "SM_TAG"} \
			{print $1,$3,$4,$5,$6,$7,$11,"'$SM_TAG'"}' \
	>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt

# SORT THE FILE IN KARYOTYPIC ORDER.
# THIS IS NOT NECESSARY WHEN DOING JUST CFTR

	(head -n 1 $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt ; \
	awk '$1~/^[0-9]/' $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt | sort -k1,1n -k 2,2n ; \
	awk '$1=="X"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt | sort -k1,1n -k 2,2n ; \
	awk '$1=="Y"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt | sort -k1,1n -k 2,2n ; \
	awk '$1=="MT"' $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt | sort -k1,1n -k 2,2n) \
	>| $CORE_PATH/$PROJECT/$SM_TAG/ANALYSIS/$SM_TAG"_"CFTR.PER.BASE.REPORT.txt

END_PER_BASE=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",H.001,REFSEQ_PER_BASE,"$HOSTNAME","$START_PER_CODING","$END_PER_BASE \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

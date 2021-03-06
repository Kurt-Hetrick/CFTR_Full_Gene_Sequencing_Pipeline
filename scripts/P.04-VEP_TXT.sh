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

	set

	echo

# INPUT VARIABLES

	VEP_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	VEP_REF_CACHE=$5
	VEP_FASTA=$6
	VEP_MAXENTSCAN_DIR=$7
	VEP_SPLICEAI_SNV=$8
	VEP_SPLICEAI_INDEL=$9
	VEP_SPLICEAI_CUTOFF=${10}
	VEP_CONDEL_CONFIG_DIR=${11}
	VEP_DBSCSNV=${12}
	VEP_DBNSFP=${13}
	THREADS=${14}
	SAMPLE_SHEET=${15}
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${16}

## ANNOTATE VARIANT ONLY CFTR REGION VCF WITH GENE/TRANSCRIPT WITH VEP

START_VEP_VCF=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $VEP_CONTAINER vep" \
			CMD=$CMD" -i $CORE_PATH/$PROJECT/TEMP/$SM_TAG".CFTR_REGION_VARIANT_ONLY.DandN.vcf"" \
			CMD=$CMD" -o $CORE_PATH/$PROJECT/$SM_TAG/VEP/$SM_TAG".vep.txt"" \
			CMD=$CMD" --fork $THREADS" \
			CMD=$CMD" --tab" \
			CMD=$CMD" --cache" \
			CMD=$CMD" --offline" \
			CMD=$CMD" --refseq" \
			CMD=$CMD" --force_overwrite" \
			CMD=$CMD" --dir $VEP_REF_CACHE" \
			CMD=$CMD" --dir_cache $VEP_REF_CACHE" \
			CMD=$CMD" --dir_plugins $VEP_REF_CACHE" \
			CMD=$CMD" --hgvs" \
			CMD=$CMD" --assembly GRCh37" \
			CMD=$CMD" --check_existing" \
			CMD=$CMD" --fasta $VEP_FASTA" \
			CMD=$CMD" --plugin MaxEntScan,$VEP_MAXENTSCAN_DIR,SWA,NCSS,verbose" \
			CMD=$CMD" --plugin SpliceAI,snv=$VEP_SPLICEAI_SNV,indel=$VEP_SPLICEAI_INDEL,cutoff=$VEP_SPLICEAI_CUTOFF" \
			CMD=$CMD" --plugin Condel,$VEP_CONDEL_CONFIG_DIR,b" \
			CMD=$CMD" --plugin dbscSNV,$VEP_DBSCSNV" \
			CMD=$CMD" --plugin dbNSFP,$VEP_DBNSFP,ALL" \
			CMD=$CMD" &&" \
			CMD=$CMD" grep -v ^## $CORE_PATH/$PROJECT/$SM_TAG/VEP/$SM_TAG".vep.txt"" \
			CMD=$CMD" | awk 'BEGIN {print \"##$SM_TAG\"} \$5~\"Feature\"||\$5~\"-\"||\$5~/^NM/ {print \$0}' " \
			CMD=$CMD" >| $CORE_PATH/$PROJECT/$SM_TAG/VEP/$SM_TAG".vep.formatted.txt"" \

	# write command line to file and execute the command line

		echo $CMD >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"
		echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"
		echo $CMD | bash

	# check the exit signal at this point.

		SCRIPT_STATUS=`echo $?`

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# also write to file that this job failed

		if [ "$SCRIPT_STATUS" -ne 0 ]
		 then
			echo $SM_TAG $HOSTNAME $JOB_NAME $USER $SCRIPT_STATUS $SGE_STDERR_PATH \
			>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"
			exit $SCRIPT_STATUS
		fi

END_VEP_VCF=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",O.001,VEP_VCF,"$HOSTNAME","$START_VEP_VCF","$END_VEP_VCF \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

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

	ALIGNMENT_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_DICT=$5
	DBSNP=$6
	TARGET_BED=$7
		TARGET_BED_NAME=$(basename $TARGET_BED .bed)
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$9

START_VCF_METRICS=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $ALIGNMENT_CONTAINER java -jar" \
			CMD=$CMD" /gatk/gatk.jar" \
		CMD=$CMD" CollectVariantCallingMetrics" \
			CMD=$CMD" --INPUT $CORE_PATH/$PROJECT/$SM_TAG/ANALYSIS/$SM_TAG.CFTR_REGION.vcf" \
			CMD=$CMD" --DBSNP $DBSNP" \
			CMD=$CMD" --SEQUENCE_DICTIONARY $REF_DICT" \
			CMD=$CMD" --OUTPUT $CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VCF_METRICS/$SM_TAG.CFTR_REGION" \
			CMD=$CMD" --TARGET_INTERVALS $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TARGET_BED_NAME"-picard.bed""
			CMD=$CMD" --THREAD_COUNT 6"

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

START_VCF_METRICS=`date '+%s'` # capture time process ends for wall clock tracking purposes.

# add text extension to files.

	mv -v $CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VCF_METRICS/$SM_TAG.CFTR_REGION.variant_calling_detail_metrics \
	$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VCF_METRICS/$SM_TAG.CFTR_REGION.variant_calling_detail_metrics.txt

	mv -v $CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VCF_METRICS/$SM_TAG.CFTR_REGION.variant_calling_summary_metrics \
	$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VCF_METRICS/$SM_TAG.CFTR_REGION.variant_calling_summary_metrics.txt

# write out timing metrics to file

	echo $PROJECT",P01,VCF_METRICS,"$HOSTNAME","$START_VCF_METRICS","$END_VCF_METRICS \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

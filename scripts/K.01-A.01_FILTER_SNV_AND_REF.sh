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

	GATK_3_7_0_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$7

# APPLY HARD FILTERS TO SNV AND REFERENCE SITES

START_FILTER_SNV_AND_REF=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# construct command line

	CMD="singularity exec $GATK_3_7_0_CONTAINER java -jar" \
		CMD=$CMD" /usr/GenomeAnalysisTK.jar" \
	CMD=$CMD" -T VariantFiltration" \
		CMD=$CMD" -R $REF_GENOME" \
		CMD=$CMD" --variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG.RAW.ANNOTATED.SNV_REF.vcf.gz" \
		CMD=$CMD" -o $CORE_PATH/$PROJECT/TEMP/$SM_TAG.FILTERED.SNV_REF.vcf.gz" \
		CMD=$CMD" --filterExpression 'QD < 2.0'" \
		CMD=$CMD" --filterName 'QDfilter'" \
		CMD=$CMD" --filterExpression 'ABHet > 0.80'" \
		CMD=$CMD" --filterName 'ABfilter80'" \
		CMD=$CMD" --filterExpression 'ABHet < 0.20'" \
		CMD=$CMD" --filterName 'ABfilter20'" \
		CMD=$CMD" --filterExpression 'QUAL < 30.0'" \
		CMD=$CMD" --filterName 'QUALfilter'" \
		CMD=$CMD" --filterExpression 'FS > 40.0'" \
		CMD=$CMD" --filterName 'FSfilter'" \
		CMD=$CMD" --logging_level ERROR"

END_FILTER_SNV_AND_REF=`date '+%s'` # capture time process stops for wall clock tracking purposes.

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

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",L.001,FILTER_SNV_AND_REF,"$HOSTNAME","$START_FILTER_SNV_AND_REF","$END_FILTER_SNV_AND_REF \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

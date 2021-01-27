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

	COMBINE_ANNOVAR_WITH_SPLICING_R_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	COMBINE_ANNOVAR_WITH_SPLICING_R_SCRIPT=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$7

# extract score from spliceai vcf output

START_COMBINE_ANNOTATIONS=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $COMBINE_ANNOVAR_WITH_SPLICING_R_CONTAINER Rscript" \
			CMD=$CMD" $COMBINE_ANNOVAR_WITH_SPLICING_R_SCRIPT" \
			CMD=$CMD" $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_cryptsplice_prioritized_predictions_reformatted.txt"" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/SPLICEAI/$SM_TAG".spliceai.table.txt"" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/ANNOVAR/$SM_TAG".CFTR_REGION_VARIANT_ONLY.DandN_ANNOVAR_REPORT.txt"" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/ANALYSIS/$SM_TAG".combined_splicing_with_annovar""

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

END_COMBINE_ANNOTATIONS=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",O.001,COMBINE_ANNOTATIONS,"$HOSTNAME","$START_COMBINE_ANNOTATIONS","$END_COMBINE_ANNOTATIONS \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

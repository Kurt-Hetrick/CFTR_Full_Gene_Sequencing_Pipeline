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
	REF_GENOME=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$7

## --index the cram file

START_INDEX_HC_CRAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $ALIGNMENT_CONTAINER samtools" \
			CMD=$CMD" index" \
				CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/HC_CRAM/$SM_TAG".HC.cram""

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

END_INDEX_HC_CRAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",H.01-A.01-A.01-A.01,INDEX_HC_CRAM,"$HOSTNAME","$START_INDEX_HC_CRAM","$END_INDEX_HC_CRAM \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# make a copy/rename the cram index file since their appears to be two useable standards

	cp -rvf $CORE_PATH/$PROJECT/$SM_TAG/HC_CRAM/$SM_TAG".HC.cram.crai" \
	$CORE_PATH/$PROJECT/$SM_TAG/HC_CRAM/$SM_TAG".HC.crai"

# exit with the signal from the program

	exit $SCRIPT_STATUS

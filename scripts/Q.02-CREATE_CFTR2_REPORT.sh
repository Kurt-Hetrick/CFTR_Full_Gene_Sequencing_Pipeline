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
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$6

# concatenate the manta report with the cftr2/ddl classification report

START_CREATE_CFTR2_REPORT=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="(echo \#STRUCTURAL_VARIANTS ;" \
			CMD=$CMD" cat" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/MANTA/$SM_TAG".MANTA_REPORT.txt" ;" \
			CMD=$CMD" echo ;" \
			CMD=$CMD" echo \#SMALL_VARIANTS ;" \
			CMD=$CMD" cat" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/CFTR2/$SM_TAG".CFTR2_VARIANTS.txt" )" \
		CMD=$CMD" | sed 's/\t/,/g'" \
		# this is to change the delimter for variants that have multiple consequences
		# from pipe to semicolon
		CMD=$CMD" | sed 's/|/;/g'" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/$SM_TAG/ANALYSIS/$SM_TAG".CFTR2_REPORT.csv"" \

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

END_CREATE_CFTR2_REPORT=`date '+%s'` # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo $PROJECT",N.001,CREATE_CFTR2_REPORT,"$HOSTNAME","$START_CREATE_CFTR2_REPORT","$END_CREATE_CFTR2_REPORT \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

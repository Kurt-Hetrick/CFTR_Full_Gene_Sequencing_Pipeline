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

	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	SAMPLE_SHEET=$5
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$6

	# find the latest version the prioritized predictions output from cryptsplice.

		PRIORITIZED_PREDICTIONS=$(ls -lhtr $CORE_PATH/$PROJECT/$SM_TAG/CRYPTSPLICE/prioritized_predictions* \
			| tail -n 1 \
			| awk '{print $NF}')

## RUN CRYPTSLICE ON THE VEP ANNOTATED VCF

START_CRYPTSPLICE_REFORMAT=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="awk 'NR>2' $PRIORITIZED_PREDICTIONS" \
			CMD=$CMD" | sed 's/)//g ; s/(//g ; s/>variant/variant/g'" \
			CMD=$CMD" >| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_cryptsplice_prioritized_predictions_reformatted.txt"" \

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

END_CRYPTSPLICE_REFORMAT=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",P.001,CRYPTSPLICE_REFORMAT,"$HOSTNAME","$START_CRYPTSPLICE_REFORMAT","$END_CRYPTSPLICE_REFORMAT \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

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

	MANTA_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	MANTA_CFTR_BED=$6
	MANTA_CONFIG=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$9

## MANTA RUN CONFIGURATION SET UP
	##################################################################
	# The config file was modified such that #########################
	##### minEdgeObservations = 2 and (instead of 3) #################
	##### minCandidateSpanningCount = 2 (instead of 3) ###############
	##### this file is called during run configuration $MANTA_CONFIG #
	##################################################################

START_CONFIGURE_MANTA=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $MANTA_CONTAINER python" \
			CMD=$CMD" /manta/bin/configManta.py" \
				CMD=$CMD" --bam $CORE_PATH/$PROJECT/$SM_TAG/CRAM/$SM_TAG".cram"" \
				CMD=$CMD" --referenceFasta $REF_GENOME" \
				CMD=$CMD" --runDir $CORE_PATH/$PROJECT/$SM_TAG/MANTA" \
				CMD=$CMD" --callRegions $MANTA_CFTR_BED" \
				CMD=$CMD" --config $MANTA_CONFIG" \
				CMD=$CMD" --exome"

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

END_CONFIGURE_MANTA=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",H.001,CONFIGURE_MANTA,"$HOSTNAME","$START_CONFIGURE_MANTA","$END_CONFIGURE_MANTA \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

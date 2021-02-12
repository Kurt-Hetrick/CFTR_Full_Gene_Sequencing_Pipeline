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

# after verifyBamID is run on the original final bam file. parse file to see if AVERAGE_DEPTH is >= 320
# if it is then downsample the final bam file to 300x
# if not then copy final bam file and corresponding index to a $file_DS.bam
# either way, verifybamid is going to be rerun on the new file.

START_DOWNSAMPLE_BAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# grab AVERAGE DEPTH from the original verifyBamID output and round down to the nearest whole number.
	# bash arithmetic can only deal with integers

		AVERAGE_DEPTH_ROUNDED=$(awk 'NR==2 {print $6"/1"}' \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VERIFYBAMID/$SM_TAG".selfSM" \
			| bc)

	# grab AVERAGE DEPTH from the original verifyBamID output

		AVERAGE_DEPTH_REAL=$(awk 'NR==2 {print $6}' \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/VERIFYBAMID/$SM_TAG".selfSM")

	# if that value is >= 320, then take 300/AVERAGE_DEPTH_REAL (to 4 decimal places)
		## and downsample the final bam file to that fraction.
	# else just copy the original final bam file as a new file.

		if [[ $AVERAGE_DEPTH_ROUNDED -gt 319 ]]
			then

				DOWNSAMPLE_FRACTION=$(awk 'BEGIN {printf "%.4f\n", 300/"'$AVERAGE_DEPTH_REAL'"}')

				# construct command line
				# this will get run IF the mean target coverage is >= 320x

					CMD="singularity exec $ALIGNMENT_CONTAINER java -jar" \
						CMD=$CMD" /gatk/picard.jar" \
					CMD=$CMD" DownsampleSam" \
						CMD=$CMD" INPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam"" \
						CMD=$CMD" OUTPUT=$CORE_PATH/$PROJECT/TEMP/$SM_TAG"_DS.bam"" \
						CMD=$CMD" REFERENCE_SEQUENCE=$REF_GENOME" \
						CMD=$CMD" PROBABILITY=$DOWNSAMPLE_FRACTION" \
						CMD=$CMD" STRATEGY=Chained" \
						CMD=$CMD" VALIDATION_STRINGENCY=SILENT" \
						CMD=$CMD" CREATE_INDEX=TRUE"

				# write command line to file and execute the command line

					echo $CMD >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"
					echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"
					echo $CMD | bash
			else

				# IF THE COVERAGE ISN'T TOO HIGH THEN JUST COPY THE BAM FILE AS A NEW FILE TO RERUN VERIFYBAMID.
				# THIS IS TO BE CONSISTENT WITH THE WORKFLOW. I.E. YOU ARE RERUNNING VERIFYBAMID NO MATTER WHAT.

				echo cp -f $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_DS.bam" \
					>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"
				echo cp -f $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bai" $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_DS.bai" \
					>> $CORE_PATH/$PROJECT/COMMAND_LINES/$SM_TAG"_command_lines.txt"

				cp -f $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bam" $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_DS.bam"
				cp -f $CORE_PATH/$PROJECT/TEMP/$SM_TAG".bai" $CORE_PATH/$PROJECT/TEMP/$SM_TAG"_DS.bai"

		fi

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

END_DOWNSAMPLE_BAM=`date '+%s'` # capture time process starts for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT"_BAM_REPORTS,Z.01,DOWNSAMPLE_BAM,"$HOSTNAME","$START_DOWNSAMPLE_BAM","$END_DOWNSAMPLE_BAM \
	>> $CORE_PATH/$PROJECT/$SM_TAG/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

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

# Select INDEL and MIXED sites
	# there should be any mnp or symbolic sites, but just in case

START_EXTRACT_INDEL_MIXED=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $ALIGNMENT_CONTAINER java -jar" \
			CMD=$CMD" /gatk/gatk.jar" \
		CMD=$CMD" SelectVariants" \
			CMD=$CMD" --reference $REF_GENOME" \
			CMD=$CMD" --variant $CORE_PATH/$PROJECT/TEMP/$SM_TAG.RAW.ANNOTATED.vcf.gz" \
			CMD=$CMD" --output $CORE_PATH/$PROJECT/TEMP/$SM_TAG.RAW.ANNOTATED.INDEL_MIXED.vcf.gz" \
			CMD=$CMD" --select-type-to-include INDEL" \
			CMD=$CMD" --select-type-to-include MIXED" \
			CMD=$CMD" --select-type-to-include MNP" \
			CMD=$CMD" --select-type-to-include SYMBOLIC"

	# write command line to file and execute the command line

		echo $CMD >> $CORE_PATH/$PROJECT/COMMAND_LINES/$PROJECT"_command_lines.txt"
		echo >> $CORE_PATH/$PROJECT/COMMAND_LINES/$PROJECT"_command_lines.txt"
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

END_EXTRACT_INDEL_MIXED=`date '+%s'` # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo $PROJECT",K.001,EXTRACT_INDEL_MIXED,"$HOSTNAME","$START_EXTRACT_INDEL_MIXED","$END_EXTRACT_INDEL_MIXED \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

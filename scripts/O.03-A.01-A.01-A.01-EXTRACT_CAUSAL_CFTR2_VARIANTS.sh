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
	CFTR2_CAUSAL_VCF=$6
	CFTR2_VEP_TABLE=$7
	SAMPLE_SHEET=$8
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$9

# grab causal cftr2 variants, but ignore poly T and TG tracts.

START_EXTRACT_CAUSAL=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $ALIGNMENT_CONTAINER" \
			CMD=$CMD" bcftools" \
		CMD=$CMD" isec" \
			CMD=$CMD" -n=2" \
			CMD=$CMD" -w1" \
			CMD=$CMD" -e'POS>=117908552 & POS<=117908576'" \
			CMD=$CMD" --output-type v" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/CFTR2/$SM_TAG".CFTR_REGION_VARIANT_ONLY.DandN.CFTR2.vcf.gz"" \
			CMD=$CMD" $CFTR2_CAUSAL_VCF" \
		CMD=$CMD" | grep -v ^#" \
		CMD=$CMD" | awk '{split(\$10,GT,\":\");" \
			CMD=$CMD" if (GT[1]==\"1/1\") print \"$SM_TAG\" , \$3 \"\n\" \"$SM_TAG\" , \$3 ;" \
			CMD=$CMD" else if (GT[1]==\"0/1\") print \"$SM_TAG\" , \$3 ;" \
			CMD=$CMD" else if (GT[1]==\"./1\") print \"$SM_TAG\" , \$3 ;" \
			CMD=$CMD" else if (GT[1]==\"1/.\") print \"$SM_TAG\" , \$3}'" \
		CMD=$CMD" | sort -k 2,2" \
		CMD=$CMD" | join " \
			CMD=$CMD" -1 2" \
			CMD=$CMD" -2 1" \
			CMD=$CMD" -o 1.1,1.2,2.4 " \
			CMD=$CMD" /dev/stdin " \
			CMD=$CMD" $CFTR2_VEP_TABLE" \
		CMD=$CMD" | singularity exec $ALIGNMENT_CONTAINER" \
			CMD=$CMD" datamash" \
		CMD=$CMD" -W" \
			CMD=$CMD" -g 1" \
			CMD=$CMD" collapse 2" \
			CMD=$CMD" collapse 3" \
		CMD=$CMD" | awk 'gsub(/,/ , \"\t\" , \$2) " \
			CMD=$CMD" gsub(/,/ , \";\" , \$3)' " \
		CMD=$CMD" | awk '{if (\$1!=\"\" && \$2!=\"\" && \$3!=\"\" && \$4!=\"\" && \$5==\"\") " \
			CMD=$CMD" print \$1,\$2,\$3,\"NONE\",\$4 ;" \
		CMD=$CMD" else if (\$1!=\"\" && \$2!=\"\" && \$3!=\"\" && \$4==\"\" && \$5==\"\") "
			CMD=$CMD" print \$1 , \$2 , \"NONE\" , \"NONE\" , \$3 ;" \
		CMD=$CMD" else print \$0}'" \
		CMD=$CMD" | awk 'END {if (NR==1) print \$0 ; " \
			CMD=$CMD" else print \"$SM_TAG\" , \"NONE\" , \"NONE\" , \"NONE\" , \"NA\"}'"
		CMD=$CMD" | awk 'BEGIN {print \"SAMPLE\" , \"CF-causing_mutation1\" , \"CF-causing_mutation2\" , " \
			CMD=$CMD" \"CF-causing_mutation3\" , \"CAUSAL_CONSEQUENCE\"} {print \$0}'" \
		CMD=$CMD" | sed 's/ /\t/g'" \
		CMD=$CMD" | sed 's/,/;/g'" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/$SM_TAG/CFTR2/$SM_TAG".CFTR2_CAUSING_VARIANTS.txt""

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

END_EXTRACT_CAUSAL=`date '+%s'` # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo $PROJECT",N.001,EXTRACT_CAUSAL,"$HOSTNAME","$START_EXTRACT_CAUSAL","$END_EXTRACT_CAUSAL \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

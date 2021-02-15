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
	CFTR2_VCF=$6
	CFTR2_VEP_TABLE=$7
	CFTR2_RAW_TABLE=$8
	SAMPLE_SHEET=$9
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=${10}

# extract cftr2 variants, but ignore poly T and TG tracts

START_EXTRACT_CFTR2=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $ALIGNMENT_CONTAINER" \
			CMD=$CMD" bcftools" \
		CMD=$CMD" isec" \
			CMD=$CMD" -n=2" \
			CMD=$CMD" -w1" \
			CMD=$CMD" -e'POS>=117188660 & POS<=117188689'" \
			CMD=$CMD" --output-type v" \
			CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/CFTR2/$SM_TAG".CFTR_REGION_VARIANT_ONLY.DandN.CFTR2.vcf.gz"" \
			CMD=$CMD" $CFTR2_VCF" \
		CMD=$CMD" | grep -v ^#" \
		CMD=$CMD" | awk 'BEGIN {OFS=\"\t\"} "
			CMD=$CMD" {split(\$10,GT,\":\");" \
			CMD=$CMD" if (GT[1]==\"1/1\") print \"$SM_TAG\" , \$3 , \"VAR_HOM\" , \$2 , \$7 ;" \
			CMD=$CMD" else if (GT[1]==\"0/1\") print \"$SM_TAG\" , \$3 , \"HET\" , \$2 , \$7 ;" \
			CMD=$CMD" else if (GT[1]==\"./1\") print \"$SM_TAG\" , \$3 , \"HET\" , \$2 , \$7 ;" \
			CMD=$CMD" else if (GT[1]==\"1/.\") print \"$SM_TAG\" , \$3 , \"HET\" , \$2 , \$7 }'" \
		CMD=$CMD" | sort -k 2,2" \
		# join with the vep table
		CMD=$CMD" | join" \
			CMD=$CMD" -1 2" \
			CMD=$CMD" -2 1" \
			CMD=$CMD" -o 1.1,1.2,2.4,1.3,1.4,1.5" \
			CMD=$CMD" /dev/stdin" \
			CMD=$CMD" $CFTR2_VEP_TABLE" \
		CMD=$CMD" | sed 's/ /\t/g'" \
		# if vep has multiple func. conseq. for a variant, it comma delimits
		# changing it to pipe delimited...which eventually gets changed to semi-colon
		# in the final cftr2 report.
		CMD=$CMD" | sed 's/,/|/g'" \
		# join with the raw cftr2 table
		CMD=$CMD" | join" \
			CMD=$CMD" -t $'\t'" \
			CMD=$CMD" -1 2" \
			CMD=$CMD" -2 1" \
			CMD=$CMD" -o 1.1,1.2,2.9,1.3,1.4,1.5,1.6" \
			CMD=$CMD" /dev/stdin" \
			CMD=$CMD" $CFTR2_RAW_TABLE" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".CFTR2_VARIANTS.txt" && " \
		CMD=$CMD" if [ -s $CORE_PATH/$PROJECT/TEMP/$SM_TAG".CFTR2_VARIANTS.txt" ] ; " \
			CMD=$CMD" then " \
				CMD=$CMD" cat $CORE_PATH/$PROJECT/TEMP/$SM_TAG".CFTR2_VARIANTS.txt" ; " \
			CMD=$CMD" else " \
				CMD=$CMD" printf \"$SM_TAG NONE NA NA NA NA NA\" ; " \
			CMD=$CMD" fi"
		CMD=$CMD" | awk 'BEGIN {print \"SAMPLE\" \"\t\" \"HGVS_CDNA\" \"\t\" \"CFTR2_DDL_CLASSIFICATION\" " \
			CMD=$CMD" \"\t\" \"CONSEQUENCE\" \"\t\" \"GENOTYPE\" \"\t\" \"POSITION\" \"\t\" \"FILTER\"} " \
			CMD=$CMD" {print \$0}'" \
		CMD=$CMD" | sed 's/,/;/g'" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/$SM_TAG/CFTR2/$SM_TAG".CFTR2_VARIANTS.txt""

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

END_EXTRACT_CFTR2=`date '+%s'` # capture time process ends for wall clock tracking purposes.

# write out timing metrics to file

	echo $PROJECT",N.001,EXTRACT_CFTR2,"$HOSTNAME","$START_EXTRACT_CFTR2","$END_EXTRACT_CFTR2 \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

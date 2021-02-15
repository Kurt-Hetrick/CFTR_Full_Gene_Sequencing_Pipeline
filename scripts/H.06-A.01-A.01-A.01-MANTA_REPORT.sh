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
	CFTR_EXONS=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$8

## reformat manta vcf into a tab delimited file
## intersect with cftr exons bed file and annotate SV with exon numbers affected

START_MANTA_REPORT=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="awk 'BEGIN {OFS=\"\t\"} " \
			CMD=$CMD" NR>1" \
			CMD=$CMD" {split(\$8,ALT,/[\[\]:]/);" \
			CMD=$CMD" if (\$4==\"BND\"&&ALT[2]==\"7\")" \
			CMD=$CMD" print \$1 , \$2-1 , ALT[3] , \$4 , ALT[3]-(\$2-1) , \$11 , \$10 ;" \
			CMD=$CMD" else print \$1 , \$2-1 , \$3 , \$4 , \$5 , \$11 , \$10}'" \
		CMD=$CMD" $CORE_PATH/$PROJECT/$SM_TAG/MANTA/$SM_TAG".MANTA_TABLE.txt"" \
		CMD=$CMD" | awk 'BEGIN {OFS=\"\t\"} " \
			CMD=$CMD" { if (\$2>\$3) print \$1 , \$3 , \$2 , \$4 , \$5 , \$6 , \$7 ;" \
			CMD=$CMD" else print \$0}'" \
		CMD=$CMD" | singularity exec $ALIGNMENT_CONTAINER bedtools" \
			CMD=$CMD" intersect" \
				CMD=$CMD" -wao" \
				CMD=$CMD" -b $CFTR_EXONS" \
				CMD=$CMD" -a -" \
		CMD=$CMD" | singularity exec $ALIGNMENT_CONTAINER datamash" \
			CMD=$CMD" -g 1,2,3,4,5,6,7" \
			CMD=$CMD" collapse 13" \
		CMD=$CMD" | awk 'BEGIN {OFS=\"\t\"} " \
		CMD=$CMD" {print \"$SM_TAG\" , \$4 , \$5 , \$8 , \$1\":\"\$2+1\"-\"\$3 , \$6 , \$7}'" \
		CMD=$CMD" | sed 's/,/|/g'" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/TEMP/$SM_TAG".MANTA_REPORT.txt" && " \
		CMD=$CMD" if [ -s $CORE_PATH/$PROJECT/TEMP/$SM_TAG".MANTA_REPORT.txt" ] ; " \
			CMD=$CMD" then " \
				CMD=$CMD" cat $CORE_PATH/$PROJECT/TEMP/$SM_TAG".MANTA_REPORT.txt" ; " \
			CMD=$CMD" else " \
				CMD=$CMD" printf \"$SM_TAG NONE NA NA NA NA NA\" ; " \
			CMD=$CMD" fi"
		CMD=$CMD" | awk '{if (\$6==1) print \$1 , \$2 , \$3 , \$4 , \$5 , \"HET\" , \$7 ; " \
			CMD=$CMD" else if (\$6==0) print \$1 , \$2 , \$3 , \$4 , \$5 , \"HOM\" , \$7 ; " \
			CMD=$CMD" else print \$0}'" \
		CMD=$CMD" | awk 'BEGIN {print \"SAMPLE\" , \"CFTR_SV_TYPE\" , \"SV_SIZE\" , " \
			CMD=$CMD" \"CFTR_EXONS\" , \"CFTR_LOCATION\" , \"GENOTYPE\" , \"MANTA_FILTER\"} {print \$0}'" \
		CMD=$CMD" | sed 's/ /\t/g'" \
		CMD=$CMD" >| $CORE_PATH/$PROJECT/$SM_TAG/MANTA/$SM_TAG".MANTA_REPORT.txt""

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

END_MANTA_REPORT=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",H.001,MANTA_REPORT,"$HOSTNAME","$START_MANTA_REPORT","$END_MANTA_REPORT \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

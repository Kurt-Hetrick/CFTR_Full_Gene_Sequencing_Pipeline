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

	GATK_3_5_0_CONTAINER=$1
	CORE_PATH=$2

	PROJECT=$3
	SM_TAG=$4
	REF_GENOME=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=$(basename $SAMPLE_SHEET .csv)
	SUBMIT_STAMP=$7

## reformat manta vcf into a tab delimited file
## intersect with cftr exons bed file and annotate SV with exon numbers affected

START_MANTA_VCF_TO_TABLE=`date '+%s'` # capture time process starts for wall clock tracking purposes.

	# construct command line

		CMD="singularity exec $GATK_3_5_0_CONTAINER java -jar" \
			CMD=$CMD" /usr/GenomeAnalysisTK.jar" \
		CMD=$CMD" -T VariantsToTable"
			CMD=$CMD" -R $REF_GENOME" \
			CMD=$CMD" --variant $CORE_PATH/$PROJECT/$SM_TAG/MANTA/results/variants/diploidSV.vcf.gz" \
			CMD=$CMD" -o $CORE_PATH/$PROJECT/$SM_TAG/MANTA/$SM_TAG.MANTA_OUT.txt" \
			CMD=$CMD" --disable_auto_index_creation_and_locking_when_reading_rods" \
			CMD=$CMD" -raw" \
			CMD=$CMD" -AMD" \
			CMD=$CMD" -F CHROM" \
			CMD=$CMD" -F POS" \
			CMD=$CMD" -F END" \
			CMD=$CMD" -F SVTYPE" \
			CMD=$CMD" -F SVLEN" \
			CMD=$CMD" -F ID" \
			CMD=$CMD" -F REF" \
			CMD=$CMD" -F ALT" \
			CMD=$CMD" -F QUAL" \
			CMD=$CMD" -F FILTER" \
			CMD=$CMD" -F IMPRECISE" \
			CMD=$CMD" -F CIPOS" \
			CMD=$CMD" -F CIEND" \
			CMD=$CMD" -F CIGAR" \
			CMD=$CMD" -F MATEID" \
			CMD=$CMD" -F EVENT" \
			CMD=$CMD" -F HOMLEN" \
			CMD=$CMD" -F HOMSEQ" \
			CMD=$CMD" -F SVINSLEN" \
			CMD=$CMD" -F SVINSSEQ" \
			CMD=$CMD" -F LEFT_SVINSSEQ" \
			CMD=$CMD" -F RIGHT_SVINSSEQ" \
			CMD=$CMD" -F INV3" \
			CMD=$CMD" -F INV5" \
			CMD=$CMD" -F BND_DEPTH" \
			CMD=$CMD" -F MATE_BND_DEPTH" \
			CMD=$CMD" -F JUNCTION_QUAL" \
			CMD=$CMD" -GF GT" \
			CMD=$CMD" -GF PR" \
			CMD=$CMD" -GF SR" \
			CMD=$CMD" -GF FT" \
			CMD=$CMD" -GF PL"

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

END_MANTA_VCF_TO_TABLE=`date '+%s'` # capture time process stops for wall clock tracking purposes.

# write out timing metrics to file

	echo $SM_TAG"_"$PROJECT",H.001,MANTA_VCF_TO_TABLE,"$HOSTNAME","$START_MANTA_VCF_TO_TABLE","$MANTA_VCF_TO_TABLE \
	>> $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv"

# exit with the signal from the program

	exit $SCRIPT_STATUS

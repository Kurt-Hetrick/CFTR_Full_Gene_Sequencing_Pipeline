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

	TARGET_BED=$5
		TARGET_BED_NAME=$(basename $TARGET_BED .bed)
	BAIT_BED=$6
		BAIT_BED_NAME=$(basename $BAIT_BED .bed)
	TITV_BED=$7
		TITV_BED_NAME=$(basename $TITV_BED .bed)
	REF_GENOME=$8
		REF_DIR=$(dirname $REF_GENOME)
		REF_BASENAME=$(basename $REF_GENOME | sed 's/.fasta//g ; s/.fa//g')
	GVCF_PAD=$9

# FIX THE BAIT BED FILE.
	# make sure that there is EOF
	# remove CARRIAGE RETURNS
	# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
	# remove chr prefix
	# remove MT genome (done in another pipeline)
# FOR DATA PROCESSING AND METRICS REPORTS AS WELL.

	awk 1 $BAIT_BED \
		| sed 's/\r//g' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sed 's/^chr//g' \
		| grep -v "^MT" \
	>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$BAIT_BED_NAME".bed"

# FIX THE TITV BED FILE FOR DATA PROCESSING AND METRICS REPORTS.
	# make sure that there is EOF
	# remove CARRIAGE RETURNS
	# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
	# remove chr prefix
	# remove MT genome (done in another pipeline)
# this is not used to calculate titv anymore. this is actually just the barcode regions.
# will be used when making a gvcf bed file.

	awk 1 $TITV_BED \
		| sed 's/\r//g' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sed 's/^chr//g' \
		| grep -v "^MT" \
	>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TITV_BED_NAME".bed"

# FIX THE TARGET BED FILE
	# make sure that there is EOF
	# remove CARRIAGE RETURNS
	# CONVERT VARIABLE LENGTH WHITESPACE FIELD DELIMETERS TO SINGLE TAB.
	# remove chr prefix
	# remove MT genome (done in another pipeline)
# FOR DATA PROCESSING AND METRICS REPORTS.

	awk 1 $TARGET_BED \
		| sed 's/\r//g' \
		| sed -r 's/[[:space:]]+/\t/g' \
		| sed 's/^chr//g' \
		| grep -v "^MT" \
	>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TARGET_BED_NAME".bed"

# THE GVCF BED FILE the BAIT bed file with the cftr target padded by 250 bp.
# the rest of the targets (the barcode targets) are unpadded.

	awk 'BEGIN {OFS="\t"} {print $1 , $2-"'$GVCF_PAD'" , $3+"'$GVCF_PAD'"}' \
	$CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TARGET_BED_NAME".bed" \
	| cat \
		/dev/stdin \
		$CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TITV_BED_NAME".bed" \
	>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$BAIT_BED_NAME"-"$GVCF_PAD"-BP-PAD-GVCF.bed"

# MAKE PICARD INTERVAL FILES (1-based start)
	# Grab the SEQUENCING DICTIONARY from the ".dict" file in the directory where the reference genome is located
	# then concatenate with the fixed bed file.
	# add 1 to the start
# picard interval needs strand information and a locus name
	# made everything plus stranded b/c i don't think this information is used
	# constructed locus name with chr name, start+1, stop

	# bait bed

		(grep "^@SQ" $REF_DIR/$REF_BASENAME".dict" \
			; awk 'BEGIN {OFS="\t"} {print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
				$CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$BAIT_BED_NAME".bed") \
		>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$BAIT_BED_NAME"-picard.bed"

	# target bed

		(grep "^@SQ" $REF_DIR/$REF_BASENAME".dict" \
			; awk 'BEGIN {OFS="\t"} {print $1,($2+1),$3,"+",$1"_"($2+1)"_"$3}' \
				$CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TARGET_BED_NAME".bed") \
		>| $CORE_PATH/$PROJECT/TEMP/$SM_TAG"-"$TARGET_BED_NAME"-picard.bed"

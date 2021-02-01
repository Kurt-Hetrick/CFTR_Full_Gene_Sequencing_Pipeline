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

	SCRIPT_DIR=$4
	SUBMITTER_ID=$5
	SAMPLE_SHEET=$6
		SAMPLE_SHEET_NAME=(`basename $SAMPLE_SHEET .csv`)
	SUBMIT_STAMP=$7
	SEND_TO=$8

		TIMESTAMP=`date '+%F.%H-%M-%S'`

# combining all the individual qc reports for the project and adding the header.

	for SM_TAG in $(awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} $1=="'$PROJECT'" {print $8}' \
			| sort \
			| uniq );
	do 
		cat $CORE_PATH/$PROJECT/$SM_TAG/REPORTS/QC_REPORT_PREP/$SM_TAG".QC_REPORT_PREP.txt"
	done \
		| sort -k 2,2 \
		| awk 'BEGIN {print "PROJECT",\
			"SM_TAG",\
			"RG_PU",\
			"LIBRARY",\
			"LIBRARY_PLATE",\
			"LIBRARY_WELL",\
			"LIBRARY_ROW",\
			"LIBRARY_COLUMN",\
			"HYB_PLATE",\
			"HYB_WELL",\
			"HYB_ROW",\
			"HYB_COLUMN",\
			"SEX",\
			"X_HET_COUNT",\
			"Y_COUNT",\
			"EXPECTED_SEX",\
			"VERIFYBAM_FREEMIX_PCT",\
			"VERIFYBAM_#SNPS",\
			"VERIFYBAM_FREELK1",\
			"VERIFYBAM_FREELK0",\
			"VERIFYBAM_DIFF_LK0_LK1",\
			"VERIFYBAM_AVG_DP",\
			"MEDIAN_INSERT_SIZE",\
			"MEAN_INSERT_SIZE",\
			"STANDARD_DEVIATION_INSERT_SIZE",\
			"MAD_INSERT_SIZE",\
			"PCT_PF_READS_ALIGNED_R1",\
			"PF_HQ_ALIGNED_READS_R1",\
			"PF_HQ_ALIGNED_Q20_BASES_R1",\
			"PF_MISMATCH_RATE_R1",\
			"PF_HQ_ERROR_RATE_R1",\
			"PF_INDEL_RATE_R1",\
			"PCT_READS_ALIGNED_IN_PAIRS_R1",\
			"PCT_ADAPTER_R1",\
			"PCT_PF_READS_ALIGNED_R2",\
			"PF_HQ_ALIGNED_READS_R2",\
			"PF_HQ_ALIGNED_Q20_BASES_R2",\
			"PF_MISMATCH_RATE_R2",\
			"PF_HQ_ERROR_RATE_R2",\
			"PF_INDEL_RATE_R2",\
			"PCT_READS_ALIGNED_IN_PAIRS_R2",\
			"PCT_ADAPTER_R2",\
			"TOTAL_READS",\
			"RAW_GIGS",\
			"PCT_PF_READS_ALIGNED_PAIR",\
			"PF_MISMATCH_RATE_PAIR",\
			"PF_HQ_ERROR_RATE_PAIR",\
			"PF_INDEL_RATE_PAIR",\
			"PCT_READS_ALIGNED_IN_PAIRS_PAIR",\
			"STRAND_BALANCE_PAIR",\
			"PCT_CHIMERAS_PAIR",\
			"PF_HQ_ALIGNED_Q20_BASES_PAIR",\
			"MEAN_READ_LENGTH",\
			"PCT_PF_READS_IMPROPER_PAIRS_PAIR",\
			"UNMAPPED_READS",\
			"READ_PAIR_OPTICAL_DUPLICATES",\
			"PERCENT_DUPLICATION",\
			"ESTIMATED_LIBRARY_SIZE",\
			"SECONDARY_OR_SUPPLEMENTARY_READS",\
			"READ_PAIR_DUPLICATES",\
			"READ_PAIRS_EXAMINED",\
			"PAIRED_DUP_RATE",\
			"UNPAIRED_READ_DUPLICATES",\
			"UNPAIRED_READS_EXAMINED",\
			"UNPAIRED_DUP_RATE",\
			"PERCENT_DUPLICATION_OPTICAL",\
			"GENOME_SIZE",\
			"BAIT_TERRITORY",\
			"TARGET_TERRITORY",\
			"PCT_PF_UQ_READS_ALIGNED",\
			"PF_UQ_GIGS_ALIGNED",\
			"PCT_SELECTED_BASES",\
			"ON_BAIT_VS_SELECTED",\
			"MEAN_TARGET_COVERAGE",\
			"MEDIAN_TARGET_COVERAGE",\
			"MAX_TARGET_COVERAGE",\
			"ZERO_CVG_TARGETS_PCT",\
			"PCT_EXC_MAPQ",\
			"PCT_EXC_BASEQ",\
			"PCT_EXC_OVERLAP",\
			"PCT_EXC_OFF_TARGET",\
			"FOLD_80_BASE_PENALTY",\
			"PCT_TARGET_BASES_1X",\
			"PCT_TARGET_BASES_2X",\
			"PCT_TARGET_BASES_10X",\
			"PCT_TARGET_BASES_20X",\
			"PCT_TARGET_BASES_30X",\
			"PCT_TARGET_BASES_40X",\
			"PCT_TARGET_BASES_50X",\
			"PCT_TARGET_BASES_100X",\
			"HS_LIBRARY_SIZE",\
			"AT_DROPOUT",\
			"GC_DROPOUT",\
			"THEORETICAL_HET_SENSITIVITY",\
			"HET_SNP_Q",\
			"BAIT_SET",\
			"PCT_USABLE_BASES_ON_BAIT",\
			"Cref_Q",\
			"Gref_Q",\
			"DEAMINATION_Q",\
			"OxoG_Q",\
			"PCT_A",\
			"PCT_C",\
			"PCT_G",\
			"PCT_T",\
			"PCT_N",\
			"PCT_A_to_C",\
			"PCT_A_to_G",\
			"PCT_A_to_T",\
			"PCT_C_to_A",\
			"PCT_C_to_G",\
			"PCT_C_to_T",\
			"HET_HOMVAR_RATIO",\
			"PCT_GQ0_VARIANTS",\
			"TOTAL_GQ0_VARIANTS",\
			"TOTAL_HET_DEPTH",\
			"TOTAL_SNPS",\
			"NUM_IN_DB_SNP",\
			"NOVEL_SNPS",\
			"FILTERED_SNPS",\
			"PCT_DBSNP",\
			"DBSNP_TITV",\
			"NOVEL_TITV",\
			"TOTAL_INDELS",\
			"NOVEL_INDELS",\
			"FILTERED_INDELS",\
			"PCT_DBSNP_INDELS",\
			"NUM_IN_DB_SNP_INDELS",\
			"DBSNP_INS_DEL_RATIO",\
			"NOVEL_INS_DEL_RATIO",\
			"TOTAL_MULTIALLELIC_SNPS",\
			"NUM_IN_DB_SNP_MULTIALLELIC",\
			"TOTAL_COMPLEX_INDELS",\
			"NUM_IN_DB_SNP_COMPLEX_INDELS",\
			"SNP_REFERENCE_BIAS",\
			"NUM_SINGLETONS"} \
			{print $0}' \
	| sed 's/ /,/g' \
	| sed 's/\t/,/g' \
	>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".QC_REPORT."$TIMESTAMP".csv"

##############################################################################################
##### If samples have multiple libraries or total failures send notification to MS Teams #####
##############################################################################################

	# if [[ -f $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_MULTIPLE_LIBS.txt" ]]
	# 	then
	# 		mail -s "BATCH $SAMPLE_SHEET_NAME FOR $PROJECT HAS THESE SAMPLES WITH MULITPLE LIBRARIES OR TOTAL FAILURES" \
	# 		$SEND_TO \
	# 		< $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_MULTIPLE_LIBS.txt"
	# 			sleep 2s
	# fi

##############################################################
##### CLEAN-UP OR NOT DEPENDING ON IF JOBS FAILED OR NOT #####
##### RUN MD5 CHECK ON REMAINING FILES #######################
##############################################################

	# CREATE SAMPLE ARRAY, USED DURING PROJECT CLEANUP

		CREATE_SAMPLE_ARRAY_FOR_FILE_CLEANUP ()
		{
			SAMPLE_ARRAY=(`awk 1 $SAMPLE_SHEET \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
				| awk 'BEGIN {FS=",";OFS="\t"} $1=="'$PROJECT'"&&$8=="'$SM_TAG'" {print $1,$8,$2"_"$3"_"$4"*"}' \
				| sort \
				| uniq \
				| singularity exec $ALIGNMENT_CONTAINER datamash -g 1,2 collapse 3`)

				#  1  Project=the Seq Proj folder name
				PROJECT_FILE_CLEANUP=${SAMPLE_ARRAY[0]}

				#  8  SM_Tag=sample ID
				SM_TAG_FILE_CLEANUP=${SAMPLE_ARRAY[1]}

				# PLATFORM UNIT: COMPRISED OF;
					#  2  FCID=flowcell that sample read group was performed on
					#  3  Lane=lane of flowcell that sample read group was performed on]
					#  4  Index=sample barcode
				PLATFORM_UNIT=${SAMPLE_ARRAY[2]}
		}

	# RUN MD5 IN PARALLEL USING 90% OF THE CPU PROCESSORS

		RUN_MD5_PARALLEL ()
		{
			find $CORE_PATH/$PROJECT -type f \
				| cut -f 2 \
				| singularity exec $ALIGNMENT_CONTAINER \
					parallel \
						--no-notice \
						--jobs 90% \
						md5sum {} \
			> $CORE_PATH/$PROJECT/REPORTS/"md5_"$PROJECT"_"$TIMESTAMP".txt"
		}

# IF THERE ARE NO FAILED JOBS THEN DELETE TEMP FILES STARTING WITH SM_TAG OR PLATFORM_UNIT
# ELSE; DON'T DELETE ANYTHING BUT SUMMARIZE WHAT FAILED.
# AFTER TEMP FILES ARE DELETED RUN MD5 IN PARALLEL

	if [[ ! -f $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt" ]]
		then
			for SM_TAG in $(awk 'BEGIN {FS=","} $1=="'$PROJECT'" {print $8}' $SAMPLE_SHEET | sort | uniq)
				do
					CREATE_SAMPLE_ARRAY_FOR_FILE_CLEANUP
					DELETION_PATH=" $CORE_PATH/$PROJECT_FILE_CLEANUP/TEMP/"

					echo rm -rf $CORE_PATH/$PROJECT_FILE_CLEANUP/TEMP/$SM_TAG_FILE_CLEANUP*
					echo rm -rf $CORE_PATH/$PROJECT_FILE_CLEANUP/TEMP/$PLATFORM_UNIT | sed "s|,|$DELETION_PATH|g"

					rm -rf $CORE_PATH/$PROJECT_FILE_CLEANUP/TEMP/$SM_TAG_FILE_CLEANUP* | bash
					echo rm -rf $CORE_PATH/$PROJECT_FILE_CLEANUP/TEMP/$PLATFORM_UNIT | sed "s|,|$DELETION_PATH|g" | bash
			done

			RUN_MD5_PARALLEL

			printf "$PERSON_NAME Was The Submitter\n \
				REPORTS ARE AT:\n $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS\n\n \
				BATCH QC REPORT:\n $SAMPLE_SHEET_NAME".QC_REPORT.csv"\n\n \
				FILE MD5 HASHSUMS:\n "md5_"$PROJECT"_"$TIMESTAMP".txt"\n\n \
				NO JOBS FAILED: TEMP FILES DELETED" \
				| mail -s "$SAMPLE_SHEET FOR $PROJECT has finished processing SUBMITTER_CFTR_Full_Gene_Sequencing_Pipeline.sh" \
					$SEND_TO

		else
			# CONSTRUCT MESSAGE TO BE SENT SUMMARIZING THE FAILED JOBS
				printf "SO BAD THINGS HAPPENED AND THE TEMP FILES WILL NOT BE DELETED FOR:\n" \
					>| $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "$SAMPLE_SHEET\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "FOR PROJECT:\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "$PROJECT\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "SOMEWHAT FULL LISTING OF FAILED JOBS ARE HERE:\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "$CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt"\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "###################################################################\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "BELOW ARE THE SAMPLES AND THE MINIMUM NUMBER OF JOBS THAT FAILED PER SAMPLE:\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "###################################################################\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				egrep -v CONCORDANCE $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt" \
					| awk 'BEGIN {OFS="\t"} NF==6 {print $1}' \
					| sort \
					| singularity exec $ALIGNMENT_CONTAINER datamash -g 1 count 1 \
				>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "###################################################################\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "FOR THE SAMPLES THAT HAVE FAILED JOBS, THIS IS ROUGHLY THE FIRST JOB THAT FAILED FOR EACH SAMPLE:\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "###################################################################\n" \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

				printf "SM_TAG NODE JOB_NAME USER EXIT LOG_FILE\n" | sed 's/ /\t/g' \
						>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

			for sample in $(awk 'BEGIN {OFS="\t"} NF==6 {print $1}' $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt" | sort | uniq);
				do
					awk '$1=="'$sample'" {print $0 "\n" "\n"}' $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_ERRORS.txt" | head -n 1 \
					>> $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"
			done

			sleep 2s

			mail -s "FAILED JOBS: $PROJECT: $SAMPLE_SHEET_NAME" \
			$SEND_TO \
			< $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_EMAIL_SUMMARY.txt"

	fi

	sleep 2s

####################################################
##### Clean up the Wall Clock minutes tracker. #####
####################################################

	# clean up records that are malformed
	# only keep jobs that ran longer than 3 minutes

		awk 'BEGIN {FS=",";OFS=","} $1~/^[A-Z 0-9]/&&$2!=""&&$3!=""&&$4!=""&&$5!=""&&$6!=""&&$7==""&&$5!~/A-Z/&&$6!~/A-Z/&&($6-$5)>180 \
		{print $1,$2,$3,$4,$5,$6,($6-$5)/60,strftime("%F",$5),strftime("%F",$6),strftime("%F.%H-%M-%S",$5),strftime("%F.%H-%M-%S",$6)}' \
		$CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.csv" \
		| sed 's/_'"$PROJECT"'/,'"$PROJECT"'/g' \
		| awk 'BEGIN {print "SAMPLE,PROJECT,TASK_GROUP,TASK,HOST,EPOCH_START,EPOCH_END,WC_MIN,START_DATE,END_DATE,TIMESTAMP_START,TIMESTAMP_END"} \
		{print $0}' \
		>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.FIXED.csv"

#############################################################
##### Summarize Wall Clock times ############################
##### This is probably garbage. I'll look at this later #####
#############################################################

	# summarize by sample by taking the max times per concurrent task group and summing them up

		sed 's/,/\t/g' $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.FIXED.csv" \
			| awk 'NR>1' \
			| sed 's/_BAM_REPORTS//g' \
			| sort -k 1,1 -k 2,2 -k 3,3 -k 4,4 \
			| awk 'BEGIN {OFS="\t"} {print $0,($7-$6),($7-$6)/60,($7-$6)/3600}' \
			| singularity exec $ALIGNMENT_CONTAINER datamash -s -g 1,2,3 max 13 max 14 max 15 | tee $CORE_PATH/$PROJECT/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
			| singularity exec $ALIGNMENT_CONTAINER datamash -g 1,2 sum 4 sum 5 sum 6 \
			| awk 'BEGIN {print "SAMPLE","PROJECT","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
			| sed -r 's/[[:space:]]+/,/g' \
		>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.BY_SAMPLE.csv"

	# break down by the longest task within a group per sample

		sed 's/\t/,/g' $CORE_PATH/$PROJECT/TEMP/WALL.CLOCK.TIMES.BY.GROUP.txt \
			| awk 'BEGIN {print "SAMPLE","PROJECT","TASK_GROUP","WALL_CLOCK_SECONDS","WALL_CLOCK_MINUTES","WALL_CLOCK_HOURS"} {print $0}' \
			| sed -r 's/[[:space:]]+/,/g' \
		>| $CORE_PATH/$PROJECT/REPORTS/$PROJECT".WALL.CLOCK.TIMES.BY_SAMPLE_GROUP.csv"

# put a stamp as to when the run was done

		echo Project finished at `date` >> $CORE_PATH/$PROJECT/REPORTS/PROJECT_START_END_TIMESTAMP.txt

#######################################################
#######################################################
##### SEND EMAIL NOTIFICATION SUMMARIES WHEN DONE #####
#######################################################
#######################################################

	# grab email addy

		SEND_TO=`cat $SCRIPT_DIR/../email_lists.txt`

	# grab submitter's name

		PERSON_NAME=`getent passwd | awk 'BEGIN {FS=":"} $1=="'$SUBMITTER_ID'" {print $5}'`

	# If there are samples with multiple libraries send that notification along with paths to the various report
	# otherwise just send out the email detailing where the reports are located at.

		# if [[ -f $CORE_PATH/$PROJECT/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_MULTIPLE_LIBS.txt" ]]
		# 	then
		# 		printf "$PERSON_NAME Was The Submitter\n \
		# 		THIS BATCH HAS SAMPLES WITH EITHER MULTIPLE LIBRARIES OR TOTAL FAILURES. THAT LIST WILL COME IN A SEPARATE NOTIFICATION\n \
		# 		REPORTS ARE AT:\n $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS\n\n \
		# 		BATCH QC REPORT:\n $SAMPLE_SHEET_NAME".QC_REPORT.csv"\n\n \
		# 		FILE MD5 HASHSUMS:\n "md5_"$PROJECT"_"$TIMESTAMP".txt"" \
		# 		| mail -s "$SAMPLE_SHEET FOR $PROJECT has finished processing SUBMITTER_CFTR_Full_Gene_Sequencing_Pipeline.sh" \
		# 			$SEND_TO
		# 	else
		# 		printf "$PERSON_NAME Was The Submitter\n \
		# 		REPORTS ARE AT:\n $CORE_PATH/$PROJECT/REPORTS/QC_REPORTS\n\n \
		# 		BATCH QC REPORT:\n $SAMPLE_SHEET_NAME".QC_REPORT.csv"\n\n \
		# 		FILE MD5 HASHSUMS:\n "md5_"$PROJECT"_"$TIMESTAMP".txt"" \
		# 		| mail -s "$SAMPLE_SHEET FOR $PROJECT has finished processing SUBMITTER_CFTR_Full_Gene_Sequencing_Pipeline.sh" \
		# 			$SEND_TO
		# fi

	# this is black magic that I don't know if it really helps. was having problems with getting the emails to send so I put a little delay in here.

		sleep 2s

	# add timestamp when project finished processing.

		echo Project started at `date` >> $CORE_PATH/$PROJECT/PROJECT_START_END_TIMESTAMP.txt

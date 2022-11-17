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
	EXPECTED_SEX=$5
	GIT_LFS_VERSION=$6
	SAMPLE_SHEET=$7
		SAMPLE_SHEET_NAME=$(basename ${SAMPLE_SHEET} .csv)
	SUBMIT_STAMP=$8

# next script will cat everything together and add the header.
# dirty validations count NF, if not X, then say haha you suck try again and don't write to cat file.

###########################################################################
##### Grabbing the BAM header (for RG ID,PU,LB,etc) #######################
##### ADDDING PIPELINE SCRIPT VERSION AND GIT LFS BACKED FILE VERSION #####
###########################################################################
###########################################################################
##### THIS IS THE HEADER ##################################################
##### "SM_TAG","PROJECT","RG_PU","LIBRARY" ################################
##### "LIBRARY_PLATE","LIBRARY_WELL","LIBRARY_ROW","LIBRARY_COLUMN" #######
##### "HYB_PLATE","HYB_WELL","HYB_ROW","HYB_COLUMN" #######################
##### "PIPELINE_VERSION","PIPELINE_FILES_VERSION "#################
###########################################################################

	if
		[ -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt ]
	then
		cat ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				-s \
				-g 1,2 \
				collapse 3 \
				unique 4 \
				unique 5 \
				unique 6 \
				unique 7 \
				unique 8 \
				unique 9 \
				unique 10 \
				unique 11 \
				unique 12 \
				unique 13 \
			| sed 's/,/;/g' \
			| awk 'BEGIN {FS="\t";OFS="\t"} \
				{print $0 , "ddl-ngs-main-" "'${GIT_LFS_VERSION}'"}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}.QC_REPORT_TEMP.txt

	elif
		[[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/RG_HEADER/${SM_TAG}.RG_HEADER.txt && -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}.cram ]]
	then

		# grab field number for SM_TAG

					SM_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools view -H \
					${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}".cram" \
						| grep -m 1 ^@RG \
						| sed 's/\t/\n/g' \
						| cat -n \
						| sed 's/^ *//g' \
						| awk '$2~/^SM:/ {print $1}'`)

		# grab field number for PLATFORM_UNIT_TAG

					PU_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools view -H \
					${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}".cram" \
						| grep -m 1 ^@RG \
						| sed 's/\t/\n/g' \
						| cat -n \
						| sed 's/^ *//g' \
						| awk '$2~/^PU:/ {print $1}'`)

		# grab field number for LIBRARY_TAG

					LB_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools view -H \
					${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}".cram" \
						| grep -m 1 ^@RG \
						| sed 's/\t/\n/g' \
						| cat -n \
						| sed 's/^ *//g' \
						| awk '$2~/^LB:/ {print $1}'`)

		# grab field number for PROGRAM_TAG

					PG_FIELD=(`singularity exec ${ALIGNMENT_CONTAINER} samtools view -H \
					${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}".cram" \
						| grep -m 1 ^@RG \
						| sed 's/\t/\n/g' \
						| cat -n \
						| sed 's/^ *//g' \
						| awk '$2~/^PG:/ {print $1}'`)

		# Now grab the header and format
			# breaking out the library name into its parts is assuming that the format is...
			# fill in empty fields with NA thing (for loop in awk) is a lifesaver
			# https://unix.stackexchange.com/questions/53448/replacing-missing-value-blank-space-with-zero

			singularity exec ${ALIGNMENT_CONTAINER} samtools \
				view \
				-H \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/CRAM/${SM_TAG}.cram \
				| grep ^@RG \
				| awk \
					-v SM_FIELD="$SM_FIELD" \
					-v PU_FIELD="$PU_FIELD" \
					-v LB_FIELD="$LB_FIELD" \
					-v PG_FIELD="$PG_FIELD" \
					'BEGIN {OFS="\t"} {split($SM_FIELD,SMtag,":"); split($PU_FIELD,PU,":"); split($LB_FIELD,Library,":"); split(Library[2],Library_Unit,"_"); split($PG_FIELD,Pipeline_Version,":"); \
					print "'${PROJECT}'",SMtag[2],PU[2],Library[2],Library_Unit[1],Library_Unit[2],substr(Library_Unit[2],1,1),substr(Library_Unit[2],2,2),\
					Library_Unit[3],Library_Unit[4],substr(Library_Unit[4],1,1),substr(Library_Unit[4],2,2),Pipeline_Version[2]}' \
				| awk 'BEGIN { FS = OFS = "\t" } \
					{ for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = "NA" }; 1' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					-s \
					-g 1,2 \
					collapse 3 \
					unique 4 \
					unique 5 \
					unique 6 \
					unique 7 \
					unique 8 \
					unique 9 \
					unique 10 \
					unique 11 \
					unique 12 \
					unique 13 \
				| sed 's/,/;/g' \
				| awk 'BEGIN {FS="\t";OFS="\t"} \
					{print $0 , "ddl-ngs-main-" "'${GIT_LFS_VERSION}'"}' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					transpose \
			>| ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}.QC_REPORT_TEMP.txt
	else
		echo -e "${PROJECT}\t${SM_TAG}\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA\tNA" \
		| singularity exec ${ALIGNMENT_CONTAINER} datamash \
			transpose \
		>| ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}.QC_REPORT_TEMP.txt
	fi

#################################################
##### GENDER CHECK FROM ANEUPLOIDY CHECK ########
#################################################
##### THIS IS THE HEADER ########################
##### SEX,X_HET_COUNT,Y_COUNT ###################
#################################################

# the number of heterozygous chrX SNPs
# and the number of high quality (Pass + qual>100) chr Y SNPs for each sample.

	# Male= no heterozygous chrX SNPs + 5 high quality chrY SNPs
	# Female= at least 1 heterozygous chrX SNP + 0 high quality chrY SNPs
	## It's very rare, but occasionally we get a female without any heterozygous chrX SNPs.
	## As long as they don't have any high quality chrY calls we say that the sex is consistent
	## this is coded as undetermined, but the lab would look at the vcf in more detail.

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}.BARCODE.vcf ]]
		then
			echo -e NA'\t'NaN'\t'NaN'\t'$EXPECTED_SEX \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else

			grep -v "^#" ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}.BARCODE.vcf \
				| awk '{X_HET_COUNT+=($1=="X" && $10 ~ /^0\/1/)} \
				{Y_VAR_COUNT+=($1=="Y" && $6>100 && $7=="PASS" && $10 ~ /^.\/./)} \
					END {if (X_HET_COUNT=="0" && Y_VAR_COUNT>=5) print "MALE",X_HET_COUNT,Y_VAR_COUNT,"'$EXPECTED_SEX'"; \
					else if (X_HET_COUNT>=1 && Y_VAR_COUNT=="0") print "FEMALE",X_HET_COUNT,Y_VAR_COUNT,"'$EXPECTED_SEX'"; \
					else print "UNDETERMINED",X_HET_COUNT,Y_VAR_COUNT,"'$EXPECTED_SEX'"}' \
				| sed 's/ /\t/g' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

	fi

##########################################################################################
##### VERIFY BAM ID ######################################################################
##########################################################################################
##### THIS IS THE HEADER #################################################################
##### "VERIFYBAM_FREEMIX","VERIFYBAM_#SNPS","VERIFYBAM_FREELK1","VERIFYBAM_FREELK0", #####
##### "VERIFYBAM_DIFF_LK0_LK1","VERIFYBAM_AVG_DP" ########################################
##########################################################################################
##### THIS IS FROM THE ORIGINAL FINAL BAM FILE ###########################################
##########################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VERIFYBAMID/${SM_TAG}".selfSM" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			awk 'BEGIN {OFS="\t"} NR>1 {print $7*100,$4,$8,$9,($9-$8),$6}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VERIFYBAMID/${SM_TAG}".selfSM" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

######################################################################################################
##### VERIFY BAM ID FROM DOWNSAMPLED BAM #############################################################
######################################################################################################
##### THIS IS THE HEADER #############################################################################
##### "VERIFYBAM_FREEMIX_DS","VERIFYBAM_#SNPS_DS","VERIFYBAM_FREELK1_DS","VERIFYBAM_FREELK0_DS", #####
##### "VERIFYBAM_DIFF_LK0_LK1_DS","VERIFYBAM_AVG_DP_DS" ##############################################
######################################################################################################
##### THIS IS FROM THE DOWNSAMPLED OR COPIED FINAL BAM FILE ##########################################
######################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VERIFYBAMID/${SM_TAG}"_DS.selfSM" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			awk 'BEGIN {OFS="\t"} NR>1 {print $7*100,$4,$8,$9,($9-$8),$6}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VERIFYBAMID/${SM_TAG}"_DS.selfSM" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

######################################################################################################
##### INSERT SIZE ####################################################################################
######################################################################################################
##### THIS IS THE HEADER #############################################################################
##### "MEDIAN_INSERT_SIZE","MEAN_INSERT_SIZE","STANDARD_DEVIATION_INSERT_SIZE","MAD_INSERT_SIZE" #####
######################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/INSERT_SIZE/METRICS/${SM_TAG}".insert_size_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			awk 'BEGIN {OFS="\t"} NR==8 {print $1,$6,$7,$3}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/INSERT_SIZE/METRICS/${SM_TAG}".insert_size_metrics.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

#######################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR READ 1 ############################################################
#######################################################################################################
##### THIS THE HEADER #################################################################################
##### "PCT_PF_READS_ALIGNED_R1","PF_HQ_ALIGNED_READS_R1","PF_HQ_ALIGNED_Q20_BASES_R1" #################
##### "PF_MISMATCH_RATE_R1","PF_HQ_ERROR_RATE_R1","PF_INDEL_RATE_R1" ##################################
##### "PCT_READS_ALIGNED_IN_PAIRS_R1","PCT_ADAPTER_R1" ################################################
#######################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			awk 'BEGIN {OFS="\t"} NR==8 {if ($1=="UNPAIRED") print "0","0","0","0","0","0","0","0"; \
				else print $7*100,$9,$11,$13,$14,$15,$18*100,$24*100}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

#######################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR READ 2 ############################################################
#######################################################################################################
##### THIS THE HEADER #################################################################################
##### "PCT_PF_READS_ALIGNED_R2","PF_HQ_ALIGNED_READS_R2","PF_HQ_ALIGNED_Q20_BASES_R2" #################
##### "PF_MISMATCH_RATE_R2","PF_HQ_ERROR_RATE_R2","PF_INDEL_RATE_R2" ##################################
##### "PCT_READS_ALIGNED_IN_PAIRS_R2","PCT_ADAPTER_R2" ################################################
#######################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else

			awk 'BEGIN {OFS="\t"} NR==9 {if ($1=="") print "0","0","0","0","0","0","0","0" ; \
				else print $7*100,$9,$11,$13,$14,$15,$18*100,$24*100}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

################################################################################################
##### ALIGNMENT SUMMARY METRICS FOR PAIR #######################################################
################################################################################################
##### THIS THE HEADER ##########################################################################
##### "TOTAL_READS","RAW_GIGS","PCT_PF_READS_ALIGNED_PAIR" #####################################
##### "PF_MISMATCH_RATE_PAIR","PF_HQ_ERROR_RATE_PAIR","PF_INDEL_RATE_PAIR" #####################
##### "PCT_READS_ALIGNED_IN_PAIRS_PAIR","STRAND_BALANCE_PAIR","PCT_CHIMERAS_PAIR" ##############
##### "PF_HQ_ALIGNED_Q20_BASES_PAIR","MEAN_READ_LENGTH","PCT_PF_READS_IMPROPER_PAIRS_PAIR" #####
################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else

			awk 'BEGIN {OFS="\t"} \
				NR==10 \
				{if ($1=="") print "0","0","0","0","0","0","0","0","0","0","0","0" ; \
				else print $2,($2*$16/1000000000),$7*100,$13,$14,$15,$18*100,$22,$23*100,$11,$16,$20*100}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ALIGNMENT_SUMMARY/${SM_TAG}".alignment_summary_metrics.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

##################################################################################################################
##### MARK DUPLICATES REPORT #####################################################################################
##################################################################################################################
##### THIS IS THE HEADER #########################################################################################
##### "UNMAPPED_READS","READ_PAIR_OPTICAL_DUPLICATES","PERCENT_DUPLICATION","ESTIMATED_LIBRARY_SIZE" #############
##### "SECONDARY_OR_SUPPLEMENTARY_READS","READ_PAIR_DUPLICATES","READ_PAIRS_EXAMINED","PAIRED_DUP_RATE" ##########
##### "UNPAIRED_READ_DUPLICATES","UNPAIRED_READS_EXAMINED","UNPAIRED_DUP_RATE","PERCENT_DUPLICATION_OPTICAL" #####
##################################################################################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/PICARD_DUPLICATES/${SM_TAG}"_MARK_DUPLICATES.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
		else
			MAX_RECORD=(`grep -n "^$" ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/PICARD_DUPLICATES/${SM_TAG}"_MARK_DUPLICATES.txt" | awk 'BEGIN {FS=":"} NR==2 {print $1}'`)

			awk 'BEGIN {OFS="\t"} \
				NR>7&&NR<'$MAX_RECORD' \
				{if ($10!~/[0-9]/) print $5,$8,"NaN","NaN",$4,$7,$3,"NaN",$6,$2,"NaN" ; \
				else if ($10~/[0-9]/&&$2=="0") print $5,$8,$9*100,$10,$4,$7,$3,($7/$3),$6,$2,"NaN" ; \
				else print $5,$8,$9*100,$10,$4,$7,$3,($7/$3),$6,$2,($6/$2)}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/PICARD_DUPLICATES/${SM_TAG}"_MARK_DUPLICATES.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash sum 1 sum 2 mean 4 sum 5 sum 6 sum 7 sum 9 sum 10 \
			| awk 'BEGIN {OFS="\t"} \
				{if ($3!~/[0-9]/) print $1,$2,"NaN","NaN",$4,$5,$6,"NaN",$7,$8,"NaN","NaN" ; \
				else if ($3~/[0-9]/&&$1=="0") print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,"NaN",($2/$6)*100 ; \
				else if ($3~/[0-9]/&&$1!="0"&&$8=="0") print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,"NaN",($2/$6)*100 ; \
				else print $1,$2,(($7+($5*2))/($8+($6*2)))*100,$3,$4,$5,$6,($5/$6),$7,$8,($7/$8),($2/$6)*100}' \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

##########################################################################################################################################################################
##### HYBRIDIZATION SELECTION REPORT #####################################################################################################################################
##########################################################################################################################################################################
##### THIS IS THE HEADER #################################################################################################################################################
##### "GENOME_SIZE","BAIT_TERRITORY","TARGET_TERRITORY","PCT_PF_UQ_READS_ALIGNED" ########################################################################################
##### "PF_UQ_GIGS_ALIGNED","PCT_SELECTED_BASES","ON_BAIT_VS_SELECTED","MEAN_TARGET_COVERAGE","MEDIAN_TARGET_COVERAGE","MAX_TARGET_COVERAGE" ##############################
##### "ZERO_CVG_TARGETS_PCT","PCT_EXC_MAPQ","PCT_EXC_BASEQ","PCT_EXC_OVERLAP","PCT_EXC_OFF_TARGET", "FOLD_80_BASE_PENALTY" ###############################################
##### "PCT_TARGET_BASES_1X","PCT_TARGET_BASES_2X","PCT_TARGET_BASES_10X","PCT_TARGET_BASES_20X","PCT_TARGET_BASES_30X","PCT_TARGET_BASES_40X","PCT_TARGET_BASES_50X" #####
##### "PCT_TARGET_BASES_100X","HS_LIBRARY_SIZE","AT_DROPOUT","GC_DROPOUT","THEORETICAL_HET_SENSITIVITY","HET_SNP_Q","BAIT_SET","PCT_USABLE_BASES_ON_BAIT"} ###############
##########################################################################################################################################################################

	# this will take when there are no reads in the file...but i don't think that it will handle when there are reads, but none fall on target
	# the next time i that happens i'll fix this to handle it.

		if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/HYB_SELECTION/${SM_TAG}"_hybridization_selection_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			awk 'BEGIN {FS="\t";OFS="\t"} \
				NR==8 \
				{if ($12=="?"&&$44=="") print $2,$3,$4,"NaN",($14/1000000000),"NaN","NaN",$23,$24,$25,$29,"NaN","NaN","NaN","NaN","NaN",\
				$36,$37,$38,$39,$40,$41,$42,$43,"NaN",$51,$52,$53,$54,$1,"NaN" ; \
				else if ($12!="?"&&$44=="") print $2,$3,$4,$12*100,($14/1000000000),$19*100,$21,$23,$24,$25,$29*100,$31*100,\
				$32*100,$33*100,$34*100,$35,$36*100,$37*100,$38*100,$39*100,$40*100,$41*100,$42*100,$43*100,"NaN",$51,$52,$53,$54,$1,$26*100 ; \
				else print $2,$3,$4,$12*100,($14/1000000000),$19*100,$21,$23,$24,$25,$29*100,$31*100,$32*100,$33*100,$34*100,$35,\
				$36*100,$37*100,$38*100,$39*100,$40*100,$41*100,$42*100,$43*100,$44,$51,$52,$53,$54,$1,$26*100}' \
			${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/HYB_SELECTION/${SM_TAG}"_hybridization_selection_metrics.txt" \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
		fi

	# this was supposed to be
	## if there are no reads, then print x
	## if there are no reads in the target area, the print y
	## else the data is fine and do as you intended.
	## however i no longer have anything to test this on...

		# awk 'BEGIN {FS="\t";OFS="\t"} \
		# NR==8 \
		# {if ($12=="?"&&$44=="") print $2,$3,$4,"NaN",($14/1000000000),"NaN","NaN",$22,$23,$24,$25,$29,"NaN","NaN","NaN","NaN",\
		# $36,$37,$38,$39,$40,$41,$42,$43,"NaN",$51,$52,$53,$54,$1,"NaN" ; \
		# else if ($12!="?") print $2,$3,$4,$12,($14/1000000000),$19,$21,$22,$23,$24,$25,$29,$31,$32,$33,$34,\
		# $36,$37,$38,$39,$40,$41,$42,$43,"NaN",$51,$52,$53,$54,$1,$26 ; \
		# else print $2,$3,$4,$12,($14/1000000000),$19,$21,$22,$23,$24,$25,$29,$31,$32,$33,$34,\
		# $36,$37,$38,$39,$40,$41,$42,$43,$44,$51,$52,$53,$54,$1,$26}' \
		# ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/HYB_SELECTION/${SM_TAG}"_hybridization_selection_metrics.txt" \
		# | singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
		# >> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

	########################################################################################################
	# grab out "MEAN_TARGET_COVERAGE","ZERO_CVG_TARGETS_PCT","PCT_TARGET_BASES_20X","PCT_TARGET_BASES_50X" #
	########################################################################################################

		if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/HYB_SELECTION/${SM_TAG}"_hybridization_selection_metrics.txt" ]]
				then
					echo -e SAMPLE,MEAN_TARGET_COVERAGE,ZERO_CVG_TARGETS_PCT,PCT_TARGET_BASES_20X,PCT_TARGET_BASES_50X\
					>| ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}".SUMMARY_COVERAGE.csv"

					echo -e ${SM_TAG},NaN,NaN,NaN,NaN \
					>> ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}".SUMMARY_COVERAGE.csv"

				else
					echo -e SAMPLE,MEAN_TARGET_COVERAGE,ZERO_CVG_TARGETS_PCT,PCT_TARGET_BASES_20X,PCT_TARGET_BASES_50X\
					>| ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}".SUMMARY_COVERAGE.csv"

					awk 'BEGIN {FS="\t";OFS=","} \
						NR==8 \
						{print "'${SM_TAG}'",$23,$29*100,$39*100,$42*100}' \
					${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/HYB_SELECTION/${SM_TAG}"_hybridization_selection_metrics.txt" \
					>> ${CORE_PATH}/${PROJECT}/${SM_TAG}/ANALYSIS/${SM_TAG}".SUMMARY_COVERAGE.csv"
				fi

##############################################
##### BAIT BIAS REPORT FOR Cref and Gref #####
##############################################
##### THIS IS THE HEADER #####################
##### Cref_Q,Gref_Q ##########################
##############################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}".bait_bias_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else
			grep -v "^#" ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}".bait_bias_summary_metrics.txt" \
				| sed '/^$/d' \
				| awk 'BEGIN {OFS="\t"} $12=="Cref"||$12=="Gref" {print $5}' \
				| paste - - \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash collapse 1 collapse 2 \
				| sed 's/,/;/g' \
				| awk 'BEGIN {OFS="\t"} {print $0}' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

############################################################
##### PRE-ADAPTER BIAS REPORT FOR Deamination and OxoG #####
############################################################
##### THIS IS THE HEADER ###################################
##### Deamination_Q,OxoG_Q #################################
############################################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/PRE_ADAPTER/SUMMARY/${SM_TAG}".pre_adapter_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else

			grep -v "^#" ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/PRE_ADAPTER/SUMMARY/${SM_TAG}".pre_adapter_summary_metrics.txt" \
				| sed '/^$/d' \
				| awk 'BEGIN {OFS="\t"} $12=="Deamination"||$12=="OxoG" {print $5}' \
				| paste - - \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash collapse 1 collapse 2 \
				| sed 's/,/;/g' \
				| awk 'BEGIN {OFS="\t"} {print $0}' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

###########################################################
##### BASE DISTRIBUTION REPORT AVERAGE FROM PER CYCLE #####
###########################################################
##### THIS IS THE HEADER ##################################
##### PCT_A,PCT_C,PCT_G,PCT_T,PCT_N #######################
###########################################################

	BASE_DISTIBUTION_BY_CYCLE_ROW_COUNT=(`wc -l ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}".base_distribution_by_cycle_metrics.txt"`)

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}".base_distribution_by_cycle_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		elif [[ -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}".base_distribution_by_cycle_metrics.txt" && $BASE_DISTIBUTION_BY_CYCLE_ROW_COUNT -lt 8 ]]
			then
				echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
		else
			sed '/^$/d' ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/METRICS/${SM_TAG}".base_distribution_by_cycle_metrics.txt" \
				| awk 'NR>6' \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash \
					mean 3 \
					mean 4 \
					mean 5 \
					mean 6 \
					mean 7 \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"
	fi

############################################
##### BASE SUBSTITUTION RATE ###############
############################################
##### THIS IS THE HEADER ###################
##### PCT_A_to_C,PCT_A_to_G,PCT_A_to_T #####
##### PCT_C_to_A,PCT_C_to_G,PCT_C_to_T #####
############################################

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ERROR_SUMMARY/${SM_TAG}".error_summary_metrics.txt" ]]
		then
			echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		else

			sed '/^$/d' ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/ERROR_SUMMARY/${SM_TAG}".error_summary_metrics.txt" \
				| awk 'NR>6 {print $6*100}' \
			>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

	fi

######################################################################################################
##### GRAB VCF METRICS FOR THE CFTR TARGET REGION ####################################################
######################################################################################################
##### THIS IS THE HEADER #############################################################################
##### TOTAL_SNPS,NUM_IN_DB_SNP,NOVEL_SNPS,FILTERED_SNPS,PCT_DBSNP,DBSNP_TITV,NOVEL_TITV ##############
##### TOTAL_INDELS,NOVEL_INDELS,FILTERED_INDELS,PCT_DBSNP_INDELS,NUM_IN_DB_SNP_INDELS ################
##### DBSNP_INS_DEL_RATIO,NOVEL_INS_DEL_RATIO,TOTAL_MULTIALLELIC_SNPS,NUM_IN_DB_SNP_MULTIALLELIC #####
##### TOTAL_COMPLEX_INDELS,NUM_IN_DB_SNP_COMPLEX_INDELS,SNP_REFERENCE_BIAS,NUM_SINGLETONS ############
######################################################################################################

	# since I don't have have any examples of what failures look like, I can't really build that in

	if [[ ! -f ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VCF_METRICS/${SM_TAG}".CFTR_REGION.variant_calling_detail_metrics.txt" ]]
			then
				echo -e NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN'\t'NaN \
				| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

			else

				awk 'BEGIN {FS="\t";OFS="\t"} NR==8 {print $2,$3,$4,$5,$6,$7,$8,$9,$10*100,$11,$12,$13,$14,$15,$16*100,$17,\
					$18,$19,$20,$21,$22,$23,$24,$25}' \
				${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/VCF_METRICS/${SM_TAG}".CFTR_REGION.variant_calling_detail_metrics.txt" \
					| singularity exec ${ALIGNMENT_CONTAINER} datamash transpose \
				>> ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}".QC_REPORT_TEMP.txt"

		fi

###################################################################################
##### see how many libraries are in the samples ###################################
##### should probably do this from the cram header, but meh, some other time. #####
##### this is to be tested against at the end. ####################################
##### taking this out for now #####################################################
###################################################################################

	# MULTIPLE_LIBRARY=`grep -v "^#" ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}".bait_bias_summary_metrics.txt" \
	# 	| sed '/^$/d' \
	# 	| awk 'BEGIN {OFS="\t"} $12=="Cref"||$12=="Gref" {print $5}' \
	# 	| paste - - \
	# 	| awk 'END {print NR}'`

	# 	# if exit does not equal 0 then exit with whatever the exit signal is at the end.

	# 		if [ "$MULTIPLE_LIBRARY" -ne 1 ]
	# 		 then
	# 			grep -v ^# ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/BAIT_BIAS/SUMMARY/${SM_TAG}".bait_bias_summary_metrics.txt" \
	# 				| sed '/^$/d' \
	# 				| awk 'NR>1 {print $1 "\t" $2}' \
	# 				| sort \
	# 				| uniq \
	# 				| singularity exec ${ALIGNMENT_CONTAINER} datamash -g 1 collapse 2 \
	# 			>> ${CORE_PATH}/${PROJECT}/TEMP/$SAMPLE_SHEET_NAME"_"$SUBMIT_STAMP"_MULTIPLE_LIBS.txt"
	# 		fi

	# tranpose from rows to list

		cat ${CORE_PATH}/${PROJECT}/TEMP/${SM_TAG}.QC_REPORT_TEMP.txt \
			| singularity exec ${ALIGNMENT_CONTAINER} datamash \
				transpose \
		>| ${CORE_PATH}/${PROJECT}/${SM_TAG}/REPORTS/QC_REPORT_PREP/${SM_TAG}.QC_REPORT_PREP.txt

	# check the exit signal at this point.

		SCRIPT_STATUS=$(echo $?)

	# -eq and -ne are used for integer comparisons
	# = and != are string comparisons

	# if exit does not equal 0 then exit with whatever the exit signal is at the end.
	# if the exit does equal zero then check to see if there is only one library, if so then exit 0
	# if exit is zero and there is multiple libraries then exit = 3. this will get pushed out to the sge accounting db so that 
		# there is an indication that there are multiple libraries, which could be due to a sample sheet screw-up.

			if [ "$SCRIPT_STATUS" -ne 0 ]
			 then
				exit $SCRIPT_STATUS
			# elif [ "$MULTIPLE_LIBRARY" -eq 1 ]
			#  then
			# 	exit 0
			else
				# exit 3
				exit 0
			fi

#!/usr/bin/env bash

# INPUT VARIABLES

	SAMPLE_SHEET=$1

	QUEUE_LIST=$2 # optional. the queues that you want to submit to.
		# if no 2nd argument present then the default is cgc.q

		if [[ ! $QUEUE_LIST ]]
			then
			QUEUE_LIST="cgc.q"
		fi

	THREADS=$3 # optional. how many cpu processors you want to use for programs that are multi-threaded
		# if no 3rd argument present then the default is 6
		# if you want to set this then you need to set the 2nd argument as well (even to the default)

		if [[ ! $THREADS ]]
			then
			THREADS="6"
		fi

	PRIORITY=$4 # optional. how high you want the tasks to have when submitting.
		# if no 4th argument present then the default is -15.
		# if you want to set this then you need to set the 3rd argument as well (even to the default)

			if [[ ! $PRIORITY ]]
				then
				PRIORITY="-15"
			fi

# CHANGE SCRIPT DIR TO WHERE YOU HAVE HAVE THE SCRIPTS BEING SUBMITTED

	SUBMITTER_SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

	SCRIPT_DIR="$SUBMITTER_SCRIPT_PATH/scripts"

##################
# CORE VARIABLES #
##################

	# GVCF PAD. CURRENTLY KEEPING THIS AS A STATIC VARIABLE

		GVCF_PAD="250"

	## This will always put the current working directory in front of any directory for PATH
	## added /bin for RHEL6

		export PATH=".:$PATH:/bin"

	# where the input/output sequencing data will be located.

		CORE_PATH="/mnt/clinical/ddl/NGS/Panel_Data"

	# Directory where NovaSeqa runs are located.

		NOVASEQ_REPO="/mnt/instrument_files/novaseq"

	# used for tracking in the read group header of the cram file

		PIPELINE_VERSION=`git --git-dir=$SCRIPT_DIR/../.git --work-tree=$SCRIPT_DIR/.. log --pretty=format:'%h' -n 1`

	# load gcc for programs like verifyBamID
	## this will get pushed out to all of the compute nodes since I specify env var to pushed out with qsub

		module load gcc/7.2.0

	# explicitly setting this b/c not everybody has had the $HOME directory transferred and I'm not going to through
	# and figure out who does and does not have this set correctly

		umask 0007

	# SUBMIT TIMESTAMP

		SUBMIT_STAMP=`date '+%s'`

	# SUBMITTER_ID

		SUBMITTER_ID=`whoami`

	# bind the host file system /mnt to the singularity container. in case I use it in the submitter.

		export SINGULARITY_BINDPATH="/mnt:/mnt"

	# QSUB ARGUMENTS LIST
		# set shell on compute node
		# start in current working directory
		# transfer submit node env to compute node
		# set SINGULARITY BINDPATH
		# set queues to submit to
		# set priority
		# combine stdout and stderr logging to same output file

			QSUB_ARGS="-S /bin/bash" \
				QSUB_ARGS=$QSUB_ARGS" -cwd" \
				QSUB_ARGS=$QSUB_ARGS" -V" \
				QSUB_ARGS=$QSUB_ARGS" -v SINGULARITY_BINDPATH=/mnt:/mnt" \
				QSUB_ARGS=$QSUB_ARGS" -p $PRIORITY" \
				QSUB_ARGS=$QSUB_ARGS" -j y"

		# $QSUB_ARGS WILL BE A GENERAL BLOCK APPLIED TO ALL JOBS
		# BELOW ARE TIMES WHEN WHEN A QSUB ARGUMENT IS ADDED OR CHANGED.

			# DEFINE STANDARD LIST OF SERVERS TO SUBMIT TO.
			# THIS IS DEFINED AS AN INPUT ARGUMENT VARIABLE TO THE PIPELINE (DEFAULT: cgc.q)

				STANDARD_QUEUE_QSUB_ARG=" -q $QUEUE_LIST"

			# SPLICEAI WILL NOT RUN ON SERVERS THAT DO NOT HAVE INTEL AVX CHIPSETS.
			# which for us is the c6100s (prod.q and rnd.q).
			# so I am removing those from $QUEUE_LIST if present and create a new variable to run spliceai

				SPLICEAI_QUEUE_QSUB_ARG=$(echo " -q $QUEUE_LIST" | sed 's/rnd.q//g' | sed 's/prod.q//g')

			# REQUESTING AN ENTIRE SERVER (specifically for cgc.q)

				REQUEST_ENTIRE_SERVER_QSUB_ARG=" -pe slots 5"

			# When you install the API modules for VEP in a non-default location (which is $HOME),
			# you have to set the $PERL5LIB variable to the new location.

				VEP_PERL5LIB_QSUB_ARG="-v PERL5LIB=/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/vep_data"

			# the default when running the vep INSTALL.pl script installs htslib.
			# so you are supposed to add that to the path variable.

				VEP_HTSLIB_QSUB_ARG="-v PATH=$PATH:/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/vep_data"

#####################
# PIPELINE PROGRAMS #
#####################

	ALIGNMENT_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/ddl_ce_control_align-0.0.4.simg"
		# contains the following software and is on Ubuntu 16.04.5 LTS
			# gatk 4.0.11.0 (base image). also contains the following.
				# Python 3.6.2 :: Continuum Analytics, Inc.
					# samtools 0.1.19
					# bcftools 0.1.19
					# bedtools v2.25.0
					# bgzip 1.2.1
					# tabix 1.2.1
					# samtools, bcftools, bgzip and tabix will be replaced with newer versions.
					# R 3.2.5
						# dependencies = c("gplots","digest", "gtable", "MASS", "plyr", "reshape2", "scales", "tibble", "lazyeval")    # for ggplot2
						# getopt_1.20.0.tar.gz
						# optparse_1.3.2.tar.gz
						# data.table_1.10.4-2.tar.gz
						# gsalib_2.1.tar.gz
						# ggplot2_2.2.1.tar.gz
					# openjdk version "1.8.0_181"
					# /gatk/gatk.jar -> /gatk/gatk-package-4.0.11.0-local.jar
			# added
				# picard.jar 2.17.0 (as /gatk/picard.jar)
				# samblaster-v.0.1.24
				# sambamba-0.6.8
				# bwa-0.7.15
				# datamash-1.6
				# verifyBamID v1.1.3
				# samtools 1.10
				# bgzip 1.10
				# tabix 1.10
				# bcftools 1.10.2
				# parallel 20161222

	GATK_3_7_0_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/gatk3-3.7-0.simg"
		# singularity pull docker://broadinstitute/gatk3:3.7-0
			# used for generating the depth of coverage reports.
				# comes with R 3.1.1 with appropriate packages needed to create gatk pdf output
				# also comes with some version of java 1.8
				# jar file is /usr/GenomeAnalysisTK.jar

	GATK_3_5_0_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/gatk3-3.5-0.simg"
		# singularity pull docker://broadinstitute/gatk3:3.7-0

	MANTA_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/manta-1.6.0.0.simg"
		# singularity 2 creates a simg file (this is what I used)
		# singularity 3 (this is what the cgc nodes have) creates a .sif file

	SPLICEAI_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/spliceai-1.3.1.1.simg"
		# singularity pull docker://ubuntudocker.jhgenomics.jhu.edu:443/illumina/spliceai:1.3.1.1
			# has to run an servers where the CPU supports AVX
			# the only ones that don't are the c6100s (prod.q,rnd.q,c6100-4,c6100-8)

	VEP_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/vep-102.0.simg"

	CRYPTSPLICE_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/cryptsplice-1.simg"

	VT_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/vt-0.5772.ca352e2c.0.simg"

	ANNOVAR_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/annovarwrangler-dev.simg"

	COMBINE_ANNOVAR_WITH_SPLICING_R_CONTAINER="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/containers/r-cftr-3.4.4.1.simg"

	COMBINE_ANNOVAR_WITH_SPLICING_R_SCRIPT="$SCRIPT_DIR/CombineCryptSpliceandSpliceandmergeAnnovar_andmergeCFTR2.R"

##################
# PIPELINE FILES #
##################

	GENE_LIST="/mnt/clinical/ddl/NGS/Exome_Resources/PIPELINE_FILES/RefSeqGene.GRCh37.rCRS.MT.bed"
		# md5 dec069c279625cfb110c2e4c5480e036
	VERIFY_VCF="/mnt/clinical/ddl/NGS/Exome_Resources/PIPELINE_FILES/Omni25_genotypes_1525_samples_v2.b37.PASS.ALL.sites.vcf"
	PHASE3_1KG_AUTOSOMES="/mnt/clinical/ddl/NGS/Exome_Resources/PIPELINE_FILES/ALL.autosomes.phase3_shapeit2_mvncall_integrated_v5.20130502.sites.vcf.gz"
	CFTR_BED="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/bed_files/CFTR_ANNOTATED.bed"
	BARCODE_SNPS="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/bed_files/CFTRFullGene_BarcodeSNPs.bed"
	MANTA_CFTR_BED="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/bed_files/twistCFTRpanelregion_grch37.bed.gz"
	MANTA_CONFIG="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/configManta_CFTR.py.ini"
	VEP_REF_CACHE="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/vep_data"
	CRYPTSPLICE_DATA="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/cryptsplice_data"
	CFTR_EXONS="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/bed_files/CFTR_EXONS.bed"
	CFTR_FOCUSED="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/bed_files/CF_CFTR.NGS1.v1.140604.bed"

	# HGVS CDNA SUBMITTED TO VEP
		CFTR2_VCF="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/CFTR2/CFTR2_31July2020_plusDDL_210107mbs_MOD.vep.DaN.vcf.gz"

		CFTR2_VEP_TABLE="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/CFTR2/CFTR2_31July2020_plusDDL_210107mbs_MOD.vep.CFTR_ONLY.sort.no_header.txt"

	# EXCEL FILE CONVERTED TO TAB DELIMITED TEXT WITH THE HEADER REMOVE AND SORTED BY HGVS CDNA
		CFTR2_RAW_TABLE="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/CFTR2/CFTR2_31July2020_plusDDL_210107mbs_MOD.sorted_cdna.no_header.txt"

	# ANNOVAR PARAMETERS AND INPUTS
		ANNOVAR_DATABASE_FILE="/mnt/clinical/ddl/NGS/CFTR_Full_Gene_Sequencing_Pipeline/resources/CFTR.final.csv"
		ANNOVAR_REF_BUILD="hg19"

		ANNOVAR_INFO_FIELD_KEYS="VariantType," \
			ANNOVAR_INFO_FIELD_KEYS=$ANNOVAR_INFO_FIELD_KEYS"DP" \

		ANNOVAR_HEADER_MAPPINGS="af=gnomad211_exome_AF," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_popmax=gnomad211_exome_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_male=gnomad211_exome_AF_male," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_female=gnomad211_exome_AF_female," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_raw=gnomad211_exome_AF_raw," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_afr=gnomad211_exome_AF_afr," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_sas=gnomad211_exome_AF_sas," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_amr=gnomad211_exome_AF_amr," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_eas=gnomad211_exome_AF_eas," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_nfe=gnomad211_exome_AF_nfe," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_fin=gnomad211_exome_AF_fin," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_asj=gnomad211_exome_AF_asj," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"af_oth=gnomad211_exome_AF_oth," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_topmed_af_popmax=gnomad211_exome_non_topmed_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_neuro_af_popmax=gnomad211_exome_non_neuro_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_cancer_af_popmax=gnomad211_exome_non_cancer_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"controls_af_popmax=gnomad211_exome_controls_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF=gnomad211_genome_AF," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_popmax=gnomad211_genome_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_male=gnomad211_genome_AF_male," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_female=gnomad211_genome_AF_female," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_raw=gnomad211_genome_AF_raw," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_afr=gnomad211_genome_AF_afr," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_sas=gnomad211_genome_AF_sas," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_amr=gnomad211_genome_AF_amr," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_eas=gnomad211_genome_AF_eas," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_nfe=gnomad211_genome_AF_nfe," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_fin=gnomad211_genome_AF_fin," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_asj=gnomad211_genome_AF_asj," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"AF_oth=gnomad211_genome_AF_oth," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_topmed_AF_popmax=gnomad211_genome_non_topmed_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_neuro_AF_popmax=gnomad211_genome_non_neuro_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"non_cancer_AF_popmax=gnomad211_genome_non_cancer_AF_popmax," \
			ANNOVAR_HEADER_MAPPINGS=$ANNOVAR_HEADER_MAPPINGS"controls_AF_popmax=gnomad211_genome_controls_AF_popmax"

			ANNOVAR_VCF_COLUMNS="CHROM,"
				ANNOVAR_VCF_COLUMNS=$ANNOVAR_VCF_COLUMNS"POS,"
				ANNOVAR_VCF_COLUMNS=$ANNOVAR_VCF_COLUMNS"REF,"
				ANNOVAR_VCF_COLUMNS=$ANNOVAR_VCF_COLUMNS"ALT"

#################################
##### MAKE A DIRECTORY TREE #####
#################################

	###############################################################################################
	# CREATE AN ARRAY FOR EACH SAMPLE IN SAMPLE SHEET FOR INPUT THAT WILL BE USED IN THE PIPELINE #
	# NAME ARRAY ELEMENTS AS VARIABLES ############################################################
	###############################################################################################

		CREATE_SAMPLE_ARRAY ()
		{
			SAMPLE_ARRAY=(`awk 1 $SAMPLE_SHEET \
				| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
				| awk 'BEGIN {FS=","; OFS="\t"} $8=="'$SAMPLE'" \
				{split($19,INDEL,";"); \
				print $1,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2],$20}' \
					| sort \
					| uniq`)

			#  1  Project=the Seq Proj folder name

				PROJECT=${SAMPLE_ARRAY[0]}

			################################################################################
			# 2 SKIP : FCID=flowcell that sample read group was performed on ###############
			# 3 SKIP : Lane=lane of flowcell that sample read group was performed on] ######
			# 4 SKIP : Index=sample barcode ################################################
			# 5 SKIP : Platform=type of sequencing chemistry matching SAM specification ####
			# 6 SKIP : Library_Name=library group of the sample read group #################
			# 7 SKIP : Date=should be the run set up date to match the seq run folder name #
			################################################################################

			#  8  SM_Tag=sample ID

				SM_TAG=${SAMPLE_ARRAY[1]}
					SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks

			#  9  Center=the center/funding mechanism

				CENTER=${SAMPLE_ARRAY[2]}

			# 10  Description=Generally we use to denote the sequencer setting (e.g. rapid run)
			# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.

				SEQUENCER_MODEL=${SAMPLE_ARRAY[3]}

			#########################
			# 11  SKIP : Seq_Exp_ID #
			#########################

			# 12  Genome_Ref=the reference genome used in the analysis pipeline

				REF_GENOME=${SAMPLE_ARRAY[4]}
					REF_DICT=$(echo $REF_GENOME | sed 's/fasta$/dict/g; s/fa$/dict/g')

			#####################################
			# 13  Operator: SKIP ################
			# 14  Extra_VCF_Filter_Params: SKIP #
			#####################################

			# 15  TS_TV_BED_File=where ucsc coding exons overlap with bait and target bed files

				TITV_BED=${SAMPLE_ARRAY[5]}

			# 16  Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
			# Used for limited where to run base quality score recalibration on where to create gvcf files.

				BAIT_BED=${SAMPLE_ARRAY[6]}

			# 17  Targets_BED_File=bed file acquired from manufacturer of their targets.

				TARGET_BED=${SAMPLE_ARRAY[7]}

			# 18  KNOWN_SITES_VCF=used to annotate ID field in VCF file. masking in base call quality score recalibration.

				DBSNP=${SAMPLE_ARRAY[8]}

			# 19  KNOWN_INDEL_FILES=used for BQSR masking, sensitivity in local realignment.

				KNOWN_INDEL_1=${SAMPLE_ARRAY[9]}
				KNOWN_INDEL_2=${SAMPLE_ARRAY[10]}

			# EXPECTED SEX

				EXPECTED_SEX=${SAMPLE_ARRAY[11]}
		}

	##################################
	# PROJECT DIRECTORY TREE CREATOR #
	##################################

		MAKE_PROJ_DIR_TREE ()
		{
			mkdir -p $CORE_PATH/$PROJECT/$SM_TAG/{CRAM,HC_CRAM,VCF,GVCF,ANALYSIS,MANTA,CRYPTSPLICE,SPLICEAI,VEP,CFTR2,ANNOVAR} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/{ALIGNMENT_SUMMARY,ANNOVAR,PICARD_DUPLICATES,VERIFYBAMID,RG_HEADER,QUALITY_YIELD,ERROR_SUMMARY,VCF_METRICS,QC_REPORT_PREP} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/BAIT_BIAS/{METRICS,SUMMARY} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/PRE_ADAPTER/{METRICS,SUMMARY} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/BASECALL_Q_SCORE_DISTRIBUTION/{METRICS,PDF} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/BASE_DISTRIBUTION_BY_CYCLE/{METRICS,PDF} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/COUNT_COVARIATES/{GATK_REPORT,PDF} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/GC_BIAS/{METRICS,PDF,SUMMARY} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/DEPTH_OF_COVERAGE/CFTR \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/HYB_SELECTION/PER_TARGET_COVERAGE \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/INSERT_SIZE/{METRICS,PDF} \
			$CORE_PATH/$PROJECT/$SM_TAG/REPORTS/MEAN_QUALITY_BY_CYCLE/{METRICS,PDF} \
			$CORE_PATH/$PROJECT/TEMP/$SM_TAG_ANNOVAR \
			$CORE_PATH/$PROJECT/{TEMP,FASTQ,COMMAND_LINES,REPORTS} \
			$CORE_PATH/$PROJECT/LOGS/$SM_TAG
		}

	###################################################
	# create function to combine project set up steps #
	###################################################

		SETUP_PROJECT ()
		{
			CREATE_SAMPLE_ARRAY
			MAKE_PROJ_DIR_TREE
			echo Project started at `date` >| $CORE_PATH/$PROJECT/PROJECT_START_END_TIMESTAMP.txt
		}

#####################
# do project set up #
#####################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","} NR>1 {print $8}' \
		| sort \
		| uniq );
	do
		SETUP_PROJECT
done

################################
##### CRAM FILE GENERATION #####
###############################################################################################
##### NOTE: THE CRAM FILE IS THE END PRODUCT BUT THE BAM FILE IS USED FOR OTHER PROCESSES #####
##### SOME PROGRAMS CAN'T TAKE IN CRAM AS AN INPUT ############################################
###############################################################################################

	########################################################################################
	# create an array at the platform level so that bwa mem can add metadata to the header #
	########################################################################################

		CREATE_PLATFORM_UNIT_ARRAY ()
		{
			PLATFORM_UNIT_ARRAY=(`awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d' \
			| awk 'BEGIN {FS=","} $8$2$3$4=="'$PLATFORM_UNIT'" {split($19,INDEL,";"); print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$12,$15,$16,$17,$18,INDEL[1],INDEL[2],$$20,$21,$22,$23,$24}' \
			| sort \
			| uniq`)

				#  1  Project=the Seq Proj folder name

					PROJECT=${PLATFORM_UNIT_ARRAY[0]}

				#  2  FCID=flowcell that sample read group was performed on

					FCID=${PLATFORM_UNIT_ARRAY[1]}

				#  3  Lane=lane of flowcell that sample read group was performed on

					LANE=${PLATFORM_UNIT_ARRAY[2]}

				#  4  Index=sample barcode

					INDEX=${PLATFORM_UNIT_ARRAY[3]}

				#  5  Platform=type of sequencing chemistry matching SAM specification

					PLATFORM=${PLATFORM_UNIT_ARRAY[4]}

				#  6  Library_Name=library group of the sample read group,
					# Used during Marking Duplicates to determine if molecules are to be considered as part of the same library or not

					LIBRARY=${PLATFORM_UNIT_ARRAY[5]}

				#  7  Date=should be the run set up date, but doesn't have to be

					RUN_DATE=${PLATFORM_UNIT_ARRAY[6]}

				#  8  SM_Tag=sample ID

					SM_TAG=${PLATFORM_UNIT_ARRAY[7]}

						# sge sm tag. If there is an @ in the qsub or holdId name it breaks

							SGE_SM_TAG=$(echo $SM_TAG | sed 's/@/_/g')

				#  9  Center=the center/funding mechanism

					CENTER=${PLATFORM_UNIT_ARRAY[8]}

				# 10  Description=Generally we use to denote the sequencer setting (e.g. rapid run)
				# “HiSeq-X”, “HiSeq-4000”, “HiSeq-2500”, “HiSeq-2000”, “NextSeq-500”, or “MiSeq”.

					SEQUENCER_MODEL=${PLATFORM_UNIT_ARRAY[9]}

				########################
				# 11  Seq_Exp_ID: SKIP #
				########################

				# 12  Genome_Ref=the reference genome used in the analysis pipeline

					REF_GENOME=${PLATFORM_UNIT_ARRAY[10]}

				#####################################
				# 13  Operator: SKIP ################
				# 14  Extra_VCF_Filter_Params: SKIP #
				#####################################

				# 15  TS_TV_BED_File=refseq (select) cds plus other odds and ends (.e.g. missing omim))

					TITV_BED=${PLATFORM_UNIT_ARRAY[11]}

				# 16  Baits_BED_File=a super bed file incorporating bait, target, padding and overlap with ucsc coding exons.
				# Used for limited where to run base quality score recalibration on where to create gvcf files.

					BAIT_BED=${PLATFORM_UNIT_ARRAY[12]}

				# 17  Targets_BED_File=bed file acquired from manufacturer of their targets.

					TARGET_BED=${PLATFORM_UNIT_ARRAY[13]}

				# 18  KNOWN_SITES_VCF=used to annotate ID field in VCF file. masking in base call quality score recalibration.

					DBSNP=${PLATFORM_UNIT_ARRAY[14]}

				# 19  KNOWN_INDEL_FILES=used for BQSR masking

					KNOWN_INDEL_1=${PLATFORM_UNIT_ARRAY[15]}
					KNOWN_INDEL_2=${PLATFORM_UNIT_ARRAY[16]}
		}

	########################################################################
	### Use bwa mem to do the alignments; ##################################
	### pipe to samblaster to add mate tags; ###############################
	### pipe to picard's AddOrReplaceReadGroups to handle the bam header ###
	########################################################################

		RUN_BWA ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N A.01-BWA"_"$SGE_SM_TAG"_"$FCID"_"$LANE"_"$INDEX \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"_"$FCID"_"$LANE"_"$INDEX"-BWA.log" \
			$SCRIPT_DIR/A.01_BWA.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$FCID \
				$LANE \
				$INDEX \
				$PLATFORM \
				$LIBRARY \
				$RUN_DATE \
				$SM_TAG \
				$CENTER \
				$SEQUENCER_MODEL \
				$REF_GENOME \
				$PIPELINE_VERSION \
				$BAIT_BED \
				$TARGET_BED \
				$TITV_BED \
				$NOVASEQ_REPO \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###########
	# run bwa #
	###########

	for PLATFORM_UNIT in $(awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} NR>1 {print $8$2$3$4}' \
			| sort \
			| uniq );
		do
			CREATE_PLATFORM_UNIT_ARRAY
			RUN_BWA
			echo sleep 0.1s
	done

	#########################################################################################
	# Merge files and mark duplicates using picard duplictes with queryname sorting #########
	# do coordinate sorting with sambamba ###################################################
	#########################################################################################
	# I am setting the heap space and garbage collector threads for picard now now ##########
	# doing this does drastically decrease the load average ( the gc thread specification ) #
	#########################################################################################
	# create a hold job id qsub command line based on the number of #########################
	# submit merging the bam files created by bwa mem above #################################
	# only launch when every lane for a sample is done being processed by bwa mem ###########
	# I want to clean this up eventually and get away from using awk to print the qsub line #
	#########################################################################################

		# 1. PROJECT
		# 2. SM_TAG
		# 3. FCID_LANE_INDEX
		# 4. FCID_LANE_INDEX.bam
		# 5. SM_TAG
		# 6. DESCRIPTION (INSTRUMENT MODEL)

		awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","; OFS="\t"} NR>1 {print $1,$8,$2"_"$3"_"$4,$2"_"$3"_"$4".bam",$8,$10}' \
			| awk 'BEGIN {OFS="\t"} {sub(/@/,"_",$5)} {print $1,$2,$3,$4,$5,$6}' \
			| sort -k 1,1 -k 2,2 -k 3,3 -k 6,6 \
			| uniq \
			| singularity exec $ALIGNMENT_CONTAINER datamash \
				-s \
				-g 1,2 \
				collapse 3 \
				collapse 4 \
				unique 5 \
				unique 6 \
			| awk 'BEGIN {FS="\t"} \
				gsub(/,/,",A.01-BWA_"$5"_",$3) \
				gsub(/,/,",INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/",$4) \
				{print "qsub",\
				"-S /bin/bash",\
				"-cwd",\
				"-V",\
				"-v SINGULARITY_BINDPATH=/mnt:/mnt",\
				"-q","'$QUEUE_LIST'",\
				"-p","'$PRIORITY'",\
				"-j y",\
				"-N","B.01-MARK_DUPLICATES_"$5"_"$1,\
				"-o","'$CORE_PATH'/"$1"/LOGS/"$2"/"$2"-MARK_DUPLICATES.log",\
				"-hold_jid","A.01-BWA_"$5"_"$3, \
				"'$SCRIPT_DIR'""/B.01_MARK_DUPLICATES.sh",\
				"'$ALIGNMENT_CONTAINER'",\
				"'$CORE_PATH'",\
				$1,\
				$2,\
				$6,\
				"'$THREADS'",\
				"'$SAMPLE_SHEET'",\
				"'$SUBMIT_STAMP'",\
				"INPUT=" "'$CORE_PATH'" "/" $1"/TEMP/"$4"\n""sleep 0.1s"}'

	###########################################################################################
	# fix common formatting problems in bed files #############################################
	# pad the target region with gvcf pad and add to titv (barcode regions) for gvcf bed file #
	# create picard style interval files ######################################################
	###########################################################################################

		FIX_BED_FILES ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-FIX_BED_FILES.log" \
			-hold_jid B.01-MARK_DUPLICATES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/C.01_FIX_BED.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$TARGET_BED \
				$BAIT_BED \
				$TITV_BED \
				$REF_GENOME \
				$GVCF_PAD \
				$CFTR2_VCF
		}

	#######################################
	# run bqsr on the using bait bed file #
	#######################################

		PERFORM_BQSR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N D.01-PERFORM_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-PERFORM_BQSR.log" \
			-hold_jid B.01-MARK_DUPLICATES"_"$SGE_SM_TAG"_"$PROJECT,C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/D.01_PERFORM_BQSR.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$KNOWN_INDEL_1 \
				$KNOWN_INDEL_2 \
				$DBSNP \
				$BAIT_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##############################
	# use a 4 bin q score scheme #
	# remove indel Q scores ######
	# retain original Q score  ###
	##############################

		APPLY_BQSR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-APPLY_BQSR.log" \
			-hold_jid D.01-PERFORM_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/E.01_APPLY_BQSR.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#####################################################
	# create a lossless cram, although the bam is lossy #
	#####################################################

		BAM_TO_CRAM ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N F.01-BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-BAM_TO_CRAM.log" \
			-hold_jid E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/F.01_BAM_TO_CRAM.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##########################################################################################
	# index the cram file and copy it so that there are both *crai and cram.crai *extensions #
	##########################################################################################

		INDEX_CRAM ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-INDEX_CRAM.log" \
			-hold_jid F.01-BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/G.01_INDEX_CRAM.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

##############################################
# run alignment steps after bwa to cram file #
##############################################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","} NR>1 {print $8}' \
		| sort \
		| uniq );
	do
		CREATE_SAMPLE_ARRAY
		FIX_BED_FILES
		echo sleep 0.1s
		PERFORM_BQSR
		echo sleep 0.1s
		APPLY_BQSR
		echo sleep 0.1s
		BAM_TO_CRAM
		echo sleep 0.1s
		INDEX_CRAM
		echo sleep 0.1s
done

########################################################################################
##### BAM/CRAM FILE RELATED METRICS ####################################################
##### NOTE: SOME PROGRAMS CAN ONLY BE RAN ON THE BAM FILE AND NOT ON THE CRAM FILE #####
##### I WILL COMMENT ON WHICH IS WHICH #################################################
########################################################################################

	###########################################################
	# COLLECT MULTIPLE METRICS  ###############################
	# USE THE TARGET BED FILE WHICH IS THE CFTR TARGET REGION #
	# uses the CRAM file as the input #########################
	###########################################################

		COLLECT_MULTIPLE_METRICS ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.01-COLLECT_MULTIPLE_METRICS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COLLECT_MULTIPLE_METRICS.log" \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT,C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.01_COLLECT_MULTIPLE_METRICS.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$DBSNP \
				$TARGET_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###########################################
	# COLLECT HS METRICS  #####################
	# bait bed is the bait bed file ###########
	# target bed files is the target bed file #
	# uses the CRAM file as the input #########
	###########################################

		COLLECT_HS_METRICS ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.02-COLLECT_HS_METRICS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COLLECT_HS_METRICS.log" \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT,C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.02_COLLECT_HS_METRICS.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$BAIT_BED \
				$TARGET_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	######################################
	# CREATE VCF FOR VERIFYBAMID METRICS #
	# USE THE BAIT BED FILE ##############
	######################################

		SELECT_VERIFYBAMID_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.03-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-SELECT_VERIFYBAMID_VCF.log" \
			-hold_jid C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT,E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.03_SELECT_VERIFYBAMID_VCF.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$VERIFY_VCF \
				$BAIT_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###############################
	# RUN VERIFYBAMID #############
	# THIS RUNS OFF OF A BAM FILE #
	###############################

		RUN_VERIFYBAMID ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.03-A.01-RUN_VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VERIFYBAMID.log" \
			-hold_jid H.03-SELECT_VERIFYBAMID_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.03-A.01_VERIFYBAMID.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#####################################################################################
	# CREATE DEPTH OF COVERAGE for CFTR TARGET REGION ###################################
	# bed file is CFTR TARGET REGION THAT IS ANNOTATED WITH INTRON, UPSTREAM, EXON, ETC #
	# so it is NOT using the sample sheet target bed file as an input ###################
	# BUT THE ANNOTATED BED FILE IS BASED ON THE TARGET BED FILE IN THE SAMPLE SHEET ####
	# uses a gatk 3.7 container #########################################################
	# input is the BAM file #############################################################
	#####################################################################################

		DOC_CFTR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-DOC_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-DOC_CFTR.log" \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT,C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04_DOC_CFTR.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$CFTR_BED \
				$GENE_LIST \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#################################################################################################
	# FORMATTING PER BASE COVERAGE FOR CFTR AND ADDING GENE NAME, TRANSCRIPT, EXON, ETC ANNNOTATION #
	#################################################################################################

		ANNOTATE_PER_BASE_REPORT_CFTR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-A.01_ANNOTATE_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-ANNOTATE_PER_BASE_CFTR.log" \
			-hold_jid C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT,H.04-DOC_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04-A.01_ANNOTATE_PER_BASE_CFTR.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$CFTR_BED
		}

	##########################################################################
	# FILTER PER BASE COVERAGE WITH GENE NAME ANNNOTATION WITH LESS THAN 50x #
	##########################################################################

		FILTER_ANNOTATED_PER_BASE_REPORT_CFTR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-A.01-A.01_FILTER_ANNOTATED_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-FILTER_ANNOTATED_PER_BASE_CFTR.log" \
			-hold_jid H.04-A.01_ANNOTATE_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04-A.01-A.01_FILTER_ANNOTATED_PER_BASE_CFTR.sh \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG
		}

	######################################################
	# BGZIP PER BASE COVERAGE WITH GENE NAME ANNNOTATION #
	######################################################

		BGZIP_ANNOTATED_PER_BASE_REPORT_CFTR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-A.01-A.02_BGZIP_ANNOTATED_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-BGZIP_ANNOTATED_PER_BASE_CFTR.log" \
			-hold_jid H.04-A.01_ANNOTATE_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04-A.01-A.02_BGZIP_ANNOTATED_PER_BASE_CFTR.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	######################################################
	# TABIX PER BASE COVERAGE WITH GENE NAME ANNNOTATION #
	######################################################

		TABIX_ANNOTATED_PER_BASE_REPORT_CFTR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-A.01-A.02-A.01_TABIX_ANNOTATED_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-TABIX_ANNOTATED_PER_BASE_CFTR.log" \
			-hold_jid H.04-A.01-A.02_BGZIP_ANNOTATED_PER_BASE_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04-A.01-A.02-A.01_TABIX_ANNOTATED_PER_BASE_CFTR.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###################################################################################################
	# FORMATTING PER CODING INTERVAL COVERAGE AND ADDING GENE NAME, TRANSCRIPT, EXON, ETC ANNNOTATION #
	###################################################################################################

		ANNOTATE_PER_CFTR_FEATURE ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.04-A.02_ANNOTATE_PER_CFTR_FEATURE"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-ANNOTATE_PER_CFTR_FEATURE.log" \
			-hold_jid H.04-DOC_CFTR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.04-A.02_ANNOTATE_PER_CFTR_FEATURE.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$CFTR_BED
		}

	####################################################################
	# HAPLOTYPE CALLER #################################################
	####################################################################
	# INPUT IS THE BAM FILE ############################################
	# A 250 BP PAD IS ADDED IN FIX BED FILES TO THE CFTR TARGET REGION #
	####################################################################

		CALL_HAPLOTYPE_CALLER ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.05-HAPLOTYPE_CALLER"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HAPLOTYPE_CALLER.log" \
			-hold_jid C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT,E.01-APPLY_BQSR"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.05_HAPLOTYPE_CALLER.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$BAIT_BED \
				$GVCF_PAD \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	########################################################
	# create a lossless HC cram, although the bam is lossy #
	########################################################

		HC_BAM_TO_CRAM ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.05-A.01_HAPLOTYPE_CALLER_BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HC_BAM_TO_CRAM.log" \
			-hold_jid H.05-HAPLOTYPE_CALLER"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.05-A.01_HAPLOTYPE_CALLER_BAM_TO_CRAM.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##########################################################################################
	# index the cram file and copy it so that there are both *crai and cram.crai *extensions #
	##########################################################################################

		INDEX_HC_CRAM ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.05-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-HC_INDEX_CRAM.log" \
			-hold_jid H.05-A.01_HAPLOTYPE_CALLER_BAM_TO_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.05-A.01-A.01_INDEX_HAPLOTYPE_CALLER_CRAM.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###################################
	# Run GenotypeGVCF on each sample #
	###################################

		GENOTYPE_GVCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N I.01_GENOTYPE_GVCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-GENOTYPE_GVCF.log" \
			-hold_jid H.05-HAPLOTYPE_CALLER"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/I.01_GENOTYPE_GVCF.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$DBSNP \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	################################################################
	# Run VariantAnnotator on each sample to add extra annotations #
	################################################################

		ANNOTATE_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N J.01_ANNOTATE_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-ANNOTATE_VCF.log" \
			-hold_jid I.01_GENOTYPE_GVCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/J.01_VARIANT_ANNOTATOR.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$PHASE3_1KG_AUTOSOMES \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#############################################################
	# Extract SNVs and REF for each sample to add filters later #
	#############################################################

		EXTRACT_SNV_AND_REF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N K.01_EXTRACT_SNV_AND_REF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_SNV_AND_REF.log" \
			-hold_jid J.01_ANNOTATE_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/K.01_EXTRACT_SNV_AND_REF.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#######################################
	# FILTER SNVs and REF for each sample #
	#######################################

		FILTER_SNV_AND_REF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N K.01-A.01_FILTER_SNV_AND_REF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-FILTER_SNV_AND_REF.log" \
			-hold_jid K.01_EXTRACT_SNV_AND_REF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/K.01-A.01_FILTER_SNV_AND_REF.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##########################################################################
	# Extract INDELS and MIXED variants for each sample to add filters later #
	##########################################################################

		EXTRACT_INDEL_AND_MIXED ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N K.02_EXTRACT_INDEL_AND_MIXED"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_INDEL_AND_MIXED.log" \
			-hold_jid J.01_ANNOTATE_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/K.02_EXTRACT_INDEL_AND_MIXED.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#####################################################
	# FILTER INDELS and MIXED VARIANATS for each sample #
	#####################################################

		FILTER_INDEL_AND_MIXED ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N K.02-A.01_FILTER_INDEL_AND_MIXED"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-FILTER_INDEL_AND_MIXED.log" \
			-hold_jid K.02_EXTRACT_INDEL_AND_MIXED"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/K.02-A.01_FILTER_INDEL_AND_MIXED.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###############################################################
	# COMBINE FILTERED INDELS and MIXED VARIANATS for each sample #
	###############################################################

		COMBINE_FILTERED_VCF_FILES ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N L.01_COMBINE_FILTERED_VCF_FILES"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COMBINE_FILTERED_VCF_FILES.log" \
			-hold_jid K.01-A.01_FILTER_SNV_AND_REF"_"$SGE_SM_TAG"_"$PROJECT,K.02-A.01_FILTER_INDEL_AND_MIXED"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/L.01_COMBINE_FILTERED_VCF_FILES.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	############################################
	# EXTRACT ALL SITES FOR CFTR TARGET REGION #
	############################################

		EXTRACT_CFTR_TARGET_REGION ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N M.01_EXTRACT_CFTR_TARGET_REGION"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_CFTR_TARGET_REGION.log" \
			-hold_jid L.01_COMBINE_FILTERED_VCF_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/M.01_EXTRACT_CFTR_TARGET_REGION.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$TARGET_BED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	################################
	# INDEX CFTR TARGET REGION VCF #
	################################

		INDEX_CFTR_TARGET_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N M.01-A.01_INDEX_CFTR_TARGET_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-INDEX_CFTR_TARGET_VCF.log" \
			-hold_jid M.01_EXTRACT_CFTR_TARGET_REGION"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/M.01-A.01_VCF_INDEX_CFTR_TARGET_VCF.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###############################################
	# GENERATE VCF METRICS FOR CFTR TARGET REGION #
	###############################################

		VCF_METRICS_CFTR_TARGET ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N M.01-A.01_VCF_METRICS_CFTR_TARGET"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VCF_METRICS_CFTR_TARGET.log" \
			-hold_jid M.01-A.01_INDEX_CFTR_TARGET_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/M.01-A.01-A.01_VCF_METRICS_CFTR_TARGET.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_DICT \
				$DBSNP \
				$TARGET_BED \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	########################
	# EXTRACT BARCODE SNPS #
	########################

		EXTRACT_BARCODE_SNPS ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N M.02_EXTRACT_BARCODE_SNPS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_BARCODE_SNPS.log" \
			-hold_jid L.01_COMBINE_FILTERED_VCF_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/M.02_EXTRACT_BARCODE_SNPS.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$BARCODE_SNPS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

#################################################################################
# Run alignment metrics generation, small variant calling and metric generation #
#################################################################################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} NR>1 {print $8}' \
			| sort \
			| uniq );
	do
		CREATE_SAMPLE_ARRAY
		COLLECT_MULTIPLE_METRICS
		echo sleep 0.1s
		COLLECT_HS_METRICS
		echo sleep 0.1s
		SELECT_VERIFYBAMID_VCF
		echo sleep 0.1s
		RUN_VERIFYBAMID
		echo sleep 0.1s
		DOC_CFTR
		echo sleep 0.1s
		ANNOTATE_PER_BASE_REPORT_CFTR
		echo sleep 0.1s
		FILTER_ANNOTATED_PER_BASE_REPORT_CFTR
		echo sleep 0.1s
		BGZIP_ANNOTATED_PER_BASE_REPORT_CFTR
		echo sleep 0.1s
		TABIX_ANNOTATED_PER_BASE_REPORT_CFTR
		echo sleep 0.1s
		ANNOTATE_PER_CFTR_FEATURE
		echo sleep 0.1s
		CALL_HAPLOTYPE_CALLER
		echo sleep 0.1s
		HC_BAM_TO_CRAM
		echo sleep 0.1s
		INDEX_HC_CRAM
		echo sleep 0.1s
		GENOTYPE_GVCF
		echo sleep 0.1s
		ANNOTATE_VCF
		echo sleep 0.1s
		EXTRACT_SNV_AND_REF
		echo sleep 0.1s
		FILTER_SNV_AND_REF
		echo sleep 0.1s
		EXTRACT_INDEL_AND_MIXED
		echo sleep 0.1s
		FILTER_INDEL_AND_MIXED
		echo sleep 0.1s
		COMBINE_FILTERED_VCF_FILES
		echo sleep 0.1s
		EXTRACT_CFTR_TARGET_REGION
		echo sleep 0.1s
		INDEX_CFTR_TARGET_VCF
		echo sleep 0.1s
		VCF_METRICS_CFTR_TARGET
		echo sleep 0.1s
		EXTRACT_BARCODE_SNPS
		echo sleep 0.1s
done

##############################################################
##### STRUCTURAL VARIANT ANALYSIS USING ILLUMINA'S MANTA #####
##############################################################

	##################################################################
	# MANTA RUN CONFIGURATION ########################################
	##################################################################
	# The config file was modified such that #########################
	##### minEdgeObservations = 2 and (instead of 3) #################
	##### minCandidateSpanningCount = 2 (instead of 3) ###############
	##### this file is called during run configuration $MANTA_CONFIG #
	##################################################################

		CONFIGURE_MANTA ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.06-CONFIGURE_MANTA"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-CONFIGURE_MANTA.log" \
			-hold_jid G.01-INDEX_CRAM"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.06-CONFIGURE_MANTA.sh \
				$MANTA_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$MANTA_CFTR_BED \
				$MANTA_CONFIG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#############
	# RUN MANTA #
	#############

		RUN_MANTA ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.06-A.01-RUN_MANTA"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-RUN_MANTA.log" \
			-hold_jid H.06-CONFIGURE_MANTA"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.06-A.01-RUN_MANTA.sh \
				$MANTA_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

#############################################
# RUN STEPS FOR STRUCTURAL VARIANT ANALYSIS #
#############################################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","} NR>1 {print $8}' \
		| sort \
		| uniq );
	do
		CREATE_SAMPLE_ARRAY
		CONFIGURE_MANTA
		echo sleep 0.1s
		RUN_MANTA
		echo sleep 0.1s
done

#######################################
##### CRYPTIC SPLICING ALGORITHMS #####
#######################################

	########################################################
	# FILTER CFTR FULL VCF TO VCF ONLY CONTAINING VARIANTS #
	########################################################

		VARIANT_ONLY_CFTR_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N N.01-VARIANT_ONLY_CFTR_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VARIANT_ONLY_CFTR_VCF.log" \
			-hold_jid M.01-A.01_INDEX_CFTR_TARGET_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/N.01-VARIANT_ONLY_CFTR_VCF.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	####################################################################
	# DECOMPOSE MULTI-ALLELIC VARIANTS IN VARIANT ONLY CFTR REGION VCF #
	####################################################################

		DECOMPOSE_NORMALIZE_VARIANT_ONLY_CFTR_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-DECOMPOSE_NORMALIZE_VARIANT_ONLY_CFTR_VCF.log" \
			-hold_jid N.01-VARIANT_ONLY_CFTR_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE.sh \
				$VT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###########################################################################################
	# SPLICEAI CAN ONLY BE RUN SERVERS THAT SUPPORT AVX #######################################
	# CURRENTLY THE ONLY SERVERS THAT DON'T ARE THE c6100s (prod.q,rnd.q,c6100-4 and c6100-8) #
	###########################################################################################

		RUN_SPLICEAI ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$SPLICEAI_QUEUE_QSUB_ARG \
			-N P.01-RUN_SPLICEAI"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-RUN_SPLICEAI.log" \
			-hold_jid O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.01-RUN_SPLICEAI.sh \
				$SPLICEAI_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###########################################################################################
	# Reformat SpliceAI to extract just the scores from the vcf file ##########################
	###########################################################################################

		REFORMAT_SPLICEAI ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.01-A.01-REFORMAT_SPLICEAI"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-REFORMAT_SPLICEAI.log" \
			-hold_jid P.01-RUN_SPLICEAI"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.01-A.01-REFORMAT_SPLICEAI.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	########################################################
	# extract CFTR FOCUSED VARIANTS FROM SPLICEAI FILE #####
	########################################################

		EXTRACT_CFTR_FOCUSED ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.01-A.02-EXTRACT_CFTR_FOCUSED"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_CFTR_FOCUSED.log" \
			-hold_jid P.01-RUN_SPLICEAI"_"$SGE_SM_TAG"_"$PROJECT,C.01-FIX_BED_FILES"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.01-A.02-EXTRACT_CFTR_FOCUSED.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$CFTR_FOCUSED \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#################################################################################################
	# run base vep to create cftr region vcf with gene symbol/transcript annotation for cryptsplice #
	#################################################################################################

		RUN_VEP_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG\
				$VEP_HTSLIB_QSUB_ARG \
				$VEP_PERL5LIB_QSUB_ARG \
			-N P.02-VEP_VCF"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-VEP_VCF.log" \
			-hold_jid O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.02-VEP_VCF.sh \
				$VEP_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$VEP_REF_CACHE \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#######################################
	# RUN CRYPTSLICE ON VEP ANNOTATED VCF #
	#######################################

		RUN_CRYPTSPLICE ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG\
			-N Q.01-RUN_CRYPTSPLICE"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-RUN_CRYPTSLICE.log" \
			-hold_jid P.02-VEP_VCF"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/Q.01-RUN_CRYPTSPLICE.sh \
				$CRYPTSPLICE_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$CRYPTSPLICE_DATA \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##############################
	# REFORMAT CRYPTSLICE OUTPUT #
	##############################

		REFORMAT_CRYPTSPLICE ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG\
			-N Q.01-A.01-REFORMAT_CRYPTSPLICE"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-REFORMAT_CRYPTSLICE.log" \
			-hold_jid Q.01-RUN_CRYPTSPLICE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/Q.01-A.01-REFORMAT_CRYPTSPLICE.sh \
				$CRYPTSPLICE_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	##################################
	# RUN ANNOVAR ON CFTR REGION VCF #
	##################################

		RUN_ANNOVAR ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.05-RUN_ANNOVAR"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-RUN_ANNOVAR.log" \
			-hold_jid O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.05-RUN_ANNOVAR.sh \
				$ANNOVAR_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$ANNOVAR_DATABASE_FILE \
				$ANNOVAR_REF_BUILD \
				$ANNOVAR_INFO_FIELD_KEYS \
				$ANNOVAR_HEADER_MAPPINGS \
				$ANNOVAR_VCF_COLUMNS \
				$THREADS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#############################################################################################
	# COMBINE REFORMATED SPLICEAI AND CRYPTSPLICE OUTPUT WITH ANNOVAR ###########################
	# do a subset with variants in cftr2 exons plus flanking regions, cryptic splice sites, etc #
	#############################################################################################

		COMBINE_ANNOVAR_WITH_SPLICING ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N R.01-COMBINE_ANNOVAR_WITH_SPLICING"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-COMBINE_ANNOVAR_WITH_SPLICING.log" \
			-hold_jid P.01-A.01-REFORMAT_SPLICEAI"_"$SGE_SM_TAG"_"$PROJECT,Q.01-A.01-REFORMAT_CRYPTSPLICE"_"$SGE_SM_TAG"_"$PROJECT,P.05-RUN_ANNOVAR"_"$SGE_SM_TAG"_"$PROJECT,P.01-A.02-EXTRACT_CFTR_FOCUSED"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/R.01-COMBINE_ANNOVAR_WITH_SPLICING.sh \
				$COMBINE_ANNOVAR_WITH_SPLICING_R_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$CFTR2_VCF \
				$COMBINE_ANNOVAR_WITH_SPLICING_R_SCRIPT \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

###########################################
# run steps for cryptic splicing analysis #
###########################################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","} NR>1 {print $8}' \
		| sort \
		| uniq );
	do
		CREATE_SAMPLE_ARRAY
		VARIANT_ONLY_CFTR_VCF
		echo sleep 0.1s
		DECOMPOSE_NORMALIZE_VARIANT_ONLY_CFTR_VCF
		echo sleep 0.1s
		RUN_SPLICEAI
		echo sleep 0.1s
		REFORMAT_SPLICEAI
		echo sleep 0.1s
		EXTRACT_CFTR_FOCUSED
		echo sleep 0.1s
		RUN_VEP_VCF
		echo sleep 0.1s
		RUN_CRYPTSPLICE
		echo sleep 0.1s
		REFORMAT_CRYPTSPLICE
		echo sleep 0.1s
		RUN_ANNOVAR
		echo sleep 0.1s
		COMBINE_ANNOVAR_WITH_SPLICING
		echo sleep 0.1s
done

########################
##### CFTR2 REPORT #####
########################

	#####################################################
	# REMOVE DBSNP ID FROM VARIANT ONLY CFTR REGION VCF #
	#####################################################

		REMOVE_DBSNP_ID_VARIANT_ONLY_CFTR_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.03-CFTR2_REMOVE_DBSNP_ID"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-CFTR2_REMOVE_DBSNP_ID_VARIANT_ONLY_CFTR_VCF.log" \
			-hold_jid O.01-CFTR2_VCF_DECOMPOSE_NORMALIZE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.03-CFTR2_REMOVE_DBSNP_ID.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	########################################
	# ANNOTATE VCF ID FIELD WITH HGVS CDNA #
	########################################

		ANNOTATE_WITH_HGVS_CDNA ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.03-A.01-ANNOTATE_VCF_HGVS_CDNA"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-ANNOTATE_VCF_HGVS_CDNA.log" \
			-hold_jid P.03-CFTR2_REMOVE_DBSNP_ID"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.03-A.01-ANNOTATE_VCF_HGVS_CDNA.sh \
				$GATK_3_7_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$CFTR2_VCF \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	############################
	# EXTRACT CAUSAL CFTR2 VCF #
	############################

		EXTRACT_CFTR2_VCF ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N P.03-A.01-A.01-EXTRACT_CFTR2_VARIANTS"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-EXTRACT_CFTR2_VARIANTS.log" \
			-hold_jid P.03-A.01-ANNOTATE_VCF_HGVS_CDNA"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/P.03-A.01-A.01-EXTRACT_CFTR2_VARIANTS.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$CFTR2_VCF \
				$CFTR2_VEP_TABLE \
				$CFTR2_RAW_TABLE \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#################################################
	# REFORMAT MANTA VCF INTO A TAB DELIMITED TABLE #
	#################################################

		MANTA_VCF_TO_TABLE ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.06-A.01-A.01-MANTA_VCF_TO_TABLE"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-MANTA_VCF_TO_TABLE.log" \
			-hold_jid H.06-A.01-RUN_MANTA"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.06-A.01-A.01-MANTA_VCF_TO_TABLE.sh \
				$GATK_3_5_0_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	###############################################
	# REFORMAT MANTA TABLE INTO CFTR2 REPORT STUB #
	###############################################

		MANTA_REPORT ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N H.06-A.01-A.01-A.01-MANTA_REPORT"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-MANTA_REPORT.log" \
			-hold_jid H.06-A.01-A.01-MANTA_VCF_TO_TABLE"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/H.06-A.01-A.01-A.01-MANTA_REPORT.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$REF_GENOME \
				$CFTR_EXONS \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

	#################################################################
	# MERGE THE CAUSAL, NON-CAUSAL, AND MANTA REPORTS INTO ONE FILE #
	#################################################################

		CREATE_CFTR2_REPORT ()
		{
			echo \
			qsub \
				$QSUB_ARGS \
				$STANDARD_QUEUE_QSUB_ARG \
			-N Q.02-CREATE_CFTR2_REPORT"_"$SGE_SM_TAG"_"$PROJECT \
				-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-CREATE_CFTR2_REPORT.log" \
			-hold_jid P.03-A.01-A.01-EXTRACT_CFTR2_VARIANTS"_"$SGE_SM_TAG"_"$PROJECT,H.06-A.01-A.01-A.01-MANTA_REPORT"_"$SGE_SM_TAG"_"$PROJECT \
			$SCRIPT_DIR/Q.02-CREATE_CFTR2_REPORT.sh \
				$ALIGNMENT_CONTAINER \
				$CORE_PATH \
				$PROJECT \
				$SM_TAG \
				$SAMPLE_SHEET \
				$SUBMIT_STAMP
		}

##################################
# QC REPORT PREP FOR EACH SAMPLE #
##################################

QC_REPORT_PREP ()
{
echo \
qsub \
	$QSUB_ARGS \
	$STANDARD_QUEUE_QSUB_ARG \
-N X.01_QC_REPORT_PREP"_"$SGE_SM_TAG"_"$PROJECT \
	-o $CORE_PATH/$PROJECT/LOGS/$SM_TAG/$SM_TAG"-QC_REPORT_PREP.log" \
-hold_jid \
M.01-A.01_VCF_METRICS_CFTR_TARGET"_"$SGE_SM_TAG"_"$PROJECT,\
M.02_EXTRACT_BARCODE_SNPS"_"$SGE_SM_TAG"_"$PROJECT,\
H.03-A.01-RUN_VERIFYBAMID"_"$SGE_SM_TAG"_"$PROJECT,\
H.02-COLLECT_HS_METRICS"_"$SGE_SM_TAG"_"$PROJECT,\
H.01-COLLECT_MULTIPLE_METRICS"_"$SGE_SM_TAG"_"$PROJECT,\
R.01-COMBINE_ANNOVAR_WITH_SPLICING"_"$SGE_SM_TAG"_"$PROJECT,\
Q.02-CREATE_CFTR2_REPORT"_"$SGE_SM_TAG"_"$PROJECT \
$SCRIPT_DIR/X.01-QC_REPORT_PREP.sh \
	$ALIGNMENT_CONTAINER \
	$CORE_PATH \
	$PROJECT \
	$SM_TAG \
	$EXPECTED_SEX \
	$SAMPLE_SHEET \
	$SUBMIT_STAMP
}

################################################
# RUN STEPS TO CREATE CFTR2 AND QC REPORT PREP #
################################################

for SAMPLE in $(awk 1 $SAMPLE_SHEET \
		| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
		| awk 'BEGIN {FS=","} NR>1 {print $8}' \
		| sort \
		| uniq );
	do
		CREATE_SAMPLE_ARRAY
		REMOVE_DBSNP_ID_VARIANT_ONLY_CFTR_VCF
		echo sleep 0.1s
		ANNOTATE_WITH_HGVS_CDNA
		echo sleep 0.1s
		EXTRACT_CFTR2_VCF
		echo sleep 0.1s
		MANTA_VCF_TO_TABLE
		echo sleep 0.1s
		MANTA_REPORT
		echo sleep 0.1s
		CREATE_CFTR2_REPORT
		echo sleep 0.1s
		QC_REPORT_PREP
		echo sleep 0.1s
done

#############################
##### END PROJECT TASKS #####
#############################

# grab email addy

	SEND_TO=`cat $SCRIPT_DIR/../email_lists.txt`

# grab submitter's name

	PERSON_NAME=`getent passwd | awk 'BEGIN {FS=":"} $1=="'$SUBMITTER_ID'" {print $5}'`

# build hold id for qc report prep per sample, per project

	BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP ()
	{
		HOLD_ID_PATH="-hold_jid "

		for SAMPLE in $(awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} $1=="'$PROJECT'" {print $8}' \
			| sort \
			| uniq);
		do
			CREATE_SAMPLE_ARRAY
			HOLD_ID_PATH=$HOLD_ID_PATH"X.01_QC_REPORT_PREP"_"$SGE_SM_TAG"_"$PROJECT"","
			HOLD_ID_PATH=`echo $HOLD_ID_PATH | sed 's/@/_/g'`
		done
	}

# run end project functions (qc report, file clean-up) for each project

	PROJECT_WRAP_UP ()
	{
		echo \
		qsub \
			$QSUB_ARGS \
			$STANDARD_QUEUE_QSUB_ARG \
			$REQUEST_ENTIRE_SERVER_QSUB_ARG \
		-N X.01-X.01_END_PROJECT_TASKS"_"$PROJECT \
			-o $CORE_PATH/$PROJECT/LOGS/$PROJECT"-END_PROJECT_TASKS.log" \
		$HOLD_ID_PATH \
		$SCRIPT_DIR/X.01-X.01-END_PROJECT_TASKS.sh \
			$ALIGNMENT_CONTAINER \
			$CORE_PATH \
			$PROJECT \
			$SCRIPT_DIR \
			$SUBMITTER_ID \
			$SAMPLE_SHEET \
			$SUBMIT_STAMP \
			$SEND_TO
	}

# final loop

for PROJECT in $(awk 1 $SAMPLE_SHEET \
			| sed 's/\r//g; /^$/d; /^[[:space:]]*$/d; /^,/d' \
			| awk 'BEGIN {FS=","} NR>1 {print $1}' \
			| sort \
			| uniq);
	do
		BUILD_HOLD_ID_PATH_PROJECT_WRAP_UP
		PROJECT_WRAP_UP
done

# MESSAGE THAT SAMPLE SHEET HAS FINISHED SUBMITTING

printf "echo\n"

printf "echo $SAMPLE_SHEET has finished submitting at `date`\n"

# EMAIL WHEN DONE SUBMITTING

printf "$SAMPLE_SHEET\nhas finished submitting at\n`date`\nby `whoami`" \
	| mail -s "$PERSON_NAME has submitted SUBMITTER_CFTR_Full_Gene_Sequencing_Pipeline.sh" \
		$SEND_TO

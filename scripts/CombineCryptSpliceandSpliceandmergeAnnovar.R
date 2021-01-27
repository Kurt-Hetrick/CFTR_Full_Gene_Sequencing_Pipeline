library(dplyr)
library(tidyr)

# #### Step 1: Load files ####
# CryptSplice prioritized predictions output file name is first argument, and SpliceAI output filename is second argument
args <- commandArgs(TRUE)
CryptSplice <- read.delim(args[1], sep="\t")

# #### Step 2: Clean up CryptSplice output ####
# Reformat identifier column so that it is chr:pos-ref>alt 
CryptSplicesep<-separate(data=CryptSplice,col=variant,into=c("Seq","Chrandpos","Transcript","Reftoalt","num"),sep="-")
CryptSplicesep$varname<-do.call(paste,c(CryptSplicesep[c("Chrandpos","Reftoalt")],sep="-"))

# Remove variants who are predicted to results in pseudoexons but P(var) < P(ref). These shouldn't result in a pseudoexon.
CryptSplicesep$consequence[CryptSplicesep$consequence=="pseudoexon inclusion"&CryptSplicesep$deltaVar<0]<-NA

# Subset to just the variants with a consequence, and only keep necessary columns
CryptSplicesep_withcons<-subset(CryptSplicesep,CryptSplicesep$consequence!="NA")
CryptSplicesep_withcons<-select(CryptSplicesep_withcons,-c("Chrandpos","Transcript","num","info","Seq","Reftoalt"))
colnames(CryptSplicesep_withcons) <-paste("CS",colnames(CryptSplicesep_withcons),sep="_")
CryptSplicesep_withcons <- CryptSplicesep_withcons %>% rename(varname=CS_varname)
 
# Some variants will have 2 consequences. In the CryptSplice output, each consequence is a separate row. Reformat such that each variant has 1 row regardless of the number of consequences.
# Put second consequence (if applicable) in second file
CryptSplicesep_withcons$dup<-duplicated(CryptSplicesep_withcons$varname)
CryptSplicesep_withcons_dup1<-subset(CryptSplicesep_withcons,CryptSplicesep_withcons$dup==FALSE)
CryptSplicesep_withcons_dup1$dup<-NULL
CryptSpliceclean<-CryptSplicesep_withcons_dup1
CryptSplicesep_withcons_dup2<-subset(CryptSplicesep_withcons,CryptSplicesep_withcons$dup==TRUE)
CryptSplicesep_withcons_dup2$dup<-NULL

# If there is indeed a second consequence for at least 1 variant, merge that back in
if (dim(CryptSplicesep_withcons_dup2)[1]>0) {
# rename variables from dup2
colnames(CryptSplicesep_withcons_dup2) <-paste(colnames(CryptSplicesep_withcons_dup2),"2",sep="_")
CryptSplicesep_withcons_dup2 <- CryptSplicesep_withcons_dup2 %>% rename(varname=varname_2)

# merge
CryptSpliceclean<-merge(CryptSplicesep_withcons_dup1,CryptSplicesep_withcons_dup2,by="varname",all=TRUE)
}

# #### Step 3: Clean SpliceAI output ####
# Load SpliceAI data
SpliceAI<-read.delim(args[2],sep="\t")

# Reformat identifier column so that it is chr:pos-ref>alt 
SpliceAI$chrpos<-do.call(paste,c(SpliceAI[c("CHR","POS")],sep=":"))
SpliceAI$refalt<-do.call(paste,c(SpliceAI[c("REF","ALLELE")],sep=">"))
SpliceAI$varname<-do.call(paste,c(SpliceAI[c("chrpos","refalt")],sep="-"))
SpliceAI<-select(SpliceAI,-c("CHR","POS","REF","ALT","chrpos","refalt"))

# Remove those that weren't run by SpliceAI (not within the gene)
SpliceAI<-subset(SpliceAI,SpliceAI$ALLELE!=".")
SpliceAI$ALLELE<-NULL

# Rename
colnames(SpliceAI) <-paste("SAI",colnames(SpliceAI),sep="_")
SpliceAI <- SpliceAI %>% rename(varname=SAI_varname)

# #### Step 4: Merge CryptSplice and SpliceAI output ####
CryptSpliceandSpliceAI<-merge(SpliceAI,CryptSpliceclean,by="varname",all=TRUE)
CryptSpliceandSpliceAI$PredictedBy[!is.na(CryptSpliceandSpliceAI$CS_consequence)]<-"CryptSplice"
CryptSpliceandSpliceAI$PredictedBy[CryptSpliceandSpliceAI$SAI_DS_AG>=0.5|CryptSpliceandSpliceAI$SAI_DS_AL>=0.5|CryptSpliceandSpliceAI$SAI_DS_DG>=0.5|CryptSpliceandSpliceAI$SAI_DS_DL>=0.5]<-"SpliceAI"
CryptSpliceandSpliceAI$PredictedBy[(CryptSpliceandSpliceAI$SAI_DS_AG>=0.5|CryptSpliceandSpliceAI$SAI_DS_AL>=0.5|CryptSpliceandSpliceAI$SAI_DS_DG>=0.5|CryptSpliceandSpliceAI$SAI_DS_DL>=0.5)&!is.na(CryptSpliceandSpliceAI$CS_consequence)]<-"SpliceAI and CryptSplice"


# #### Step 5: Merge with Annovar output ####
Annovar <- read.delim(args[3], sep="\t")
Annovar$varname<-paste0(Annovar$CHROM,":",Annovar$POS,"-",Annovar$REF,">",Annovar$ALT)
Annovar_withSplice<-merge(Annovar,CryptSpliceandSpliceAI,by="varname",all=TRUE)
Annovar_withSplice$varname<-NULL

# #### Step 5: Save
filename=paste0(args[4],".txt")
write.table(Annovar_withSplice,filename,quote=FALSE,row.names=FALSE,sep="\t")

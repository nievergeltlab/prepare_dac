#set working dir
 workingdir=/home/maihofer/katy

#Call to working dir
 cd $workingdir


studyname=ring
studyname_caps=RING #Write the name in capital letters as well..
###Prepare the post-qc genotype data

#Note:This data always has qc in the filename. 

#Note:Sometimes the dates in the name are not october, but rather march. 

#Note: IF THERE IS A V2, USE V2 AND NOT V1!!!!

#Note: IF THERE IS A V2, USE V2 AND NOT V1!!!!

tar xvzf /archive/maihofer/"$studyname"_qc_v1_oct6_2016.tgz --wildcards "*-qc.fam" --wildcards "*-qc.bim" --wildcards "*-qc.bed"

#The post-qced genotypes file will be in the folder called STUDYNAME/qc/
#It may also extract a copy of the data from STUDYNAME/qc/imputation
#These files are the same, only the rsIDs have been updated from Illumina to dbSNP
#Prefer to use the one in STUDYNAME/qc. 
#If both exist, please check that the .fam files are the same size.
#(Sometimes it looks like there are two copies, but the file in  STUDYNAME/qc/imputation is
# only a shortcut to the real file. Shortcuts usually have a bent arrow on the icon)


#Note: Please do a quick check of phenotypes in the .fam files. If the phenotyping is off, check back with me
#Note: Phenotype in Army STARRS may not correspond to real phenotype, please check
#Note: Phenotype in STRONGSTAR will not correspond to real phenotype, needs to be fixed!! 

###Prepare best guess dosages data

#First extract dosages data from the archive 
#Note: 1) really big studies have multiple files to be extracted, which will be suffixed A B C..


 tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016.tar

#Set number of CPU cores to use
 nodesize=16

#Set info threshold for inclusion of dosages
 info_th=0

#Set MAF threshold for inclusion of dosages
 freq_th=0

#Set cutoff for genotype calling
 bg_th=0.8

#Set where dosages data are (I'll write typical path here:)
 indir="$workingdir"/"$studyname_caps"/qc/imputation/dasuqc1_pts_"$studyname"_mix_am-qc.hg19.ch.fl/qc1
 
#Set output directory
 outdir="$workingdir"/"$studyname"/
 if [ ! -e $outdir ]
 then
  mkdir $outdir
 fi
#Note: walltime is set as hours:minutes:seconds. Increase wall time if jobs fail.
#do i need -V?
 qsub -l walltime=02:20:00 bestguessgenos.qsub -d $workingdir -e errandout/ -o errandout/ -F "-i $info_th -f $freq_th -b $bg_th -d $indir -o $outdir  -n $nodesize -m default"
 
#Test run for job
# qsub -l walltime=00:05:00 bestguessgenos.qsub -d $workingdir -e errandout/ -o errandout/ -F "-i $info_th -f $freq_th -b $bg_th -d $indir -o $outdir  -n $nodesize -m default"

#Job failure can be checked by looking at the .o and .e files in the errandout folders
#Generally a filesize > 0 for the .e file means there are errors that you should check

#When the job is done, check the data:

#The bgn folder should have approximately 2781 files in it
#The qc1 folder should have aproxiumately 4635 files in it

###Prepare merged best guess dosages data
#Don't start this until the best guess files are made!!

#Set location of bg data (should be location of outdir!
 indirm="$workingdir"/"$studyname"/      

#one of : bgs, bg, bgn (typically bgn is used)
 bgtype='bgn'

#Set location where merged_data will be stored
 outdirm="$workingdir"/"$studyname"/"$bgtype"_cobg   
 
#Make it so there are no errors
 if [ ! -e $outdirm ]
 then
  mkdir $outdirm
 fi
 
##If the study has n < 2000, run the following:
 qsub -l walltime=02:00:00 merge_all_genotypes.qsub -d $workingdir -e errandout/ -o errandout/ -F "-d $indirm -o $outdirm -t $bgtype -s $studyname"
 #Test run for job
 #qsub -l walltime=00:05:00 merge_all_genotypes.qsub -d $workingdir -e errandout/ -o errandout/ -F "-d $indirm -o $outdirm -t $bgtype -s $studyname"

##If the study has n >= 2000, run the following:
 qsub -t1-22 -l walltime=02:00:00 merge_all_genotypes_bychr.qsub -d $workingdir -e errandout/ -o errandout/ -F "-d $indirm -o $outdirm -t $bgtype -s $studyname"


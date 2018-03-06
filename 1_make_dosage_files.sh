#set working dir
 workingdir=/home/maihofer/katy

#Call to working dir
 cd $workingdir

studyname=wrby
studyname_caps=WRBY #Write the name in capital letters as well..

#Set/make output directories
 outdir="$workingdir"/"$studyname"/

 if [ ! -e $outdir ]
 then
  mkdir $outdir
 fi
 
 if [ ! -e "$outdir"/bgn ]
 then
  mkdir "$outdir"/bgn 
 fi
 
 if [ ! -e "$outdir"/qc ]
 then
  mkdir "$outdir"/qc
 fi

 if [ ! -e "$outdir"/qc1 ]
 then
  mkdir "$outdir"/qc1
 fi
 
 if [ ! -e "$outdir"/info ]
 then
  mkdir "$outdir"/info
 fi
  
###Prepare the post-qc genotype data

#Note:This data always has qc in the filename. 

#Note:Sometimes the dates in the name are not october, but rather march. 

#Note: IF THERE IS A V2, USE V2 AND NOT V1!!!!

tar xvzf /archive/maihofer/"$studyname"_qc_v1_oct6_2016.tgz --wildcards "*-qc.fam" --wildcards "*-qc.bim" --wildcards "*-qc.bed" --wildcards "*reference_info*"  --wildcards "*mds_cov"
#qc_v1_oct6_2016.tgz 
#qc_v2_mar12_2017.tgz


#Notes: The post-qced genotypes file will be in the folder called STUDYNAME/qc/
#It may also extract a copy of the data from STUDYNAME/qc/imputation
#These files are the same, only the rsIDs have been updated from Illumina to dbSNP
#Prefer to use the one in STUDYNAME/qc. 
#If both exist, please check that the .fam files are the same size.
#(Sometimes it looks like there are two copies, but the file in  STUDYNAME/qc/imputation is
# only a shortcut to the real file. Shortcuts usually have a bent arrow on the icon)


#Specify phenotype file (give full path)
phenofile=rutgers_v2.pheno.txt #pts_pts1_mix_am-qc-goodjmca.pheno #strongstar_v1.pheno.txt

#If phenotype file was specified, will update phenotype in plink data. If not, data will just be copied.
if [  $phenofile != "xxxx" ]
then
 phen="--pheno $phenofile"
else
 phen=""
fi

#Here I've assumed that the QCed phenotype is in the default directory. Almost always this is correct. I'm using the empirical f distrubition from the het test to set the impute sex for missing samples. 
#imputed sex should match sex in file, if they dont, they were qced out
module load plink2
plink --bfile "$studyname_caps"/qc/pts_"$studyname"_mix_am-qc --impute-sex .45 .8 --allow-no-sex $phen --make-bed --out "$outdir"/qc/pts_"$studyname"_mix_am-qc
awk '{print $1,$2,$5}' "$outdir"/qc/pts_"$studyname"_mix_am-qc.fam > "$outdir"/qc/pts_"$studyname"_mix_am-qc.sexfile

cp "$studyname_caps"/qc/pca/*mds_cov "$outdir"/qc/.

#Note: Please do a quick check of phenotypes in the .fam files. If the phenotyping is off, check back with me
#Note: Phenotype in Army STARRS may not correspond to real phenotype, please check. may want to update predicted gender as well
#Note: Phenotype in STRONGSTAR will not correspond to real phenotype, needs to be fixed!! 
#Note: Phenotype in Saturn/Defend may not correspond 100% to real phenotype, please check!
#Note: Phenotype in ONG definitely needs to be reset! 
#Note: may want to update gender for delahanty subjects, ppds, and sydney neuroimaging
#Check pheno in PTSD1 and the gender. Almeida got analyzed weird so I dont remember how that went. fixed.
#For Yehuda sample: remove subjects with 1039 IDs. rename Participant 1456-08 is the same participant as 1456-008.

###Prepare best guess dosages data

#Note: walltime is set as hours:minutes:seconds. Increase wall time if jobs fail.

#First extract dosages data from the archive 
#Note: 1) really big studies have multiple files to be extracted, which will be suffixed A B C..

 tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016.tar
 # tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016_a.tar
 # tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016_b.tar
 # tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016_c.tar
 # tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016_d.tar
 # tar xvf /archive/maihofer/"$studyname"_an_v1_oct6_2016_e.tar




#Location of PLINK binaries
 p2_loc=/home/maihofer/katy/plink2
 p19_loc=/home/maihofer/katy/plink

#Set where dosages data are (I'll write typical path here :)
 indir_dosages="$workingdir"/"$studyname_caps"/qc/imputation/dasuqc1_pts_"$studyname"_mix_am-qc.hg19.ch.fl/qc1

#Set number of CPU cores to use
 nodesize=16

#Set info threshold for inclusion of dosages
 info_th=0

#Set MAF threshold for inclusion of dosages
 freq_th=0

#Note: Laramie threshold settings are 
 #info_th=0.8
 #freq_th=0.01
 
#Set cutoff for genotype calling
 bg_th=0.8

#Best guess type. One of : bgs, bg, bgn (typically bgn is used)
 bgtype="bgn"

 
#Set cutoff for missingness of best guess data (default 1 - do not filter markers!)
 geno_th=xxxx

 sexlist="$outdir"/qc/pts_"$studyname"_mix_am-qc.sexfile #SEt to xxxx if no updates required!

#User:If for gcta, set if for eur or aam. if for dac, set to dac
 
 
for ancset in eur aam lat dac
do

if [ $ancset == "dac" ]
then
 ancgroup=""
 snpfile=xxxx #unless otherwise specified!
 keepfile=xxxx #unless otherwise specified!
 suffix=xxxx
fi

#Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
if [ $ancset != "dac" ]
then
 ancgroup=$ancset #eur or aam or lat
 snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
 keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
 suffix="$ancgroup"
fi

#Set and make output directories

#Output dosages
 outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
#Location of info scores
 if [ ! -e "$outdir_info" ]
 then
  mkdir "$outdir_info"
 fi
 
#Location of filtered dosages
 if [ ! -e "$outdir_dosages" ]
 then
  mkdir "$outdir_dosages"
 fi
#Location of best guess
 if [ ! -e "$outdir_bg" ]
 then
  mkdir "$outdir_bg"
 fi
#Location of merged best guess
 if [ ! -e "$outdirm" ]
 then
  mkdir "$outdirm"
 fi

done

##Get info scores and MAFs for all markers

 #Gives SNP list with info >= info_th and maf >= freq_th, which can be used to filter data in later steps
 #--keep filter will select only certain subjects for maf/info calcs 
 #Script functions also as a covariate free linear association analysis
 #speed test note: 350 files in 20 minutes for 3500 subs
for ancset in eur aam lat dac
do

 if [ $ancset == "dac" ]
 then
  ancgroup=""
  snpfile=xxxx #unless otherwise specified!
  keepfile=xxxx #unless otherwise specified!
  suffix=xxxx
 fi

 #Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
 if [ $ancset != "dac" ]
 then
  ancgroup=$ancset #eur or aam or lat
  snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
  keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
  suffix="$ancgroup"
 fi
 outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
 qsub -l walltime=02:00:00 afs_info.qsub -d $workingdir -e errandout/"$studyname"_"$step""$ancgroup"_afsinfo.e -o errandout/"$studyname"_"$step""$ancgroup"_afsinfo.o -F "-i $info_th -f $freq_th  -d $indir_dosages -o $outdir_info -n $nodesize -p $phenofile -k $keepfile -t $p19_loc "
 
 done
 
#After this has run, can get a SNPlist of markers that are good according to your metric
 #cat "$outdir"/info"$ancgroup"/*.snplist > "$outdir"/"studyname"_info"$info_th"_maf"$freq_th".snplist
 #snpfile="$outdir"/"$ancgroup""studyname"_info"$info_th"_maf"$freq_th".snplist
 #wc -l $snpfile #should be several million lines..


#Remake dosage data with correct phenotype info (--keep filter will reduce files down to select subset)
#Speed test note: 100 files in 5 minutes, for ~3500 subs.
#-s filter will limit to just a snplist. BE SURE -s is set to xxxx if you want unfiltered reults!

for ancset in eur aam lat dac
do

 if [ $ancset == "dac" ]
 then
  ancgroup=""
  snpfile=xxxx #unless otherwise specified!
  keepfile=xxxx #unless otherwise specified!
  suffix=xxxx
 fi

 #Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
 if [ $ancset != "dac" ]
 then
  ancgroup=$ancset #eur or aam or lat
  snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
  keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
  suffix="$ancgroup"
 fi
  outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
 qsub -l walltime=04:00:00 dosage_recode.qsub -d $workingdir -e errandout/"$studyname"_"$step""$ancgroup"_dosages.e -o errandout/"$studyname"_"$step""$ancgroup"_dosages.o -F "-d $indir_dosages -o $outdir_dosages -n $nodesize -p $phenofile -k $keepfile -s $snpfile -t $p19_loc -z $suffix -q $p2_loc  -x $sexlist"

 done
 
 ls $outdir_dosages | grep .fini | wc -l 
  ls $outdir_dosages | grep .gz | wc -l 
 
#Speed test note: 100 full files in 5 minutes, for ~3500 subs.
#Make best guess data  #(--keep filter will reduce files down to select subset. )

#for results based upon filtered dosages, set indir to the outdir of dosage data m otherwise set to same as indir of dosage data

for ancset in eur aam lat  dac
do

 if [ $ancset == "dac" ]
 then
  ancgroup=""
  snpfile=xxxx #unless otherwise specified!
  keepfile=xxxx #unless otherwise specified!
  suffix=xxxx
 fi

 #Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
 if [ $ancset != "dac" ]
 then
  ancgroup=$ancset #eur or aam or lat
  snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
  keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
  suffix="$ancgroup"
 fi
  outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
 qsub -l walltime=02:00:00 bestguessgenos_plink2.qsub -d $workingdir -e errandout/"$studyname"_"$step""$ancgroup"_bestguess"$bgtype".e -o errandout/"$studyname"_"$step""$ancgroup"_bestguess"$bgtype".o  -F "-g $geno_th -f $freq_th -b $bg_th -d $outdir_dosages -o $outdir_bg -n $nodesize -p $phenofile -k $keepfile  -t $p2_loc -m $bgtype -s $snpfile"
done

#Job failure can be checked by looking at the .o and .e files in the errandout folders
#Generally a filesize > 0 for the .e file means there are errors that you should check

#When the job is done, check the data:

#The bgn folder should have approximately 2781 files in it
#The qc1 folder should have aproxiumately 4635 files in it

###Prepare merged best guess dosages data
#Don't start this until the best guess files are made!!l

##Merge data by chr by the following:
for ancset in eur aam lat  dac
do

 if [ $ancset == "dac" ]
 then
  ancgroup=""
  snpfile=xxxx #unless otherwise specified!
  keepfile=xxxx #unless otherwise specified!
  suffix=xxxx
 fi

 #Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
 if [ $ancset != "dac" ]
 then
  ancgroup=$ancset #eur or aam or lat
  snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
  keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
  suffix="$ancgroup"
 fi
  outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
 qsub  -l walltime=01:00:00 merge_all_genotypes_bychr_lowmem.qsub -d $workingdir -e errandout/"$studyname"_"$step""$ancgroup"_cobg"$bgtype".e -o errandout/"$studyname"_"$step""$ancgroup"_cobg"$bgtype".o -F "-d $outdir_bg -o $outdirm -t "$bgtype"_"$ancgroup" -s $studyname"
 #qsub -t1-22 -l walltime=01:00:00 merge_all_genotypes_bychr.qsub -d $workingdir -e errandout/"$studyname"_"$step""$ancgroup"_cobg"$bgtype".e -o errandout/"$studyname"_"$step""$ancgroup"_cobg"$bgtype".o -F "-d $outdir_bg -o $outdirm -t "$bgtype"_"$ancgroup" -s $studyname"

 done
 
 ##Merge all chr together (this usually makes files that are too big to be useful)
 #qsub -l walltime=00:15:00 merge_all_genotypes.qsub -d $workingdir -e errandout/ -o errandout/ -F "-d $indirm -o $outdirm -t $bgtype -s $studyname"

 #Make folder for dac data
 if [ ! -e "todac" ]
 then
  mkdir "todac"
 fi
 

#Always done on a study level
 tar cvzf todac/"$studyname"_qcbfile_v1.tgz "$studyname"/qc/

#On a per ancestry/dac level, join all data..
for ancset in lat dac aam eur
do

 if [ $ancset == "dac" ]
 then
  ancgroup=""
  snpfile=xxxx #unless otherwise specified!
  keepfile=xxxx #unless otherwise specified!
  suffix=xxxx
 fi

#Subset to just one pool of subjects ( Should be done only on a second iteration of this step, 
 if [ $ancset != "dac" ]
 then
  ancgroup=$ancset #eur or aam or lat
  snpfile="$ancgroup"maf01_ALL.allchr.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf #Default behavior
  keepfile=ancfiles/"$ancgroup"_pts_"$studyname"_mix_am-qc.subjects
  suffix="$ancgroup"
 fi

 outdir_info="$outdir"/info"$ancgroup" 
 outdir_dosages="$outdir"/qc1"$ancgroup"  #Location of filtered dosages
 outdir_bg="$outdir"/"$bgtype""$ancgroup" #Location of best guess
 outdirm="$outdir"/"$bgtype""$ancgroup"_cobg #Location of merged best guess
 
 tar cvzf todac/"$studyname"_"$ancgroup"_infofile_v1.tgz $outdir_info
 tar cvf todac/"$studyname"_"$ancgroup"_dosfile_v1.tar $outdir_dosages #note this is a .tar!
 tar cvf todac/"$studyname"_"$ancgroup"_bgfile_v1.tar $outdir_bg  #note this is a .tar!
 tar cvf todac/"$studyname"_"$ancgroup"_cogbgfile_v1.tar $outdirm #note this is a .tar!
 

done

 cp -n todac/"$studyname"* /archive/maihofer/dac/.
 
 
  rm todac/"$studyname"*


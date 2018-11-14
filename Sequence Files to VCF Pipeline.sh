#!/bin/bash

echo "Welcome! Thank you for using our pipeline!"
#Find data files for analysis
echo "What is the absolute path to your data files? (FASTQ, SAM or BAM)"
read DATA
DATA=$DATA

#Exit if the correct data file was not inputted
if [[ $DATA != *.fq ]] && [[ $DATA != *.fastq ]] && [[ $DATA != *.sam ]] && [[ $DATA != *.bam ]]; then
	echo
	echo "Please enter a FASTQ, SAM, or BAM file. The script will now exit."
	exit
fi

echo
echo "Where is your reference genome located? (Please enter the absolute path)"
read REF
REF=$REF
echo
echo "Thank you"

echo 
echo "How many CPU's would you like to run this pipeline?"
read CPU
CPU=$CPU

#Make a directory
echo
echo "Now that you have given us this information, we will create a new directory for you containing your reads. It will be called Readsvcf"

mkdir Readsvcf
cd Readsvcf

#if the data file entered was a FASTQ file; start with this step:
if [[ $DATA == *fq ]] || [[ $DATA == *fastq ]]; then 

	#Locate sabre
	echo
	echo "Thank you! Now, we want to locate the program sabre."
	echo "What is the absolute path to sabre?"
	read SABRE
	TOOL=$SABRE
	
	echo
	echo "Awesome! Next, we need the absolute path to the barcodes that will be assigned to the FASTQ file"
	read BARCODE
	BARCODE=$BARCODE
	echo

	#Run the program
	echo "We will now create your separate FASTQ files."
	$TOOL se -f $DATA -b $BARCODE -u unk.fq

	#Now that you have completed the demultiplexing step, we need to trim the sequences.
	#We will use cutadapt to trim the sequences and create newly trimmed fastq files.
	#With such large files, the pipeline may take an extended period of time if run iteratively. 
	#Therefore it will run using parallel and the user has the option to choose how many CPU's paralell will use.


	#Next, we define our adapter sequence.
	echo
	echo "What is the adapter sequence used for your sequencing? (Please enter in all capital letters)"
	read ADAP
	ADAP=$ADAP

	#We trim the adapter sequences from our files.
	#Any sequences longer than 50 nucleotides will be removed.
	#The resulting trimmed files are outputed into a file called cut_output.fastq
	
	echo
	echo "Next is to trim the adapter sequencies from your files..."	

	cutadapt -a $ADAP -m 50 -o cut_output.fq $DATA
		if [ $? -ne 0 ]
			then
				printf There is error in the cutadapt
				exit 1
		fi

	#Now that the sequences have been trimmed. We want to align those sequences against the reference genome. 
	#This step will be accomplished by using BWA. But first the pipeline must know where the BWA is located 

	echo
	echo "What is the path for your BWA tool?"
	read BWA
	BWA=$BWA

	#The BWA can be optimized depending on the number of threads it is run with. 
	#This number depends on the memory of the hardware  the user is using to run the pipeline.
	#The user will have the option to select this number. 

	echo
	echo "How many threads do you want to run the alignment on? (BWA is most optimized with threads that are the same number of cores in your hardware)"
	read THR
	THR=$THR


	#The first step is indexing the reference genome, depending on the size of the genome the user has the option of indexing with two different algorithms 
	echo
	echo "Have you already indexed your reference genome? (Y or N, you only need to do it once rather than every time)"
	read INDEX
	INDEX=$INDEX
	 
	if [[ $INDEX == N ]]; then 
		echo "Is the size of your reference genome LONG or SHORT? (LONG > 100 mb)"
		read ANS
		ANS=$ANS
		echo 
		echo "We will now index your genome, this may be a lengthy process depending on the size."
		echo
		
			if [[ $ANS == LONG ]]; then
				bwa index -a bwtsw $REF
			else
				bwa index -a is $REF
			fi
			
	elif [[ $INDEX == Y ]]; then 
		echo "You said you have already indexed your genome, we will skip this step."
	fi
			  
	#Next we will run the alignment
	echo
	echo "Next we will run the alignment with BWA..."
	echo
	
	parallel -j $CPU $BWA mem -t $THR $REF {}.fq ">" {}.sam ::: $(ls -1 *.fq | sed 's/.fq//')
			if [ $? -ne 0 ]
				then 
					printf There is a problem in the alignment step
					exit 1
			fi

fi

#If a FASTQ file has completed the previous step or a SAM file was entered as the inital data file, then proceed with the follow sections:
if [ -e cut_output.fq ] || [[ $DATA == *.sam ]]; then
	if [[ $DATA == *.sam ]]; then
		cp $DATA .
	fi

	#Now to continue the analysis within the pipeline, we must convert the SAME files into BAM files 
	echo
	echo "Now to convert the SAM files to BAM files..."
	echo

	parallel -j $CPU samtools view -b -S -h {}.sam ">" {}.bam ::: $(ls -1 *.sam | sed 's/.sam//')
			if [ $? -ne 0 ]
				then 
					printf "There is a problem in the samtools-view step"
					exit 1
			fi
			
fi

#If a SAM file has completed the previous step or a BAM file was entered as the inital data file, then proceed with the follow section:
#Counting the number of SAM files in the current directory, if count != 0, then it means that the the previous step was completed with SAM files 
count=`ls -1 *.sam 2>/dev/null | wc -l`
if [ !count != 0 ] || [[ $DATA == *.bam ]]; then	
   if [[ $DATA == *.bam ]]; then
      cp $DATA .
   fi
   
	#The new BAM files will now be sorted and indexed using samtools 
	echo
	echo "The BAM files are now being sorted and indexed using samtools..."
	echo

	parallel -j $CPU samtools sort {}.bam -o {}.sort.bam ::: $(ls -1 *.bam | sed 's/.bam//')
			if [ $? -ne 0 ]
				then 
					printf "There is a problem in the samtools-sort step"
					exit 1
			fi
			
	parallel -j $CPU samtools index {} ::: $(ls -1 *.sort.bam)
		if [ $? -ne 0 ]
			then 
				printf "There is a problem in the samtools-index step"
				exit 1
		fi

			
	# create a list of sorted BAM files with path
	for i in $(ls -1 *.sort.bam)
		do
			printf "$PWD/${i}\n" >> "bamlist"
			if [ $? -ne 0 ]
				then 
					printf "There is a problem in the production of the bam file list"
					exit 1
			fi
	done
				

	#Converting BAM files to VCF
	echo
	echo "Final stage is converting your BAM files to VCF..."
	echo "Your final VCF file will be saved in a directory called Results."
	echo

	mkdir Results
	cd Results


	# -g directs samtools to output genotype likelihoods in the bcf format
	# -f firects samtools to direct the specified reference
	# -b directs samtools to list input BAM files
	samtools mpileup -g -f $REF -b ../bamlist > Variant.bcf
		if [ $? -ne 0 ]
			then
				printf "An error has occurred with samtools mpileup step"
				exit 1
		fi


	# -m directs bcftools to call SNPs, v directs bfctools to only output potential variants
	bcftools call -m -v Variant.bcf > Variants.vcf
		if [ $? -ne 0 ]
			then
				printf "An error has occurred with bcftools"
				exit 1
		fi
		
	#Clean vcf file of duplicates
	# -d ensures that if a record has duplicates, it only keeps the first instance
	bcftools norm -d variants.vcf
			
	#Gave user option to view stats on vcf file
	echo
	echo "Would you like statistics for your VCF file? Y or N"
	read ANS
	ANS=$ANS

	if [[ $ANS == Y ]]; then 
		bcftools stats Variants.vcf > Variants_stats.txt
		echo
		echo "The statistics will be saved in a file called Variants_stats.txt in your Results directory."
		echo "Would you like to print them to screen now? (Y or N)"
		read ANS
		ANS=$ANS
			if [[ $ANS == Y ]]; then
				cat Variants_stats.txt
			fi
	fi 
			
			
fi

echo
echo "Your VCF file is now ready in the path ./Readsvcf/Results/Variants.vcf"
echo "Thank you for running our pipeline, bye!"

exit
	
		

	

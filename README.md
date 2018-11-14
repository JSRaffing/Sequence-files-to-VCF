## GAAJC Pipeline

The GAAJC pipeline is a bioinformatics pipeline designed to use single end read sequencing data in FASTQ format and create a VCF (Variant Call Format) file.  This pipeline executes the job in parallel for increased speed. 

The file conversion is as follows:

**FASTQ -> SAM -> BAM -> VCF**


## Dependencies

This pipeline requires the installation of several different programs. The programs are listed below with a link of where they can be downloaded. The web page of each program provides a list of steps on how to install the program as well as any additional programs that may need to be installed. 

The programs are as follows:

**Sabre** https://github.com/najoshi/sabre
	
**Cutadapt** https://cutadapt.readthedocs.io/en/stable/installation.html
	
**BWA** http://bio-bwa.sourceforge.net/bwa.shtml
	
**Samtools**  https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2
	
**Bcftools** https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2


## Beginning the Pipeline

To begin the pipeline, it requires a reference genome and a sequence file (such as a FASTQ, SAM, or BAM). The pipeline will also require the absolute paths of these files. It will also request the absolute paths of the programs being used to manipulate your sequence data. 
  
## Fast-Tracking the Pipeline 

The GAAJC pipeline has the option of fast tracking the pipeline depending on the file inputted. If for example you give a SAM file of your reads, the pipeline will start at the SAM -> BAM conversion and run till the end. 

## Adjusting Parameters
During the pipeline, you will be asked how many CPUs you would like that pipeline to run. You should look at your computer settings to ensure you are selecting the proper number. 

## Size of the Reference Genome

At the step involving the tool BWA, you will be asked if you want your reference genome indexed or not. If you choose to index your reference genome you will be asked if it is short or long. If your reference genome is greater than 100mb, it is considered long.

## Speed of Indexing the Reference Genome 

A quick note on speed of indexing, depending on the length of your reference genome the speed of the indexing may be longer. For example, indexing the entire human genome takes around 3 hours to finish.


## Authors

- Angela Chen
- Animesh Vadaparti
- Cailin Harris
- Jennien Raffington
- Geoff Strong

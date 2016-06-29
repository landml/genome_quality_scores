# genome_quality_scores
Scripts to support the paper 'Quality scores for 32,000 genomes'

This first version has many remnants from the original design and purpose of this set of scripts. There will be things that don’t make sense in a current context but aren’t doing any harm.

These scripts were written with the following assumptions:

1. They support the development and update of a database managed by the Comparative Genomics Group at the Oak Ridge National Laboratory (ORNL).

2. Written to support the paper: Quality scores for 32,000 genomes, Miriam Land, Doug Hyatt, Se-Ran Jun, Guruprasad H Kora, Loren J Hauser, Oksana Lukjancenko and David W Ussery, Standards in Genomic Sciences, 2014 9:20 DOI: 10.1186/1944-3277-9-20

3.  After initial development, proof of concept, and corresponding paper, a more comprehensive, efficient, and automated system would be created for the long-term maintenance of database.

4.	The scripts here have hard-coded file paths and other system dependencies because they were considered a temporary means of defining the data and processes.

5.	The initial data load included genomes from 5 sources, GenBank genomes, PATRIC, BROAD, DOE KBase, and the sequence read archive (SRA). A fasta file of genomic DNA was downloaded for each genome from each of these sources in October of 2013. As described in the paper, the SRA had been assembled previously for an earlier paper.  Nightly updates of new GenBank genomes were done until April 2016.

6.	The root directory for this project was either /compgenpanfs/cgdb or /auto/compgen/cgdb depending on the computing resource used. Individual scripts may include one or both of these.

7.	As described in the paper, each genome’s DNA sequence was indexed with a single md5 checksum. The md5 was used to assign a file path for the storage of all files associated with a genome.  The first three characters of the md5 were used to divide the master list of all possible md5s into 4096 directories. A genome’s directory is /root_dir/data/3-char-md5/full-md5.

8.	A master list of all genomes, their md5s, names, and scores is called all.summary.txt.  

9.	Scripts for downloading the data are not included here. The management of this will be institution specific.

10.	Scripts for running all the component tools are not included here. The management and pathways for these tools will be institution specific (e.g., queuing system). The options used for running those scripts are included in this readme. 

11.	The scripts here are for parsing output and assigning scores, as defined in the paper.

12.	The DNA sequence was scored with the script score_sequence.pl.

13.	For genomes with at least 20,000 bases, gene finding was done with Prodigal. The –a switch was used to create a file of protein translations. Other output files were created but are not used in the scoring analysis.

14.	Essential genes were identified by running hmmscan (HMMER3 package) with a database of 102 Pfam domains. The --tblout and –noali switches were used. The script score_essential.pl was used to assign scores to the essential gene output.

15.	rRNA was run with RNAmmer version 1.2 on all genomes as they were added. The ‘-m ssu,lsu,tsu’ and –multi’ switches were used and XML output was created. The script score_rrna.pl was used to parse the output and assign a score. The script also extracts the rRNA sequences so they can be used for other tools.

16.	tRNA was run with tRNAscan-SE 1.3.1 on all genomes as they were added. The –m switch was used to create a statistics summary file. The script score_trna.pl was used to parse the output and assign a score. The script also extracts the rRNA sequences so they can be used for other tools.

17.	The script quality_scores.pl was used to combine the scores from all of the sources.

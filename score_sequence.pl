#!/usr/bin/perl
use strict;
use warnings;

#
#	Parse the output from tRNAscan-SE outputs
#	and create a output file for the genome.

#	This can be used for repeated analysis without having to
#	parse all of the raw output files or read the directory.
#

my $md5 = shift || die "Usage: $0 <md5>";
my $stub = substr($md5,0,3);
my $cpen = 10000;

#
#	Make sure the MD5 is valid
#
my $indir = "/compgenpanfs/cgdb/data/$stub/$md5";

unless (-e $indir)
{
	die "Did not find $indir";
}

#
#	Make sure we have a scores directory
#
my $dir = "$indir/scores";
unless (-e $dir)
{
	mkdir("$dir",0775) || die "Did not create score directory $dir";
}


my $fna = "$indir/$md5.fna";
unless (-e $fna)
{
	die "Does not have the input file $fna";
}

my $score   = "$dir/sequence.score.txt";

&score_file($md5, $fna, $score );

if (-e $score )
{
#	&print_file($md5,$score);
}
else
{
	&score_file($score);
	my $second = "$indir/$md5.squal";
	system("cp $score $second") unless (-e $second);
}



#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Score each individual file
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/


sub score_file
{
	my ($md5,$fna,$score) = @_;

	open (OUT,">$score") || die "Did not create $score";
	print OUT "#MD5\tGenus/Species\tQualityScore\tNumContigs\tTotalBases\tGCBases\tNonstBases\tNumGaps\tPercent GC\n";

	my $sequence = "", my $seqLen = 0;
	my $gcBases = 0, my $nonBases = 0, my $numGaps = 0;
	my $seqCtr = 0;

	if(open(SFH, $fna) == 0) 
	{
		warn "...failed to open file $fna for reading\n";
		return;
	}
	while(my $line = <SFH>) 
	{
		if($line =~ /^>/ && $seqCtr != 0) 
		{
			$seqLen += length($sequence);
			$gcBases += ($sequence =~ tr/GC/GC/);
			$nonBases += length($sequence) - ($sequence =~ tr/ACTG/ACTG/);
			$numGaps += scalar (my @tmp = ($sequence =~ /[^N]NNNNNNNNNNN*[^N]/g));
		}
		if($line =~ /^>/) 
		{
			$seqCtr++;
			$sequence = "";
			my @info = split /[\|>]+/, $line;
			next;
		}
		chop $line;
		$line =~ tr/a-z/A-Z/;
		$sequence .= $line;
	}
	close SFH;
	$seqLen += length($sequence);
	$gcBases += ($sequence =~ tr/GC/GC/);
	$nonBases += length($sequence) - ($sequence =~ tr/ACTG/ACTG/);
	$numGaps += scalar (my @tmp = ($sequence =~ /[^N]NNNNNNNNNNN*[^N]/g));

	my $numer = $seqLen; ## REMOVE  - $nonBases;
	my $denom = $seqLen + $cpen*($seqCtr + $numGaps - 1);
	$score = sprintf "%.2f", $numer/$denom;

	my $pctgc = sprintf "%.2f", $gcBases/$seqLen*100; 

	print OUT "$md5\tNO Name\t$score\t$seqCtr\t$seqLen\t$gcBases\t$nonBases\t$numGaps\t$pctgc\n";
#	print "$md5\tNO Name\t$score\t$seqCtr\t$seqLen\t$gcBases\t$nonBases\t$numGaps\t$pctgc\n";
	close OUT;

	&perm($score,'cgdb');
}
sub sq_score() {

}



#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Print out the files
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/


sub print_file
{
	my ($md5,$score) = @_;

	open (IN,$score) || die "Did not open $score";
	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
#		print $line;
	}
	close IN;

}

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#  The file must exist and the user must be the owner
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

sub perm
{
  my ($file,$group) = @_;
  return unless(-e $file && -o $file);
  system ("chmod 775 $file");
  system ("chgrp $group $file");
}


#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
sub usage
{
	die "Usage: $0 <md5>";
}
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/


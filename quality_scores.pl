#!/usr/bin/perl

use strict;
use warnings;

#
#	Get the Combine the Quality Scores for all Genomes
#
#
#	Input and Output files
#
my $indir  = "/compgenpanfs/cgdb/metadata";

my $out    = "$indir/quality.scores.txt";
#
#	Open the files and print the header line
#
open (OUT,">$out") || die "Did not create $out";
my @title = ('#MD5','Genus/Species','Total Score','Sequence Score',"tRNA Score","rRNA Score","Essential Gene Score");
my $title = join("\t",@title);
print OUT "$title\n";

my ($type) = @_;

my %ID;
my $Row;

my $infile = "$indir/all.summary.txt";
open (FH,$infile) || die "Did not open $infile";
my $dummy = <FH>;  ## HEADER Line

my $count=0;
my %Found;
while (my $buf = <FH>)
{
	chomp $buf;
	my @ary = split(/	/,$buf);
	my $md5 = $ary[1];
	next if (exists $Found{$md5});
	$Found{$md5} = 'Y';
	my $stub = substr($md5,0,3);
#	next unless ($stub =~ /000/);

#-----------------------------------------------------------------
#
#	Make sure the MD5 is valid
#
#-----------------------------------------------------------------
	my $dir = "/compgenpanfs/cgdb/data/$stub/$md5/scores";
	next unless (-e $indir);

	my $file = "$dir/sequence.score.txt";
	my $seq_score = &get_data($file);

	$file = "$dir/tRNA.score.txt";
	my $trna_score = &get_data($file);
	
	$file = "$dir/rRNA.score.txt";
	my $rrna_score = &get_data($file);
	
	$file = "$dir/essential.score.txt";
	my $ess_score = &get_data($file);
 
	my $total_score = ($seq_score + $trna_score + $rrna_score  + $ess_score) / 4;
	print OUT "$md5\t$ary[4]\t$total_score\t$seq_score\t$trna_score\t$rrna_score\t$ess_score\n";

	$count++;
#	last if ($count > 100);
}
close FH;
close OUT;
&perm($infile,'cgdb');

sub get_data
{
	my ($file) = @_;
#	print "FILE=$file\n";
	return 0 unless (-e $file);
	open (IN,$file) || warn "did not open $file";
	my $dummy = <IN>;
	my @ary = split(/	/,<IN>);
	close IN;
#	print "MD5=$ary[0]\tNAME=$ary[1]\tSCORE=$ary[2]\n";
	return $ary[2] if ($#ary > 1) ;
	return 0;
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

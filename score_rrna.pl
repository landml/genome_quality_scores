#!/usr/bin/perl
use strict;
use warnings;

#
#	Parse the output from RNAmmer outputs
#	and create a output file for the genome.

#	This can be used for repeated analysis without having to
#	parse all of the raw output files or read the directory.
#

my $md5 = shift || die "Usage: $0 <md5>";
my $stub = substr($md5,0,3);

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


my $infile  = "$indir/$md5.rrna.xml";

unless (-e $infile)
{
	die "Does not have the input file $infile";
}

my $parse   = "$dir/rRNA.summary.txt";
my $score   = "$dir/rRNA.score.txt";

#unless (-e $parse)
{
	&parse_file($md5,$infile,$parse);
}

#if (-e $score && -e $parse)
#{
#	&print_file($md5,$parse,$score);
#}
#else
#{
#	&score_file($md5,$parse,$score);
#}

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Parse each individual file
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

#
#	The input file has one line for each rRNA molecule
#	Accumulate all of the rows in an array called @answer
#	When you get to the last row of a genome ID/name
#	Parse all of the lines, assign a score and print out statisitics
#	Be sure and do this again at the end of the file
#	and print out the stats for the last genome.
#


sub parse_file
{
	my ($md5,$infile,$parse) = @_;

#
#	Create the output file and print the header line
#
	open (OUT,">$parse") || die "Did not create $parse";
	print OUT "#MD5\tFeature\tMolecule\tStart\tStop\tStrand\tContig\tSequence\n";

	open  (IN,$infile) || return;

#-------------------------------------------------------
#	Parse the XML file using the xsltproc command
#	and an input XSL file.
#	Get rid of the header line and blank lines
#	which are appropriate if parsing only one file.
#	Add the id of the genome and print to the output file.
#-------------------------------------------------------

	my $cmd = "ssh viper xsltproc --novalid /home/ml3/test_jobs/rna.xsl $infile";
#	print  "CMD=$cmd\n";
	my @answer = `$cmd`;

	my $count = 0;
	foreach my $line (@answer)
	{
		chomp $line;
		next if ($line lt '     ');
		next if ($line =~ /^Feature/);
		print OUT "$md5\t$line\n";
#		print "$md5\t$line\n";
		$count++;
	}
#	if ($count == 0)
#	{
#		print OUT "$md5\trRNA\t23s_rRNA\t0\t0\n$md5\trRNA\t16s_rRNA\t0\t0\n$md5\trRNA\t5s_rRNA\t0\t0\n";
#	}
	close IN;
	close OUT;
	&perm($parse,'cgdb');

}

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Score the values in the parsed file
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#----------------------------------------------------------------
#	Parse the lines from the file
#	Establish a minimum for each type of molecule
#	Set up an array for the all the lengths found for each type of molecule
#	Set the minimum score to be 0.1
#	Set up a score for each molecule type
#		default = 0
#		if molecule exists and length > minimum - set to .3
#		if molecule exists and length > 50% of minimum - set to .2
#		if molecule exists and length is short - set to .1  
#----------------------------------------------------------------
sub score_file
{
	my ($md5,$parse,$score_file) = @_;

	open (IN,$parse) || die "Did not open $parse";
	open (OUT,">$score_file") || die "Did not create $score_file";
	print OUT "#MD5\tGenus/Species\tScore\tn23\tn16\tn5\tlist23\tlist16\tlist5\n";

	my $min23 = 2900;
	my $min16 = 1450;
	my $min5  = 100;
	my $max23 = 3500;
	my $max16 = 1700;
	my $max5  = 120;
	my @ary23;
	my @ary16;
	my @ary5;

	my $score   = 0.1;
	my $found23 = 0;
	my $found16 = 0;
	my $found5  = 0;

	while (my $line = <IN>)
	{
		next if ($line =~ /^\#/);
		chomp $line;
		my @ary = split(/	/,$line);
		my $type   = $ary[2];
		my $length = $ary[4] - $ary[3];

		if ($type =~ /23/ )
		{ 
			push(@ary23,$length);
			if ($found23 < .3)
			{
				if ($length > $min23 && $length <= $max23)           { $found23 = .3;  }
				elsif ($length > (0.5*$min23) || $length > $max23  ) { $found23 = .2;  }
				else  { $found23 = .1;  }
			}
		}
		elsif ($type =~ /16/ )
		{ 
			push(@ary16,$length);
			if ($found16 < .3)
			{
				if ($length > $min16 && $length <= $max16)           { $found16 = .3;  }
				elsif ($length > (0.5*$min16) || $length > $max16) { $found16 = .2;  }
				else  { $found16 = .1;  }
			}
		}
		elsif ($type  =~ /5/ )
		{ 
			push(@ary5,$length);
			if ($found5 < .3)
			{
				if ($length > $min5 && $length <= $max5)           { $found5 = .3;  }
				elsif ($length > (0.5*$min5) || $length > $max5 ) { $found5 = .2;  }
				else  { $found5 = .1;  }
			}
		}
	
#		print OUT "$md5\t$ary[2]\t$length\n";
	}

#
#	Create output field with concatenated lengths of the molecules
#

	my $list23 = join('/',@ary23);
	my $list16 = join('/',@ary16);
	my $list5  = join('/',@ary5);
#
#	Set the number of molecules found of each type
#
	my $n23 = $#ary23 + 1;
	my $n16 = $#ary16 + 1;
	my $n5  = $#ary5 + 1;

#
#	Calculate Score and print to output file
#
	$score = 0.1 + $found23 + $found16 + $found5;	

	print OUT "$md5\tNO Name\t$score\t$n23\t$n16\t$n5\t$list23\t$list16\t$list5\n";
#	print "$md5\tNO Name\t$score\t$n23\t$n16\t$n5\t$list23\t$list16\t$list5\n";

	&perm($score,'cgdb');
	return ($score);
}


#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Print out the contents of the two files
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
sub print_file
{
	my ($md5,$parse,$score) = @_;

	open (IN,$parse) || die "Did not open $parse";
	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
#		print $line;
	}
	close IN;

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
#  Usage
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

sub usage
{
	die "Usage: $0 <md5>";
}


my $count = 0;
$score = 0;
my $num_complete =0;
my $last = 'None';
my @answer = ();
$md5 = 'None';


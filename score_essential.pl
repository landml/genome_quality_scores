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


my $infile  = "$indir/$md5.essential.out";

unless (-e $infile)
{
	exit;
	die "Does not have the input file $infile";
}

my $parse   = "$dir/essential.summary.txt";
my $score   = "$dir/essential.score.txt";

unless (-e $parse)
{
	&parse_file($md5,$infile,$parse);
}

if (-e $score && -e $parse)
{
	&print_file($md5,$parse,$score);
}
else
{
	&score_file($md5,$parse,$score);
}

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Parse each individual file
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

#	Parse each individual file
#	Initialize a hash for essential genes to be all zeros
#	Print out a line with the ID/Name, a list of counts.
#	The @ess and @codons list defines
#	the order for the headers and the output columns.
#

sub parse_file
{
	my ($md5,$infile,$parse) = @_;

#
#	List of the Models Used
#
	my $file = "/compgenpanfs/cgdb/scripts/analysis/TableS4.txt";
	open (FH,$file) || die "Did not open $file";
	my @ess;
	while (my $buf = <FH>)
	{
		chomp $buf;
		my ($model,$desc) = split(/	/,$buf);
		push(@ess,$model);
	}
	close FH;

	my %ESS;
	foreach (@ess)
	{	$ESS{$_} = 0; }

#
#	Create a tab-delimited list for the output header
#
	my $ess_list = '';
	foreach (@ess)
	{
		$ess_list .= "$_\t";
	}
	chop ($ess_list);
#
#	Create the output file and print the header line
#
	open (OUT,">$parse") || die "Did not create $parse";


	print OUT "#MD5\t$ess_list\n";
#	print "#MD5-HEADER with list of models\t$ess_list\n";

	open  (IN,$infile) || return;

	while (my $buf = <IN>)
	{
		next if ($buf =~ /^\#/);
		chomp $buf;
		next if ($buf lt '     ');

		my ($targer,$type) = split(/[ ]+/,$buf);
		unless (exists $ESS{$type})
		{
			print "Problem $file $buf\n";
			next;
		}
#		print "DEBUG: Found $type\n";
		$ESS{$type}++ ;
	}
	close IN;
	
	$ess_list = '';
	foreach (@ess)
	{
		$ess_list .= "$ESS{$_}\t";
	}
	chop ($ess_list);
	print OUT "$md5\t$ess_list\n";
#	print "$md5\t$ess_list\n";

	close OUT;
	&perm($parse,'cgdb');

}


#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Score each individual file
#
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/


sub score_file
{
	my ($md5,$parse,$score) = @_;

	open (IN,$parse) || die "Did not open $parse";
	my $line = <IN>;
	my @AA = split(/	/,$line);

	open (OUT,">$score") || die "Did not create $score";
	print OUT "#MD5\tGenus/Species\tScore\tNum Essential Genes\n";

	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
		chomp $line;
		my ($md5,@ary) = split(/	/,$line);

#		print "MD5=$md5 name=$GS{$md5}\n" ;

		my $score = 1;
		my $num_ess = 0;
		for (my $i=0; $i <=(scalar $#ary); $i++)
		{
			if ($ary[$i] > 0)
			{
				$num_ess++;
			}
			else
			{
				$score = $score - .01;
			}
		}

		$score = int(10000 * $score) / 10000;
		$score = 0 if ($score < .01);

		print OUT "$md5\tNO Name\t$score\t$num_ess\n";
#		print "$md5\tNO Name\t$score\t$num_ess\n";

	}

	close OUT;
	&perm($score,'cgdb');
}


#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
#
#	Print out the files
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

#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
sub usage
{
	die "Usage: $0 <md5>";
}
#-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/


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


my $infile  = "$indir/$md5.trna.stats";

unless (-e $infile)
{
	die "Does not have the input file $infile";
}

my $parse   = "$dir/tRNA.summary.txt";
my $score   = "$dir/tRNA.score.txt";

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

#
#	Parse each individual file
#	Initialize a hash for tRNAs and an hash for codons to be all zeros
#	The summary for the tRNAs starts after the line with Isotype
#	If the word Cove appears, you have gone too far
#	Start parsing when the region with the summary have been found
#	Split the line by space, colon, and tab
#	The codons are in an array.  Sometimes with a value, sometimes not
#	If there is a number, it is a count of the codon before it.
#	Print out a line with the ID/Name, a list of tRNA counts, and a 
#	list of codon counts.  The @trnas and @codons list define
#	the order for the headers and the output columns.
#

sub parse_file
{
	my ($md5,$infile,$parse) = @_;

#
#	Create the output file and print the header line
#
	open (OUT,">$parse") || die "Did not create $parse";

#
#	List of the tRNAs and codons.  Create default hash of each
#

	my @trnas = qw (Ala Gly Pro Thr Val Ser Arg Leu Phe Asn Lys Asp Glu His Gln Ile Met Tyr Cys Trp SelCys Supres Pseudo);
	my @codons = (
	'AAT', 'AAC', 'AAA', 'AAG', 
	'ACT', 'ACC', 'ACA', 'ACG', 
	'AGT', 'AGC', 'AGA', 'AGG', 
	'ATT', 'ATC', 'ATA', 'ATG', 
	'CAT', 'CAC', 'CAA', 'CAG', 
	'CCT', 'CCC', 'CCA', 'CCG', 
	'CGT', 'CGC', 'CGA', 'CGG', 
	'CTT', 'CTC', 'CTA', 'CTG', 
	'GAT', 'GAC', 'GAA', 'GAG', 
	'GCT', 'GCC', 'GCA', 'GCG', 
	'GGT', 'GGC', 'GGA', 'GGG',
	'GTT', 'GTC', 'GTA', 'GTG', 
	'TAT', 'TAC', 'TAA', 'TAG', 
	'TCT', 'TCC', 'TCA', 'TCG', 
	'TGT', 'TGC', 'TGA', 'TGG', 
	'TTT', 'TTC', 'TTA', 'TTG', 
	);

	my %Trna;
	my %Codon;
	foreach (@trnas)
	{	$Trna{$_} = 0; }
	foreach (@codons)
	{	$Codon{$_} = 0; }


#
#	Create a tab-delimited list for the output header
#
	my $trna_list = '';
	my $cod_list  = '';
	foreach (@trnas)
	{
		$trna_list .= "$_\t";
	}
	chop ($trna_list);
	foreach (@codons)
	{
		$cod_list .= "$_\t";
	}
	chop ($cod_list);

	print OUT "#MD5\t$trna_list\t$cod_list\n";

	open  (IN,$infile) || return;

	my $found = 'N';

	while (my $buf = <IN>)
	{
		if ($buf =~ /Isotype/)
		{
			$found = 'Y';
			next;
		}
		elsif ($buf =~ /Cove/)
		{
			$found = 'N';
		}
		next unless ($found eq 'Y');

		chomp $buf;
		next if ($buf lt '     ');

		my ($type,$count,@ary) = split(/[ :	]+/,$buf);
		for (my $i=0;$i<=$#ary;$i++)
		{
			if ($ary[$i] =~ /^\d+$/)
			{
				$Codon{$ary[$i-1]} = $ary[$i];
			}
		}
		$Trna{$type} = $count;
	}	
	close IN;
	$trna_list = '';
	$cod_list  = '';
	foreach (@trnas)
	{
		$trna_list .= "$Trna{$_}\t";
	}
	chop ($trna_list);
	foreach (@codons)
	{
		$cod_list .= "$Codon{$_}\t";
	}
	chop ($cod_list);
	print OUT "$md5\t$trna_list\t$cod_list\n";
#	print "$md5\t$trna_list\t$cod_list\n";

	close OUT;
	&perm($parse,'cgdb');

}


exit (0);

sub score_file
{
	my ($md5,$parse,$score) = @_;

	open (IN,$parse) || die "Did not open $parse";
	my $line = <IN>;
	my @AA = split(/	/,$line);

	open (OUT,">$score") || die "Did not create $score";
	print OUT "#ID\tGenus/Species\tScore\tNum trna\tNum codon\n";

	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
		chomp $line;
		my @ary = split(/	/,$line);
		my $md5 = $ary[0];

		my $num_trna = 0;
		my $score = 1;
		for (my $i=1; $i <=20; $i++)
		{
			if ($ary[$i] > 0)
			{
				$num_trna++;
			}
			else
			{
				$score = $score - .1 if ($score > .1);
			}
		}

		my $num_codon = 0;
		for (my $i=24; $i <=(scalar $#AA); $i++)
		{
			if ($ary[$i] > 0)
			{
				$num_codon++;
			}
		}
		print OUT "$md5\tNO Name\t$score\t$num_trna\t$num_codon\n";
#		print "$md5\tNO Name\t$score\t$num_trna\t$num_codon\n";

	}
	close OUT;
	&perm($score,'cgdb');
}


sub print_file
{
	my ($md5,$parse,$score) = @_;

	open (IN,$parse) || die "Did not open $parse";
	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
	#	print $line;
	}
	close IN;

	open (IN,$score) || die "Did not open $score";
	while (my $line = <IN>)
	{
		next if ($line =~ /^#/);
	#	print $line;
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



sub usage
{
	die "Usage: $0 <md5>";
}

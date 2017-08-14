use strict;
use warnings;
use FindBin qw($Bin);
use PerlIO::gzip;

die "perl $0 <kmer_freq> <min_freq> <outfile>\n" if(@ARGV!=3);
my($input,$min,$output) = @ARGV;
if($input=~/\.gz$/){
	open FI,"<:gzip",$input or die$!;
}else{
	open FI,"$input" or die $!;
}
open FO,">$output";
while(<FI>){
	chomp;
	my($kmer,$freq) = split;
	if($freq>=$min){
		print FO "$kmer\n";
	}
}
close FO;
close FI;

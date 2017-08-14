use strict;
use warnings;

die "perl $0 <out.gap> <outfile>\n" if(@ARGV==0);

my($input,$out) = @ARGV;

open FI,"$input" or die $!;
open FO,">$out" or die $!;

while(<FI>){
	chomp;
	my($est_id,$scaf_id) = (split)[1,2];
	
}

close FO;
close FI;

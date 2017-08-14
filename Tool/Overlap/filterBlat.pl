use strict;
use warnings;

die "perl $0 <score> <input>\n" if(@ARGV==0);
my($SCORE,$input)=@ARGV;
open FI,"$input" or die "$!";
while(<FI>){
	chomp;
	my  @array = split;
	next if($#array<10);
	my $score = $array[0]; #score
	my $query = $array[9];#query
	my $target = $array[13];#target
	$query =~ s/(_head$)|(_tail$)//;
	print "$query\t$target\n" if($query ne $target && $score>=$SCORE);
}
close FI;

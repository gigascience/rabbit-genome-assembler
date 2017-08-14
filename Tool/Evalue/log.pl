use strict;
use warnings;

die "perl $0 <log>" if(@ARGV==0);
my $log = shift;
open FI,$log or die $!;
open FO1,">A.lst";
open FO2,">B.lst";
while(<FI>){
	checkContain($_) if(/contains/);
	checkMerge($_) if(/merge/);
}
close FI;
close FO1;
close FO1;
##############################################
sub checkContain{
	my $line = shift;
	chomp $line;
	$line =~ /(\w+)-(\d+)\s+contains\W+(\w+)-(\d+)/;
	if($1 ne $3){
	print "$line\n";
	print FO1 "$1-$2\n";
	print FO2 "$3-$4\n";
	}
}
sub checkMerge{
	my $line = shift;
	chomp $line;
	$line =~ /(\w+)-(\d+)\s+merge\S+\W+(\w+)-(\d+)/;
	if($1 ne $3){
	print "$line\n";
	print FO1 "$1-$2\n";
	print FO2 "$3-$4\n";
	}
}
	

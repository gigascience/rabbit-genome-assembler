use strict;
use warnings;
use PerlIO::gzip;

die "perl $0 <list> <seq.fa> <out>" if(@ARGV==0);
my($lst,$seq,$out) = @ARGV;
my %hash_id;
open FI,$lst or die $!;
while(<FI>){
	chomp;
	$hash_id{$_} = 1;
}
close FI;
if($seq=~/.gz$/){
	open FI,"<:gzip",$seq;
}else{
	open FI,$seq or die $!;
}
open FO,">$out" or die $!;
while(<FI>){
	chomp;
	if(/>(\S+)/){
		my $id = $1;
		my $seq = <FI>;
		if(exists $hash_id{$id}){
			print FO ">$id\n$seq";
		}
	}
}
close FI;
close FO;
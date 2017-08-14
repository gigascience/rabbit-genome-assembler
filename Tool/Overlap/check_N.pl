use strict;
use warnings;
use PerlIO::gzip;

use constant CUT => 0.1;

die "perl $0 <seq.fa> <out>\n" if(@ARGV==0);
my($input,$out) = @ARGV;

if($input=~/.gz$/){
	open FI,"<:gzip",$input or die $!;
}else{
	open FI,$input or die $!;
}

open FO,">$out";
my $base = 0;
while(<FI>){
	if(/^>(\S+)/){
		my $id = $1;
		my $seq = <FI>;
		chomp $seq;
		my $num_N = ($seq =~ tr/Nn/Nn/);
		my $seq_len = length($seq);
		my $prop = $num_N/$seq_len;
		if($prop <= CUT){
			$base+=$seq_len;
		}
		print FO "$id\t$prop\n";
	}
}
print FO "usable base:$base\n";
close FO;
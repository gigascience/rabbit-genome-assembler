use strict;
use warnings;

die "perl $0 <bac.fa> <read_len> <outfile>\n" if(@ARGV==0);
my($bac,$len,$file)=@ARGV;

open FO,">$file" or die $!;
open FI,$bac or die $!;
while(<FI>){
	if(/^>(\S+)/){
		my $id=$1;
		my $seq = getSeq(*FI);
		$seq = uc($seq);
		my $head = substr($seq,0,$len);
		if($head !~/N/ && length($head)==$len){
			 print FO ">${id}_head\n$head\n";
		}
		my $tail = substr($seq,-$len,$len);
		print FO ">${id}_tail\n$tail\n" if($tail !~/N/ && length($tail)==$len);
	}
}
close FI;
close FO;

################################################################
######################### subroutine ###########################
################################################################
sub getSeq{
	my $fh = shift;
	my $seq = "";
	while(<$fh>){
		if(/^>/){
			seek($fh,-(length($_)+1),1);
			last;
		}else{
			chomp;
			$seq .= $_;
		}
	}
	return $seq;
}

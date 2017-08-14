use strict;
use warnings;

die "perl $0 <bac.fa> <reads.fa> <read_len> <outfile>\n" if (@ARGV==0);

my($bac,$reads,$rd_len,$out)=@ARGV;
my (%hash_read);

# load reads as kmer
print STDERR "loading reads\n";
open FI,"$reads" or die $!;
while(<FI>){
	chomp;
	if(/^>(\S+)/){
		my $id=$1;
		my $seq = getSeq(*FI);
		$seq = uc($seq);
		if(!exists $hash_read{$seq}){
			$hash_read{$seq}="";
		}
		$hash_read{$seq} .= "$id\t";
	}
}
close FI;

# load bac
open FO,">$out" or die $!;
open FI,"$bac" or die $!;
while(<FI>){
	if(/^>(\S+)/){
		my $id=$1;
		my $seq = getSeq(*FI);
		$seq = uc($seq);
		my $len = length($seq);
		my %hash_id;
		for(my $i=0;$i<=$len-$rd_len;$i++){
			my $tmp = substr($seq,$i,$rd_len);
			my $tmp_r = &reverse($tmp);
			if(exists $hash_read{$tmp}||exists $hash_read{$tmp_r}){
				$tmp = (exists $hash_read{$tmp})?$tmp:$tmp_r;
				my @ids = split(/\t/,$hash_read{$tmp});
				foreach(@ids){
					s/_head//g;
					s/_tail//g;
					$hash_id{$_} = 1;
				}
			}
		}
		foreach(keys %hash_id){
			print FO "$_\t$id\n" if($_ ne $id);
		}
	}
}
close FI;
close FO;







#########################################################################
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

# my $seq = reverse($ref);
sub reverse{
	my $ref = shift;
	$ref =~ tr/ATGCN/TACGN/;
	$ref = reverse($ref);
	return $ref;
}

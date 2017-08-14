use strict;
use warnings;
use PerlIO::gzip;

die "perl $0 <scaf.lst> <min_len> <max_len> <N_percent> <trim_end> <out>\n" if(@ARGV==0);
my($list,$min_len,$max_len,$n_percent,$trim_end,$out) = @ARGV;

open LIST,"$list" or die $!;
open FO,">$out" or die $!;
while(<LIST>){
	chomp;
	my $fa = $_;
	if($fa=~/.gz$/){
		open FI,"<:gzip",$fa or die $!;
	}else{
		open FI,$fa or die $!;
	}
	my $line = <FI>;
	$line =~ /^>(\S+)/;
	my $id = $1;
	while($id ne ""){
		my($seq,$next_id) = ("","");
		&getSeq1(*FI,\$seq,\$next_id);
		$seq = substr($seq,$trim_end,length($seq)-2*$trim_end) if(length($seq)>2*$trim_end);
		my $head = substr($seq,0,500);
		while($head=~/N/ && length($seq)>500){
			$seq = substr($seq,50);
			$head = substr($seq,0,500);
		}
		my $tail = substr($seq,-500,500);
		while($tail=~/N/ && length($seq)>500){
			$seq=substr($seq,0,length($seq)-50);
			$tail = substr($seq,-500,500);
		}
		my $len = length($seq);
		my $n_num = ($seq =~ tr/N/N/);
		my $n_per = ($len>0)? $n_num/$len:0;
		if($n_per<$n_percent && $len>$min_len && $len<$max_len){
			print FO ">$id\n$seq\n";
		}
		$id = $next_id;
	}
	close FI;
	print STDERR "format fasta file finished\n";
}
close LIST;
close FO;



sub getSeq1{
	my($fh,$seq,$next_id) = @_;
	while(<$fh>){
		if(/^>(\S+)/){
			${$next_id} = $1; 
			last;
		}else{
			s/\s+//g;
			${$seq}.= uc($_);
		}
	}
}


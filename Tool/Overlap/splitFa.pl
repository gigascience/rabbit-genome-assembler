use strict;
use warnings;
use PerlIO::gzip;
die "perl $0 <seq.fa> <seq_base> <trim_len> <prefix> <trim_end> <N_percent>" if(@ARGV==0);
my($seq,$base_num,$trim_len,$prefix,$trim_end,$N_per) = @ARGV;
$trim_end ||= 0;
$N_per ||= 0.5;
print STDERR "trim end:$trim_end\n";

my $file_id=0;
my $filename="${prefix}_$file_id.fa";
my $base=0;
if($seq=~/.gz$/){
	open FI,"<:gzip",$seq or die $!;
}else{
	open FI,$seq or die $!;
}
open FO,">$filename" or die $!;
while(<FI>){
	if(/^>(\S+)/){
		my $id = $1;
		my $seq = getSeq(*FI);
		my $seq_len = length($seq);
		my $num_N = ($seq =~ tr/Nn/Nn/);
		my $prop = $num_N/$seq_len;
		next if(length($seq)<$trim_len||$prop>$N_per);
		$base += $seq_len;
		if($base >$base_num){
			$base = 0;
			close FO;
			$file_id++;
			my $filename="${prefix}_$file_id.fa";
			open FO,">$filename" or die $!;
		}
		print FO ">$id\n$seq\n";
	}
}
close FI;
close FO;

###############################subroutine########################
sub getSeq{
	my $fh = shift;
	my $seq = <$fh>;
	chomp $seq;
	$seq = uc($seq);
	$seq = substr($seq,$trim_end,length($seq)-2*$trim_end) if(length($seq)>2*$trim_end);
	my $head = substr($seq,0,101);
	while($head=~/N/&&length($seq)>100){
		$seq=substr($seq,50);
	}
	my $tail = substr($seq,-101,101);
	while($tail=~/N/&&length($seq)>100){
		$seq=substr($seq,0,length($seq)-50);
	}
	return $seq;
}

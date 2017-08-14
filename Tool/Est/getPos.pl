use strict;
use warnings;

die "$0 <input> <output>\n" if(@ARGV==0);
my($input,$output) = @ARGV;
my $tag = "CCTGCAGG";
if($input=~/.gz/){
	open FI,"<:gzip",$input or die;
}else{
	open FI,$input or die $!;
}
open FO,">$output" or die $!;
my $num = 1;
my $line = <FI>;
$line =~ /^>(\S+)/;
my $id = $1;
while($id ne ""){
	my($seq,$next_id) = ("","");
	&getSeq1(*FI,\$seq,\$next_id);
	#process sequence
	my $pos = index($seq,$tag,0);
	while($pos!=-1){
		my $start = ($pos>=100)?$pos-100:0;
		my $subseq = substr($seq,$start,206);
		print FO ">${id}_$start\n$subseq\n";
		$pos = index($seq,$tag,$pos+1);
	}
	$id = $next_id;
}
close FO;
close FI;
print STDERR "format fasta file finished\n";

sub getSeq1{
	my($fh,$seq,$next_id) = @_;
	while(<$fh>){
		if(/^>(\S+)/){
			${$next_id} = $1; 
			last;
		}else{
			s/\s+//g;
			${$seq}.= $_;
		}
	}
}
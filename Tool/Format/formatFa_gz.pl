use strict;
use warnings;
use PerlIO::gzip;

die "perl $0 <seq.fa> <id_prefix> <out>\n" if(@ARGV==0);
my($fa,$prefix,$out) = @ARGV;
if($fa=~/.gz/){
	open FI,"<:gzip",$fa or die;
}else{
	open FI,$fa or die $!;
}
open FO,">$out" or die $!;
my $num = 1;
my $line = <FI>;
$line =~ /^>(\S+)/;
my $id = $1;
while($id ne ""){
	$id = $prefix."_$num";
	$num++;
	my($seq,$next_id) = ("","");
	&getSeq1(*FI,\$seq,\$next_id);
	print FO ">$id\n$seq\n";
	$id = $next_id;
}
close FO;
close FI;
print STDERR "format fasta file finished\n";

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

 #!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin $Script);
use Getopt::Long;

=head1 Name

	findCom.pl --find potential connection between sequences using Linux SGE system.

=head1 Version

	Author: zhandongliang, zhandongliang@genomics.org.cn
	Version: 1.0,  Date: 2011-11-21
  
=head1 Usage

	perl findCom.pl <fasta> <output>
	--head_len<num>		the length of head.
	--ignore		ignore the sequence with the length is shorter than head_len 
	--scope<num>		the scope to find relation between sequence, default is -1(all).
	--score<num>		the match num of the sequence.
	--thread<num>		the number of jobs running,default is 10.
	--queue<str>		the queue(-q) to submit jobs.
	--project<str> 		the project(-P) to submit jobs.
	
=head1 Example
	
	perl findCom.pl bac.fa relation.lst --head_len 1000 --scope 2000  --score 1500 --thread 50 --queue bc_mem.q --project bc_mem
	
=cut

my($head_len,$ignore,$scope,$seed_len,$score,$thread,$queue,$project);
GetOptions(
	"head_len:i"=>\$head_len,
	"ignore"=>\$ignore,
	"scope:i"=>\$scope,
	"score:i"=>\$score,
	"thread:i"=>\$thread,
	"queue:s"=>\$queue,
	"project:s"=>\$project
);

die `pod2text $0` if (@ARGV == 0 || !defined $queue);

my($bac,$output) = @ARGV;
print STDERR "$bac\t$output\n";

$thread ||=20;
my $DEVIDE_SIZE = 50000000;
my $pwd = `pwd`;
my $name_end = "read$$.fa";
my ($file_id,$base_now,@files) = (0,0);
my $filename="Files$$/split_${file_id}.fa";
chomp $pwd;
mkdir("Files$$");

my($read_base,$seq_base) = (0,0);

# default setting
$head_len ||= 500;
$scope ||= -1;
$thread ||= 10;
$score ||= 0.8*$head_len;
my $step_size = int($head_len/50);
print STDERR "$head_len\t$step_size \n";

my $qsub_info = "--queue $queue ";
$qsub_info .= " --project $project" if(defined $project);

# software
my $BUILD = "$Bin/lastdb ";
my $LAST = "$Bin/lastal " ;
my $BLAT = "$Bin/blat ";

#get reads from bac sequence
print STDERR "begin to get reads\n";
open FI,"$bac" or die $!;
open FO,">$name_end" or die $!;
open SPLIT,">$filename" or die $!;

while(<FI>){
	if(/>(\S+)/){
		my $id = $1;
		my $seq = &getSeq(*FI);
		next if(length($seq)<$head_len && defined $ignore);# ignore short sequences
		
		my $head = substr($seq,0,$head_len);
		my $tail = substr($seq,-$head_len,$head_len);
		print FO ">${id}_head\n$head\n>${id}_tail\n$tail\n";
		
		$read_base += length($head)+length($tail); #for counting memory
		
		if($base_now >$DEVIDE_SIZE){
			$base_now = 0;
			close SPLIT;
			push(@files,$filename);
			$file_id++;
			$filename="Files$$/split_${file_id}.fa";
			open SPLIT,">$filename" or die $!;
		}
		if($scope == -1){
			print SPLIT ">$id\n$seq\n";
			$base_now += length($seq);
		}else{
			$head = substr($seq,0,$scope);
			$tail = substr($seq,-$scope,$scope);
			print SPLIT ">$id\n$head\n$id\n$tail\n";
			$base_now += 2*$scope;
		}
	}
}
close FI;
close SPLIT;
push(@files,$filename);
close FO;

#compare each files using blat
my $memory = 0.5;
my @result;
foreach(@files){
	`echo "$BLAT  $pwd/$_ $name_end  /dev/stdout -tileSize=18 -stepSize=$step_size -maxGap=20  -minMatch=30 -minScore=$score  -noHead -extendThroughN|perl $Bin/filterBlat.pl $score /dev/stdin >$pwd/$_.lst" >> cmp$$.sh`; 
	push(@result,"$pwd/$_.lst");
}
`perl $Bin/qsub-sge.pl --jobprefix Rabit_cmp $qsub_info --resource vf=${memory}G  cmp$$.sh`;
`cat @result > $output && rm -r $name_end Files$$`;

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
			$seq .= uc($_);
		}
	}
	return $seq;
}



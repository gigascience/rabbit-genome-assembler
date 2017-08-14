die "perl <last.tab> <out>\n" if(@ARGV==0);
my($last,$out) = @ARGV;
open FI,"$last" or die $!;
open FO,">$out" or die $!;
while(<FI>){
	chomp;
	my($score,$name1,$name2)=(split)[0,1,6];
	if($score>500 && $name1 ne $name2){
		print FO "$score\n";
	}
}
close FO;
close FI;

`sort -o $out -k 1,1n  $out`;

open FI,"$out" or die $!;
my $dead_line = 600;
my $num = 0;
my $gap = 500;
while(<FI>){
	chomp;
	if($_ < $dead_line){
		$num++;
	}else{
		my $begin = $dead_line-$gap;
		print "$begin-$dead_line\t$num\n";
		$num = 1;
		$dead_line+=$gap;
	}
}
 my $begin = $dead_line-$gap;
 print "$begin-$dead_line\t$num\n";
close FI;

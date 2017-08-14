die "perl $0 <*.log> <cds.fa> <outfile> <percentage:0.9>\n" if(@ARGV==0);
my($log,$input,$outfile,$percent) = @ARGV;
$percent ||= 0.9;
my %gene_arr;
open FI,"$log" or die $!;
while(<FI>){
	chomp;
	my($operation,$id) = (split)[0,1];
	if($operation eq "abandon"){
		$gene_arr{$id} = 1;
	}
}
close FI;

my %hash_scaf,%hash_num;
open FI,"$input" or die $!;
while(<FI>){
	chomp;
	if(/>(\w+)\s+locus=(\w+):/){
		my $gene = $1;
		my $scaf = $2;
		if(!exists $hash_num{$scaf}){
			$hash_num{$scaf} = 0;
		}
		$hash_num{$scaf} += 1;
		if(exists $gene_arr{$gene}){
			if(!exists $hash_scaf{$scaf}){
				$hash_scaf{$scaf} = 0;
			}
			$hash_scaf{$scaf} += 1;
		}
	}
}
close FI;

open FO,">$outfile" or die $!;
open FO1,">$outfile.lst" or die $!;
my $confirm = 0;
foreach(keys %hash_scaf){
	my $trim_num = $hash_scaf{$_};
	my $gene_in_scaf = $hash_num{$_};
	print FO "$_\t$hash_scaf{$_}\t$hash_num{$_}\n";
	if($trim_num/$gene_in_scaf>=$percent){
		$confirm += $trim_num ;
		print FO1 "$_\n";
	}
}
print FO "confirm num(col.2/col.3>=$percent)\t$confirm\n";
close FO;
close FO1;

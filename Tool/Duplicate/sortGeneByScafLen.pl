die "perl $0 <cds.fa> <scaff_len.lst> <outfile>\nThis program is used to sort the gene by the scaffold len\n" if(@ARGV==0);
my($cds,$list,$out) = @ARGV;
open FI,"$cds" or die $!;
my %hash_scaf;	#key:scaf	value array of genes
while(<FI>){
	if(/>(\w+)\s+locus=(\w+):/){
		my $gene = $1;
		my $scaf = $2;
		if(!exists $hash_scaf{$scaf}){
			my @array;
			$hash_scaf{$scaf} = \@array;
		}
		push(@{$hash_scaf{$scaf}},$gene);
	}
}
close FI;

open FI,"$list" or die $!;
open FO,">$out" or die $!;
while(my $scaf_id = <FI>){
	chomp $scaf_id;
	$scaf_id = (split(/\s+/,$scaf_id))[0];
	next unless(exists $hash_scaf{$scaf_id});
	foreach my $gene(@{$hash_scaf{$scaf_id}}){
		print FO "$gene\n";
	}
}
close FI;
close FO;
die "perl $0 <more.lst> <less.lst>\n" if(@ARGV==0);
my($more,$less) = @ARGV;
open FI,"$less" or die $!;
%hash;
while(<FI>){
	chomp;
	$hash{$_} = 1;	
}
close FI;

open FI,"$more" or die $!;
while(<FI>){
        chomp;
	print "$_\n"  unless(exists $hash{$_});
}
close FI;


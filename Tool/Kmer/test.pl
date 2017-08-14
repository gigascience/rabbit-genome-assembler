use strict;
use warnings;
# translate dna base to bit code
use constant WIDTH =>2;
my %bit_codes = (
	A => 0b00,
	C => 0b01,
	G => 0b10,
	T => 0b11,
);
@bit_codes{values %bit_codes} = keys %bit_codes;

# main
my $kmer = "AAAAAAAAATTTGGAGTCCCG";
my $bits = &kmer2bit($kmer);
my $bits_r = get_reverse_complement_kbit($bits,length($kmer));
my $str = &bit2kmer($bits_r,length($kmer));
print "$kmer\n$str\n";

####################### subroutine ################# 
sub kmer2bit{
	my @bases = split //,shift;
	my $bits = '';
	foreach my $i (0 .. $#bases){
		vec($bits,$i,WIDTH) = $bit_codes{$bases[$i]};
	}
	return $bits;
}

sub bit2kmer{
	my ($bits,$len) = @_;
	my $kmer = '';
	for(my $i=0;$i<$len;$i++){
		my $base = $bit_codes{vec($bits,$i,WIDTH)};
		$kmer .= $base;
	}
	return $kmer;
}

sub get_reverse_complement_kbit{
	my ($bits,$len) = @_;
	my $bits_cp = $bits;
	for(my $i=0;$i<int($len/2);$i++){
		vec($bits,$i*WIDTH,WIDTH) = vec($bits,($len-1-$i)*WIDTH,WIDTH);
		vec($bits,($len-1-$i)*WIDTH,WIDTH) = vec($bits_cp,$i*WIDTH,WIDTH);
	}
	return $bits;
}
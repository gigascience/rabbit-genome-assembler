use strict;
use warnings;
use List::Util qw(min);

# constant
use constant LEFT => -1;
use constant RIGHT => 1;
use constant INTERVAL => 12;

die "perl $0 <bac.fa> <reads.fa> <seed_len>  <mismatch <10> <outfile>\n" if (@ARGV==0);

my($bac,$reads,$seed_len,$mismatch,$out)=@ARGV;
if($mismatch>=10){
	$mismatch = 4;
	print STDERR "<mismatch> must less than 10\nset mistmatch:4 now\n";
}
# hash_read:id->@array
#	@array:seed\t$start
#hash_seed:seed->@array
#	@array:read_id\t$start\t$symbol(+|-)
my (%hash_readSeed,%hash_seedRead);
$seed_len ||= 31;
# load reads
print STDERR "loading reads\n";
open FI,"$reads" or die $!;
while(<FI>){
	chomp;
	if(/^>(\S+)/){
		my $id=$1;
		my $seq = getSeq(*FI);
		my $seq_len = length($seq);
		my $inter = $seq_len/INTERVAL;
		my @array;
		for(my $i=0;$i<$seq_len-$seed_len;$i+=$inter){
			my $seed = substr($seq,$i,$seed_len);
			next if($seed=~/N/);
			my $symbol;
			$seed = getMin($seed,$symbol);
			my $seed_info = "$seed\t$i\t$symbol";
			push(@array,$seed_info);
		}
		$hash_readSeed{$id} = \@array;
	}
}
close FI;

# get kmers from reads as seed
print STDERR "getting seeds\n";
while(my($id,$array_ref) = each %hash_readSeed){
	my @array = @{$array_ref};
	for(my $i=0;$i<=$#array&&$i<$mismatch;$i++){ # mismatch keys for each sequence
		my($seed,$start,$symbol) = split(/\t/,$array[$i]);
		if(exists $hash_seedRead{$seed}){
			push(@{$hash_seedRead{$seed}},"$id\t$i\t$symbol");
		}else{
			my @new_array;
			push(@new_array,"$id\t$i\t$symbol");
			$hash_seedRead{$seed} = \@new_array;
		}
	}
}

# load bac
print STDERR "getting comparing..\n";
open FO,">$out" or die $!;
open FI,"$bac" or die $!;
while(<FI>){
	if(/^>(\S+)/){
		my $seq_id=$1;
		my $seq = getSeq(*FI);
		my $seq_len = length($seq);
		my (%hash_id,%hash_kmer,%hash_dumn);
		# put each kmer into hash to increase speed.
		for(my $begin=0;$begin<=$seq_len-$seed_len;$begin++){
			my $tmp = substr($seq,$begin,$seed_len);
			my $sym_kmer;
			my $seed = getMin($tmp,$sym_kmer);
			next if($seed=~/N/);
			if(exists $hash_kmer{$seed}){
				$hash_kmer{$seed} .= "$begin\t$sym_kmer|";
			}else{
				$hash_kmer{$seed} = "$begin\t$sym_kmer|";
			}
		}
		foreach my $kmer (keys %hash_kmer){# kmer
			my $array_read_ref = $hash_seedRead{$kmer}; # kmer对应的reads
			next unless(defined $array_read_ref);
			my @pos_kmer = split(/|/,$hash_kmer{$kmer}); #kmer的位置
			foreach my $read_info(@{$array_read_ref}){#process each read
				my($read_id,$i,$seed_sym) = split(/\t/,$read_info);
				my $seq_id_tail = $seq_id+"_tail";
				my $seq_id_head = $seq_id+"_head";
				next if(exists $hash_dumn{$read_id}||exists $hash_id{$read_id}||$seq_id_tail eq $read_id||$seq_id_head eq $read_id);
				my $mis;
				foreach(@{$hash_readSeed{$read_id}}){
					my($seed,$pos,$symbol) = split;
					$mis++ unless(exists $hash_kmer{$seed});
					if($mis>$mismatch){
						$hash_dumn{$read_id} = 1;
						last;
					}
				}
				if($mis<=$mismatch){
					$read_id =~ s/(_head$)|(_tail$)//;
					print FO "$read_id\t$seq_id\n";
					$hash_id{$read_id} = 1;
				}
			}
		}
	}
}
close FI;
close FO;

#########################################################################
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

# my $seq = reverse($ref);
sub reverse{
	my $ref = shift;
	$ref =~ tr/ATGCN/TACGN/;
	$ref = reverse($ref);
	return $ref;
}

# my $seq = getMin($seq,\$reverse);
sub getMin{
	my $seq = shift;
	my $reverse = shift;
	my $seq_r = &reverse($seq);
	if($seq gt $seq_r){
		$seq = $seq_r;
		${$reverse} = 1;
	}else{
		${$reverse} = -1;
	}
	return $seq;
}

# judge if the seeds are in the seq
sub isMatch{
	my($seq1_ref,$seq2_ref,$mismatch) = @_;
	my $seq1_len = length(${$seq1_ref});
	my $seq2_len = length(${$seq2_ref});
	return -1 if($seq1_len>$seq2_len);
	return 1 if(${$seq1_ref} eq ${$seq2_ref});
	#kmers in seq1
	my $interval = $seq1_len/10;
	my $mis_num = 0;
	my $k = 21;
	for(my $i=0;$i<=$seq2_len-$k;$i+=$interval){
		my $query = substr(${$seq1_ref},$i,$k);
		$mis_num++ if(index(${$seq2_ref},$query,0)==-1);
	}
	return 1 if($mis_num <= $mismatch);
	return -1;
}

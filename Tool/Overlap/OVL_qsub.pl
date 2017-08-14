#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use File::Basename;
use List::Util qw(max);

die "perl $0 <ovl.cfg>\n" if(@ARGV==0);
my $input = shift;

# global variables
my($bac,				# input sequence file
   $recur,				# recurcive number of doing assembly
   $size,				# genome size, stop when the file size <= genome size
   $thread,				# the number of computer node needed in finding the relationship
   $trim_len,			# trim sequences which length < trim_len
   $trim_end,			# trim sequence end because the end's quality usually lower
   $DEVIDE,				# divide the sequence file into several files to save memory(bp),note that the size must >=50M
   $memory_ovl,			# the memory(G) set to qsub
   $qsub_ovl,			# the overlap qsub command
   $qsub_find,			# the qsub command of find relation
);
my @strategy;			# the overlap strategies 

# initial working varibles
parseCfg($input); 		# parsing the config file
my $COUNTER = 0;		# the file number to avoid file being covered.
my $pwd = `pwd`;		# working directory
chomp $pwd;				
my $basename = "l_".basename($bac);
system("ln -s $bac $pwd/$basename");
my $pre = "$pwd/$basename";	# the file that is being process and will be deleted.

# generate clean shell
`echo "rm -r *.trim Files* *.log *split* *.fa.sh cmp*.sh reads*.fa *.repeat" >clean.sh`;

# core process
my $devide_size = $DEVIDE;
for(my $i=0;$i<$recur;$i++){
	foreach my $cfg(@strategy){	
		while(1){
			my $file_size = (stat $pre)[7];	
			last if($file_size <= $size);
			&assembleFile($pre,$cfg,$devide_size);
			last if($devide_size>$file_size);
			$devide_size *=2 if($file_size>$devide_size);
		}
	}
	# terminate if filesize less than genome size
	my $file_size = (stat $pre)[7];
	print STDERR "recurcive time: $i\n";
	last if($file_size <= $size);
	$devide_size = 2*$DEVIDE;
}

# clean up the workplace
system("sh clean.sh");
mkdir("Evidence");
mkdir("Evidence/Evi$$");
system("mv *.evidence Evidence/Evi$$");

######################################################################################################################################
######################################################################################################################################
sub parseCfg{# parseCfg($input)
	my $input = shift;
	open FI,"$input" or die $!;
	while(<FI>){
		chomp;
		my $line = $_;
		my @values = split;
		$bac=$values[1] if($values[0] eq "[sequence]");
		$recur=$values[1] if($values[0] eq "[recursive]");
		$size=$values[1] if($values[0] eq "[genome_size]");
		$thread=$values[1] if($values[0] eq "[cpu]");
		$trim_len=$values[1] if($values[0] eq "[min_len]");
		$trim_end=$values[1] if($values[0] eq "[trim_end]");
		$DEVIDE=$values[1] if($values[0] eq "[devide_size]");
		# queue information
		if($values[0] eq "[find_queue]"){
			my($name,$queue,$project) = @values;
			$qsub_find .= "--queue $queue " if(defined $queue);
			$qsub_find .= "--project $project " if(defined $project);
		}
		if($values[0] eq "[overlap_queue]"){
			my($name,$queue,$project,$memory) = @values;
			$qsub_ovl .= "--queue $queue " if(defined $queue);
			$qsub_ovl .= "--project $project " if(defined $project);
			if(defined $memory){
				$memory_ovl = $memory;
				$memory_ovl =~ s/[GgmM]//;
			}else{
				$memory_ovl = 0;
			}
		}
		# strategy
		push(@strategy,$line) if($values[0] eq "[ovl]");
	}
	close FI;
	$thread ||= 1;
	$trim_len ||= 1000;
	$trim_end ||= 0;
	$DEVIDE=100000000 if($DEVIDE < 50000000); # 50M
	print STDERR "[sequence]\t$bac\n";
	print STDERR "[recursive]\t$recur\n";
	print STDERR "[genome_size]\t$size\n";
	print STDERR "[cup]\t$thread\n";
	print STDERR "[min_len]\t$trim_len\n";
	print STDERR "[trim_end]\t$trim_end\n";
	print STDERR "[devide_size]\t$DEVIDE\n";
	print STDERR "[find_queue]\t$qsub_find\n";
	print STDERR "[overlap_queue]\t$qsub_ovl\t$memory_ovl\n";
}

sub splitFile{
	my($file,$divide_base) = @_;
	`perl $Bin/splitFa.pl $file $divide_base $trim_len bac_split$$ $trim_end && rm $file`;
	my $line = `ls bac_split$$*.fa`;
	my @files = split(/\n/,$line);
	return @files;
}

sub assembleFile{
	my($file,$cfg,$devide_size) = @_;
	my @files = &splitFile($file,$devide_size);
	my $cpu_num = ($thread/($#files+1)>1)?int($thread/($#files+1)):1;
	my @tmp;
	`rm SHELL.SH` if(-e "SHELL.SH");
	foreach(@files){
		my $out = config($_,"$_.sh",$cfg,$cpu_num); # generate script file for each file
		push(@tmp,$out);
		`echo "sh $_.sh" >>SHELL.SH`;
	}
	`perl $Bin/runScript_local.pl SHELL.SH $thread`;
	`cat @tmp > final$$.fa && rm @tmp`;
	$pre = "final$$.fa";
}

sub config
#generate script shell:
#shell:
#	findCom.pl
#	qsub overlap.sh
#overlap.sh:
#	overlap
{
	my($file,$shell,$cfg,$cpu_num)=@_;
	$COUNTER++;
	my(
	$program,			# overlap program
	$seek_len,			# use two ends of a sequence as seed to find other sequences that have overlap with it
	$score,				# cut off of the match length of seek_len
	$merge_prop,		# connect two sequences when similarity >merger_prop
	$trim_prop,			# trim sequence when similarity <trim_prop
	$out_pre,			# the output file's prefixes
	) = split(/\s+/,$cfg);
	$program = "$Bin/overlap";
	my $out = "$out_pre-$COUNTER";
	my $outfile = "$out_pre-$COUNTER.fa";
	
	`echo "perl $Bin/findCom.pl $pwd/$file  $pwd/$file.lst  --head_len $seek_len --score $score  --thread $cpu_num $qsub_find" >$shell`;	#get relation in qsub
	`echo "$program -i $pwd/$file -r $pwd/$file.lst -m $merge_prop -t $trim_prop -o $pwd/$out && rm $pwd/$file $pwd/$file.lst" > $file-ovl.sh`;
	
	my $seq_size = (stat $file)[7];
	my $memory = 3*$seq_size/1000000000;
	$memory_ovl = max($memory,$memory_ovl);
	`echo "perl $Bin/qsub-sge.pl --jobprefix vol $qsub_ovl  --interval 100  --resource vf=${memory_ovl}G $file-ovl.sh">>$shell`;
	return $outfile;
}

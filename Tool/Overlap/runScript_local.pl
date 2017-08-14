use strict;
use warnings;

die "perl $0 <script> <max_jobs>\n" if(@ARGV<2);
my($script,$max_jobs) = @ARGV;
my (@jobs,%run_jobs);
my $log = "job_$$.log";
`touch $log`;

open JOBS,"$script" or die "can't open $script\n";
while(<JOBS>){
	chomp;
	push(@jobs,$_);
}
close JOBS;

my $run_jobs = 1;
my $count = 0;
while(@jobs || $count>0){
	if($count<$max_jobs && @jobs!=0){
		my $job = shift @jobs;
		$job .= " && echo job_$run_jobs >> $log";
		$run_jobs{"job_$run_jobs"}=1;
		system("$job &");
		$run_jobs++;
		$count++;
	}else{
		open LOG,"$log" or die "can't not open $log";
		while(<LOG>){
			chomp;
			if(exists $run_jobs{$_}){
				delete $run_jobs{$_};
				$count--;
			}
		}
		close LOG;
		sleep 5;
	}
}
`rm $log`;

use strict;
use warnnings;
use FindBin qw($Bin $Script);

die "perl <input.fa> <output> <queue> <project>\n" if(@ARGV==0);
my($input,$output,$queue,$project) = @ARGV;

# find overlap of ends
`perl $Bin/findCom.pl $input red$$.lst --head_len 500 --scope 500 --score 450 --thread 50 --queue $queue --project $project`;

# 
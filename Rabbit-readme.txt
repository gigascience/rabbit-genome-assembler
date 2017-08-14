Author: Dongliang Zhan, zhandongliang@genomics.org.cn
Version: 2.1, Date: 2012-4-12

This package contains three main modules:
1.Jellyfish:    a very useful k-mer counter program.
2.Overlaper:    an assembly software suitable for long sequences (>2kb).
3.TrimDup:      a module using the k-mer statistics to remove redundancy.

/////////////////////////////////Jellyfish////////////////////////////////////////////
1. You can download jellyfish from http://www.cbcb.umd.edu/software/jellyfish/
2. Change the config file in the Tool Directory.
3. Then you can use Tool/Kmer/kmer_counter.pl to generate a k-mer counter script.

/////////////////////////////////Overlaper////////////////////////////////////////////
This is a overlap assembler using blat to find overlap between sequences.
1. You have to install blat in your computer and link it in the Tool/Overlap directory.
2. This software uses SGE system to submit jobs.
3. Before you use the software, you have to format the input:
  3.1 Cat files into one file and filter the low quality sequences.
      perl Tool/Format/mergeFiles.pl  <scaf.lst> <min_len> <max_len> <N_percent> <trim_end> <out>
  3.2 Make sure every ID is unique in the file,or u can use the script
      perl Tool/Format/formatFa_gz.pl <seq.fa> <id_prefix> <out>
4. Edit the assembly config file in the format like Tool/Overlap/ovl.cfg:
  [sequence]      fosmid.fa
  [recursive]     1
  [genome_size]   12000000
  [cpu]   30
  [min_len]       2000
  [trim_end]      40
  [devide_size]   100000000
  [find_queue]    bc.q    test
  [overlap_queue] bc.q    test
  [ovl]   5001    4000    0.9   0.9  ov_5001
  [ovl]   3001    2500    0.9   0.9  ov_3001
  [ovl]   301     301     0.9   0.9  ov_301
  4.1 description:
  [sequence]:   the input sequence, must in format
  [recursive]:  recursive time
  [genome_size]:when the assembly result is less than this, the program will exit.
  [cpu]:        the max jobs to submit to sge.
  [min_len]:    the sequence which length < min_len will to remove.
  [trim_end]:   trim both end of sequences
  [devide_size]:split input file into devide_size to reduce the complicated of assembly and save memory and disk.
  [find_queue]: col.1 is the queue of sge "-q", col.2 is the project name,"-P".
  [overlap_queue]:the qsub information of assembly like find_queue.
  [ovl]:        col.1 cut both end of sequence with length of col.1 to do alignment, col.2 if the match length >=col.2 then record the relation.
                col.1 and col.2 is used for finding the overlap between sequence.
                col.3 connect the sequence with another if the common percent is larger or equal col.3
                col.4 remove the sequence if this sequence has similarity greater or equal to col.4
                col.5 the output prefix.
5. Now you can run the overlap program: perl Tool/Overlap/OVL_qsub.pl ovl.cfg 2>log&
6. You can see the example in Example/Assemble directory.

///////////////////////////////////////////TrimDup/////////////////////////////////////////////////////////////////////////////////////
This program is used to remove redundancy with the statistics of k-mer from WGS reads.
You can use this program to remove redundant scaffolds and genes.
1. First you have to run jellyfish to get k-mer occurrence frequency table, >=20X data are recommended.
2. Then use the program to remove sequences, note that k=16 is recommended and the memory is 8G+sequence_size.
  Tool/Duplicate/TrimDup <kmer_table> <kmer_size> <max_occ> <scaf.fa> <out_prefix> <percentage>

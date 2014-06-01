package HyTestStats;
use strict;
use Moose;
require 'hydlib.pl';
use File::Slurp;
use File::Copy;

#create the HyTestStats object when starting the process, just after the Hytest is created - need its ref
#update it with each job/itteration
#use it to write the stat for itteration to stats ...
#use it to get back the info for the 'approved' job

#where the stats need to be collected to
has 'statspath'=>(isa => 'Str', is => 'rw', required =>1);

#what is the HyTest set collecting stats about
has 'configname'=>(isa => 'Str', is => 'rw', required =>1);
has 'jobset'=>(isa => 'Str', is => 'rw', required =>1);
has 'hytest'=>(isa => 'Ref', is => 'rw', required =>1);
has 'testname'=>(isa => 'Str', is => 'rw', required =>0);
has 'itteration'=>(isa => 'Int', is => 'rw', required =>0);
has 'elapsedtime'=>(isa => 'Num', is => 'rw', required =>0);

#who is running it
has 'username'=>(isa => 'Str', is => 'rw', required =>0);

#and some hydstra info
has 'ini'=>(isa => 'Any', is => 'rw', required =>0);
has 'hydlogtext'=>(isa => 'Str', is => 'rw', required =>0); #optionally slurp the hydlog and ...

1;
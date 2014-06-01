=setup
[Configuration]
ListFileExtension = HTM

[Window]
Name = PER
Head = HYTEST - User Test Harness

[Labels]
TSS0  = END  130 11 .
TESTPATH	= END   31 11 Tests Folder
TESTS 		= END   31 +1 Tests to Run
TSS1  		= START 41 +1 (Test pattern, * for all or hyday or hyday_01 or 0 for no tests)
LDEST 		= END   31 +2 Approved Subdir
RDEST 		= END   31 +1 Test Destination Subdir
CLEARRDEST 	= START 118 +0 CLEAR

NumRepeats	= END   31 +1 Number of Repeats for each Test
StatsPath       = END   31 +1 Location for Stats
JobCONFIG 	= END   31 +1 Choose HyConfig Options for Tests
;this will use an index into a list available from the hytest.ini - trick is to ....what exactly

RunCompare	= END   31 +2 Run the Comparison process?
BC        	= END   31 +1 Open Results in Beyond Compare?

;SVR   		= END   31 +2 Use SVRRUN to Run Tests?
OUT   		= END   31 +1 Output File


[Fields]
TESTPATH	= 33 11 INPUT   CHAR     80  0  FALSE   FALSE   0.0 0.0 '&hyd-ptmppath.testharness\testjobs\' $PA
TESTS 		= 33 +1 INPUT   CHAR       80  0  FALSE   FALSE   0.0 0.0 '.*' 
LDEST 		= 33 +3 INPUT   CHAR       80  0  FALSE   FALSE   0.0 0.0 'APPROVED' $IN.HYTEST.INI @[RESULTS]
RDEST 		= 33 +1 INPUT   CHAR       80  0  FALSE   FALSE   0.0 0.0 'TEST' $IN.HYTEST.INI @[RESULTS]
CLEARRDEST	= 125 +0 INPUT   LIST   3  0  FALSE   TRUE    0.0 0.0 'YES' YNO

NumRepeats	= 33 +1 INPUT  NUMERIC   3  0  FALSE   FALSE   1 10  '1'
StatsPath	= 33 +1 INPUT   CHAR     80  0  FALSE   FALSE   0.0 0.0 '&hyd-ptmppath.testharness\stats\' $PA

JobCONFIG 	= 33 +1 INPUT   CHAR   80  0  FALSE   FALSE   0.0 0.0 'DEFAULT' $IN.HYTEST.INI @[HYCONFIGS]

RunCompare	= 33 +2 INPUT   LIST        3  0  FALSE   TRUE    0.0 0.0 'NO' YNO
BC    		= 33 +1 INPUT   LIST        3  0  FALSE   TRUE    0.0 0.0 'NO' YNO

;SVR   		= 33 +2 INPUT   LIST        3  0  FALSE   TRUE    0.0 0.0 'NO' YNO
OUT   		= 33 +1 INPUT   CHAR       80  0  FALSE   TRUE    0.0 0.0 '#PRINT(P           )'

[Perl]
=cut


=skip
Notes on V11 logging
Easiest way would be to override the hyconfig HYDLOGPATH setting, then whatever turned up in that folder (down the data tree) 
belongs to the job you just ran.

Minor complication within a batch job:  the HYLOGITCNF env var has some of the settings in a "burnt-in" manner, 
you'd have to force that env var to be reset.  Easy enough.

Write something about screen rendering of PNG, and screen settings - Win 8 vs XP etc. Font aliasing and ClearType.

=cut
#to do the test with the hytest.pm file here - short cut is this
use lib "h:/hydstra/prod/hyd/DAT/ini";


#Copyright (c) 2009 Kisters Pty Ltd. All rights reserved. 
#***keyword-flag***     'Version %v'
# version 'Version 1'

require 'hydlib.pl';
require 'hydtim.pl';
require 'hydata.pl';

use HyTest2; #cos this will evolve and want the original to run too.
#use HyTest::Stats;
use File::Copy;
use File::Slurp;
use strict;
my (@PERC_CLASS)=qw(vslow slow ok fast vfast);

#print "paused"; <STDIN>;

main: {
  my %ini; 
  my $junkpath=lc(HyconfigValue('JUNKPATH'));
  my $temppath=lc(HyconfigValue('TEMPPATH'));
  my $hydver=HyconfigValue('HYDVER').'.'.HyconfigValue('HYDREL');
  
  #Open INI File from HYSCRIPT
  IniHash($ARGV[0],\%ini);
  #Open INI File for HYTEST - immediately so can use lookups into it
  IniHash('hytest.ini',\%ini);
  Prt('-L',HashDump(\%ini));
  
  #set up parameters
  my $testpath=$ini{perl_parameters}{testpath}; #code explicitly so that can refer to diff place than where results are written.
      #decouple testpath location from testroot->where the results are written
  my $numrepeats=$ini{perl_parameters}{numrepeats}; #to get stats need more than one run - allow many.
        # has consequences for analysis
        #1. where to write and how to separate each run. have one dir for rawraw single result, another for raw result the append of all. maybe just one.
        #2. how to pull all the results into analysis
  
  my $testpattern=$ini{perl_parameters}{tests};
  my $clearrdest=istrue($ini{perl_parameters}{clearrdest});
  my $jobconfig=lc($ini{perl_parameters}{jobconfig}); #keys are lower cased by default - so -to use it need to ensure lc()
  my $jobconfigpath=$ini{hyconfigs}{$jobconfig};
  my $statspath=$ini{perl_parameters}{statspath};
  my $docompare=istrue($ini{perl_parameters}{runcompare}); 
  my $openbc=istrue($ini{perl_parameters}{bc});
  #my $use_svr=istrue($ini{perl_parameters}{svr});
  my $prmfile=JunkFile('prm');

  OpenFile(*hREPORT,$ini{perl_parameters}{out},'>');
 Prt('-S',NowStr()," HYTEST Started",' running tests immediately',"\n");
  #Prt('-S',NowStr()," HYTEST Started",($use_svr)?' using SVRRUN':' running tests immediately',"\n");
  Prt('-L',"Report file=$ini{perl_parameters}{out}\n");
  
  #get the report directory if the user is writing to a file
  my $reportdir=$ini{user_parameters}{out_folder};
  Prt('-L',"Reportdir=[$reportdir]\n");
  MkDir($reportdir);

  #get the performance classes from hytest.ini
  #these are v.rough. expect that need some statistical measure. but that means that need to capture those stats for the approved
  my @perc=CSVSplit($ini{config}{'percentage classes'});
  Prt('-L',join('|',@perc),"\n");
  if($#perc!=3){Prt('-RSX',"*** ERROR - ther emust be exactly 4 percentage classes in HYTEST.INI, you provided @{[$#perc+1]} of ",join(',',@perc),"\n")};
  
  #test destination folder
  my $ldest=lc($ini{perl_parameters}{ldest}); 
  my $rdest=lc($ini{perl_parameters}{rdest}); 
  Prt('-RSX',"*** ERROR - Destination must not be 'approved'\n") if ($rdest eq 'approved');
  
  #set up test directory names and check they are present
  my $testroot=lc($ini{results}{$rdest}); 
  #Prt('-P',"rdest=$rdest, testroot=[$testroot]\n");
  
  if($testroot !~m{\\$}){$testroot.='\\'}; #append trailing backslash if necessary
  Prt('-RSX',"*** ERROR - testroot [$testroot] not found - please make directory and re-run\n") if !-d $testroot;
  
  #where are the test batch files kept
  if($testpath !~m{\\$}){$testpath.='\\'}; #append trailing backslash if necessary
  Prt('-RSX',"*** ERROR - Tests Batch Jobs directory [$testpath] not present\n") if (!-d $testpath);
  
  #where do the test write results to, well after it gets generated on temppath
  my $rraw="${testroot}results\\$rdest\\raw\\";
  my $rmasked="${testroot}results\\$rdest\\masked\\";
  
  #potential output dirs or comparison
  my ($lraw,$lmasked,$bcleft,$bcright);
  if ($docompare) { #may only want stats
    $lraw="${testroot}results\\$ldest\\raw\\";
    $lmasked="${testroot}results\\$ldest\\masked\\";
    if ($openbc) { #if not doing compare won't want bc
      $bcleft="${testroot}results\\$rdest";
      $bcright="${testroot}results\\$ldest";
    }
  }
  
  foreach my $dir ($testroot,$rraw,$rmasked,$lraw,$lmasked){
    if ($dir) {
      MkDir($dir);
      Prt('-RSX',"*** ERROR - Test directory [$dir] not present\n") if (!-d $dir);
    }
  }
 
  #get a hytest object to run things with
  my $hytest=HyTest->new(
    testpath=>$testpath,
    testpattern=>$testpattern,
    reportdir=>$reportdir,
    docompare=>$docompare,
    beyondcompare=>$openbc,
    ldest=>$ldest,
    rdest=>$rdest,
    rraw=>$rraw,
    rmasked=>$rmasked,
    #plus
    statspath=>$statspath,
    configname=>$jobconfig
);
  
  #do i need to do following ...
  #change working directory to TEMPPATH so batch jobs don't have to  
  #chdir($temppath);

  #only run tests of the pattern is not '0', which means don't run any tests
  if($testpattern ne '0'){
    
    #get a list of tests to run
    my @alltests=DOSFileList("${testpath}*.bat",0);
    my @tests=grep {$_=~m{$testpattern}i} @alltests;
    Prt('-L',"Test list=[\n",join("\n",@tests),"\n]\n");
    Prt('-RSX',"*** ERROR - No tests found at ${testpath}\n") if($#tests==-1);
    
    #delete the outputs
    #do i need to delete them all or just those for current jobs
    my @deletionList;
    if ($clearrdest) {
      @deletionList=@alltests;
    } else {
      @deletionList=@tests;
    }
    foreach my $test (@deletionList){
      my $t=FileName($test);
      PrintAndRun('-L',"del /q ${rraw}$t*.*");
      PrintAndRun('-L',"del /q ${rmasked}$t*.*");
    }
    
    #run each test
    #maybe add back the svrrun and svrsub when work out how to make it work
    #
    my $testno=1;
    my $testcount=@tests;
    foreach my $test (@tests){
      my $testname=FileName($test);
      for( my $testinstance=1;$testinstance<=$numrepeats;$testinstance++) {
  
        Prt('-SL',NowStr()," Test $testname (test $testno of $testcount tests) ((repeat# $testinstance of $numrepeats repeats))\n");      
        #run immediately and wait for the test to complete
        $hytest->run($test,"$testno/$testcount/$testinstance",$testinstance);
        ##$hytest->write_stats();
      }
      $testno++;
    }
  }  
  
  #now load and compare results from the test
  if ($docompare) {
    Prt('-R',$hytest->compare);
  }
  Prt('-SR',NowStr()," HYTEST Finished\n");
  close(hREPORT);

  #print "paused"; <STDIN>;
}


sub gatherStats {
  my ($statslogfile,$stats) =@_;
  1;
}


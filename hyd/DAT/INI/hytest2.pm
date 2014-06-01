package HyTest;

#Copyright (c) 2013 Kisters Pty Ltd. All rights reserved. 
#***keyword-flag***     "Version %v  %f"
# "Version 14  23-Jul-12,21:58:02"

=head1 PACKAGE HYTEST

HyTest - Support routines for the HYTEST.HSC - the Hydstra test harness.

=head1 SYNOPSIS

  my $hytest=HyTest->new(ldest=>$ldest,rdest=>$rdest,beyondcompare=>$openbc,reportdir=>$reportdir,testpath=>$testpath,
               rraw=>$rraw,rmasked=>$rmasked);
  foreach my $test (@tests){
    $hytest->run($test,$title);
  }
  Prt('-R',$hytest->compare);


=head1 DESCRIPTION

HyTest.pm is a utility module used by HYTEST.HSC, the Hydstra user test harness. It manages the processing of the
tests, and the collation of the outputs, as well as the display of the results.

HYTEST can run the test harness in a number of different environments, each of which is named with a single word such as WINXP, XPOVERSQL,
SVRRUN, STANDALONE etc. A specialy reserved environment is APPROVED, which holds the final correct and approved test results. Test results
are pushed to APPROVED by a process of approval, either using the HYTEST interface or else using Beyond Compare.

See the documentation of HYTEST.HSC in the Hydstra Help file for more details.

=head1 MOOSE DEFINITIONS

  has 'ldest' => (isa => 'Str', is => 'rw', required => 1);
  has 'rdest' => (isa => 'Str', is => 'rw', required => 1);
  has 'testpath' => (isa => 'Str', is => 'rw', required => 1);
  has 'rraw' => (isa => 'Str', is => 'rw', required => 1);
  has 'rmasked' => (isa => 'Str', is => 'rw', required => 1);
  has 'beyondcompare'=>(isa => 'Bool', is => 'rw', required =>0, default=>1 );
  has 'reportdir'=>(isa => 'Str', is => 'rw', required =>1);

=over 8

=item ldest

The left-hand destination of  test run, typically but not necessarily APPROVED. The destination must be registered in HYTEST.INI.

=item rdest

The right hand destination of the current run. This will become part of the folder name where the current test results are stored.
The destination must be registered in HYTEST.INI.

=item testpath

The path to the top of the test harness system. This is defined in HYTEST.INI, and will probably be something like:

  approved=&hyd-logpath.th 
  
=item rraw

Fully qualified folder of the raw results for this test run. The raw folder contains the output from the test run exactly as it is produced by the
program being tested. For example:

  C:\hydstra\systems\V100400\HYD\log\th\results\homewin8\raw

=item rmasked

Fully qualified folder of the masked results for this test run. The masked folder contains the output from the test run after it has been processed to become invariant.
This will include masking out such varying items as dates and times, program versions, and execution times, amongst other things.

It is the resposnsibility of the user developing the test jobs to ensure that the final masked output is invariant between runs.

  C:\hydstra\systems\V100400\HYD\log\th\results\homewin8\masked

=item beyondcompare

A boolean variable set to 1 if you want to open Beyond Compare to detailed test comparisons. Beyond Compare must be installed
on the computer running HYTEST if you chose this option, and HYTEST.INI need to be configured to point to it. 

=item reportdir

Path to the location of the test jobs.

=back
  
=head1 METHODS


=cut

use Moose;
use File::Slurp;
use File::Copy;
use HyTable;
use Win32;
use Time::HiRes qw(time);
use strict;

has 'testpath' => (isa => 'Str', is => 'rw', required => 1);
has 'testpattern' => (isa => 'Str', is => 'rw', required => 1);
has 'reportdir'=>(isa => 'Str', is => 'rw', required =>1);
has 'beyondcompare'=>(isa => 'Bool', is => 'rw', required =>0, default=>1 );

has 'ldest' => (isa => 'Str', is => 'rw', required => 1);
has 'rdest' => (isa => 'Str', is => 'rw', required => 1);
has 'rraw' => (isa => 'Str', is => 'rw', required => 1);
has 'rmasked' => (isa => 'Str', is => 'rw', required => 1);

has 'statspath'=>(isa => 'Str', is => 'rw', required =>0);
has 'all_jobs_stats_file'=>(isa => 'Str', is => 'rw', required =>0);
has 'all_jobs_steps_file'=>(isa => 'Str', is => 'rw', required =>0);
#identification information
has 'configname'=>(isa => 'Str', is => 'rw', required =>0);
has 'job_starting_time'=>(isa => 'Str', is => 'rw', required =>0);
has 'computername'=>(isa => 'Str', is => 'rw', required =>0);
has 'username'=>(isa => 'Str', is => 'rw', required =>0);


#***keyword-flag***     '%v'
my($tlib_version)= '1';
#***keyword-flag***     '%f'
my($tlib_date)='28-Feb-13,12:28:00';

my %c; #configuration hash
my $t; #output table
my (@PERC_CLASS)=qw(vfast fast ok slow vslow);
my @files; #list of files to report on
my @perc;
my ($newconfig,$newaccess);
my $runpath=lc(::HyconfigValue('RUNPATH'));
my($nowstr,$nowrel,$nowprm,$nowprt,$nowfil,$temppath,$totaltime);
my($thtemp,$thjunk,$thprm,$thpriv,$hyconf);
my $hydver;

=head2 new

Create a new hytest object.

  my $hytest=HyTest->new(ldest=>$ldest,rdest=>$rdest,beyondcompare=>$openbc,reportdir=>$reportdir,testpath=>$testpath,
               rraw=>$rraw,rmasked=>$rmasked);

=cut




sub BUILD {
  my ($self)=@_;
  #need a way to identify this set of jobs uniquely
  $self->_jobSetIdInformation();
  $self->_stats_set_filenames();

  #get todays date so we can eliminate it from various outputs
  $nowrel=::NowRel();
  $nowstr=::ReltoTmp($nowrel,'YYYYMMDD');
  $nowprm=::ReltoTmp($nowrel,'DD/MM/YYYY');
  $nowprt=::ReltoTmp($nowrel,'YYYY/MM/DD');
  $nowfil=::ReltoTmp($nowrel,'YYYY-MM-DD');
  ::Prt('-L',"nowrel=[$nowrel], nowstr=[$nowstr], nowprm=[$nowprm], nowprt=[$nowprt], nowfil=[$nowfil]\n");
  
  #set up some temppath info, including new temppaths for tests themselves
  $temppath=lc(::HyconfigValue('TEMPPATH'));
  $thtemp="${temppath}th\\";
  $thjunk="${thtemp}temp\\";
  $thprm="${thtemp}prm\\";
  $thpriv="${thtemp}thpriv\\";
  ::RmDir($thtemp);
  ::MkDir($thtemp);
  copy("${temppath}hylogin.ini","${thtemp}hylogin.ini"); 
  $hyconf="temppath;$thtemp;junkpath;$thjunk;privpath;$thpriv;prmpath;$thprm;abortw;f";
  
  ::Prt('-L',
"SET LDEST=@{[$self->ldest]}
SET RDEST=@{[$self->rdest]}  
SET REPORTDIR=@{[$self->reportdir]}
SET TESTPATH=@{[$self->testpath]}
SET RRAW=@{[$self->rraw]}
SET RMASKED=@{[$self->rmasked]}
SET HYCONF=$hyconf
");
  $hydver=::HyconfigValue('HYDVER').'.'.::HyconfigValue('HYDREL');
  ::Prt('-L',"hydver=$hydver\n");  
  return $self;
}

#buld and assign a unique jobSetId to this job
sub _jobSetIdInformation {
  my $self=shift;
  #get a starting time that i can use on the job
  my $time=::NowStr();
  $time =~ s{[\/\s:]}{_}g;
  $self->job_starting_time($time);
  #get the user running this
  my $username = $ENV{username};
  $self->username($username);
  #get the machine being run on
  my $computername = $ENV{COMPUTERNAME};
  $self->computername($computername);
  #these together with the config should id the instance
  1;
}

sub _stats_set_filenames {
  my $self=shift;
  #set_the ALL STATS file names in the path providd
  
  #
  my $path = $self->statspath;
  if($path !~m{\\$}){$path.='\\'};
  $self->statspath($path);
  ::MkDir( $path) or die("StatsPath: cannot create path '$path'\n");
  my $all_jobs="${path}ALL_JOB_STATS.csv";
  my $all_job_steps="${path}ALL_JOB_STEPS.csv";

  $self->all_jobs_stats_file($all_jobs);
  $self->all_jobs_steps_file($all_job_steps);
  1;
}

sub write_job_line {
  my ( $self, $testname, $itteration, $elapsedtime) =@_;
  if (! -e $self->all_jobs_stats_file()){
    ::OpenFile(*hSTATS_ALL,$self->all_jobs_stats_file(),'>');
    my $header=sprintf(
      "%s,%s,%s,%s,%s,%s,%s\n",
        'configname',
        'computername',
        'username',
        'job_starting_time',
        'testname',
        'itteration',
        'elapsedtime'  
      );
    print hSTATS_ALL $header;
  } else {
    ::OpenFile(*hSTATS_ALL,$self->all_jobs_stats_file(),'>>');
  }
  #file is open so now write the line of results
  my $line=sprintf(
    "%s,%s,%s,%s,%s,%s,%s\n",
    $self->configname(),
    $self->computername(),
    $self->username(),
    $self->job_starting_time(),
    $testname,
    $itteration,
    $elapsedtime  
    );
  print hSTATS_ALL $line;
  #done
  close(hSTATS_ALL);
}

has 'configname'=>(isa => 'Str', is => 'rw', required =>0);
has 'job_starting_time'=>(isa => 'Str', is => 'rw', required =>0);
has 'computername'=>(isa => 'Str', is => 'rw', required =>0);
has 'username'=>(isa => 'Str', is => 'rw', required =>0);


sub _load {
  #utility routine loads test results from left and right directories and develops a list of file names to compare.
  
  my ($self)=@_;
  
  my $ldest=lc($self->ldest); $ldest=~s{\\$}{}x; $c{ldest}=$ldest;
  my $rdest=lc($self->rdest); $rdest=~s{\\$}{}x; $c{rdest}=$rdest;

  #Open INI File for HYTEST
  ::IniHash('hytest.ini',\%c,0);

  my $lpath=($c{results}{$ldest}//'undef')."\\results\\$ldest"; $c{lpath}=$lpath;
  my $rpath=($c{results}{$rdest}//'undef')."\\results\\$rdest"; $c{rpath}=$rpath;
  
  
  ::Prt('-L'," Left destination $ldest=[$lpath]\n");
  ::Prt('-L',"Right destination $rdest=[$rpath]\n");
  my (@folders)=($lpath,$rpath);
  
  #take a copy of HYCONFIG for later use with HTML
  my $reportdir=$self->reportdir;
  my $hyconfig=::HyconfigValue('CONFPATH');
  $newconfig=$reportdir."hyconfig.hytest.ini";
  copy($hyconfig,$newconfig);
  
  #take a copy of HYACCESS for later use with HTML
  my $hyaccess=::HyconfigValue('ACCPATH');
  $newaccess=$reportdir."hyaccess.hytest.ini";
  copy($hyaccess,$newaccess);
  
  
  #load list of test results
  foreach my $folder (@folders){
    next if ($folder =~m{undef});
    @files=::DOSFileList("${folder}\\masked\\*.*",1);
    @files=map {lc($_)} @files;
    ::Prt('-L',"files in ${folder}\\*.*=",join(',',@files),"\n");

    #Go through the files and build a unique lists of files to drive the rest of the process
    foreach my $file (@files){
      my $fn=::FileNameExt($file);
      $c{files}{$fn}++;
    }
  }
  ::Prt('-L',"Files to compare=\n",::HashDump(\%{$c{files}}),"\n");
  
  @perc=::CSVSplit($c{config}{'percentage classes'});
  ::Prt('-L',join('|',@perc),"\n");
  if($#perc!=3){::Prt('-RSX',"*** ERROR - there must be exactly 4 percentage classes in HYTEST.INI, you provided @{[$#perc+1]} of ",join(',',@perc),"\n")};

  #get a list of tests to compare
  @files=sort keys %{$c{files}};
  ::Prt('-L',"Test list=[\n",join("\n",@files),"\n]\n");
  ::Prt('-RSX',"*** ERROR - No files found at $ldest or $rdest\n") if($#files==-1);
  
  return $self;
}

=head2 run

Runs a single test, which must be a batch job in the test folder.

  $hytest->run('c:\hydstra\systems\v100400\hyd\log\th\testjobs\hyday_01.bat','1/7');
  
First parameter is the test to run, second parameter i put on the title br of the CMD shell tunning the test

=cut

sub run {
  my ($self,$test,$title,$itteration)=@_;
  
  my $testname=::FileName($test);
  my $rraw=$self->rraw;
  my $rmasked=$self->rmasked;
  my $testpath=$self->testpath;
  ::Prt('-L',"Running test [$test] with thtemp=[$thtemp]\n");

  #clear out test outputs
  unlink("${thtemp}test.txt","${thtemp}hydsys.err","${thtemp}hydlog.txt");
  unlink(::DOSFileList("${thtemp}*.xml",0));
  unlink(::DOSFileList("${thtemp}*.png",0));

  #run the job
  my $starttime=time();
  my $prm=qq(\@echo off & title $title& cd /d $testpath& set HYTESTPATH=$testpath& set HYTESTENV=1& set HYCONF=$hyconf& set print=${thtemp}test.txt&set print1=${thtemp}junk& set plot=wix\(wix??.xml\)& call $test);
  ::PrintAndRun('-L',$prm,0,0);
  my $elapsedtime=sprintf('%.3f',time()-$starttime);
  #Prt('-S',NowStr(),"                       $elapsedtime seconds\n");
  $totaltime+=$elapsedtime;

  #pick up the text outputs
  ::Prt('-L',"Opening test output file [${rraw}$testname.txt]\n");
  ::OpenFile(*hOUTPUT,"${rraw}$testname.txt",'>>');
  ::Prt(*hOUTPUT,"[Job output]\n\n");
  ::PrintFile(*hOUTPUT,"${thtemp}test.txt");
  if(-f "${thtemp}hydsys.err"){
    #don't collect the stats if there was an error
    #but do collect the error info
    ::Prt(*hOUTPUT,"[HYDSYS.ERR]\n\n");
    ::PrintFile(*hOUTPUT,"${thtemp}hydsys.err");
  } else {
    #there was no error so use the $elapsedtime for the stats
    $self->write_job_line( $testname, $itteration, $elapsedtime);
  }

  #### will need special handling for HYDLOG files in V11 ####
  ::Prt(*hOUTPUT,"\n[HYDLOG Output]\n\n");
  ::PrintFile(*hOUTPUT,"${thtemp}hydlog.txt");
  ::Prt(*hOUTPUT,"\n[Run Time=$elapsedtime seconds]\n\n");

  close(hOUTPUT);
  
  #if (! -f "${thtemp}hydsys.err"){
  #  #stats not valid if there was an error - so don't collect
  #  my $statslogfile=$self->statspath;
  #  my %stats=(
  #      configname=>$self->configname, #what was the environment at the time
  #      jobset=>$self->jobset, #need to group runs of same job in a sequence. this could be the starting datetime-user-computer when hytest was fired
  #      testname=>$testname,
  #      itteration=>$itteration,
  #      elapsedtime=>$elapsedtime,
  #      username=>$ENV{username},
  #      );
  #  ::gatherStats($statslogfile,\%stats);
  #}

  #slurp the text output into a memory buffer
  my $output=read_file("${rraw}$testname.txt");

  #fix up some dates
  $output=~s{${nowstr}\d{6}}{99999999999999}gx;
  $output=~s{\d\d:\d\d_${nowprm}}{99:99_99/99/9999}gx;
  $output=~s{${nowprm}}{99/99/9999}gx;
  $output=~s{${nowstr}\d{6}}{99999999999999}gx;
  $output=~s{${nowprt} \d\d:\d\d:\d\d(\.\d\d\d)?}{9999/99/99 99:99:99}g;

  #fix up test job run time in output
  $output=~s{\[Run Time=.*? seconds\]}{[Run Time=9.99 seconds]}g;

  #get rid of explicit paths
  foreach my $pathname qw(RUNPATH MISCPATH UTEPATH JUNKPATH PRIVPATH TEMPPATH PTMPPATH DBFPATH PERLPATH){ 
    my $pathpatt=::HyconfigValue($pathname);
    $pathpatt=~s{\\}{\\\\}gx;
    $output=~s{$pathpatt}{<$pathname>\\}igx ;
  }
  
  #fix up temporary paths used in TH
  $output=~s{<TEMPPATH>\\th\\temp\\}{<JUNKPATH>\\}ig;
  $output=~s{<TEMPPATH>\\th\\prm\\}{<PRMPATH>\\}ig;
  $output=~s{<TEMPPATH>\\th\\private\\}{<PRIVPATH>\\}ig;
  $output=~s{<TEMPPATH>\\th}{<TEMPPATH>}ig;
  
  #get rid of program version
  $output=~s{\sV\d+\s}{ V999 }gx;

  #get rid of user id
  $output=~s{ USER: \w+\W}{ USER: <USER> }g;


  #get rid of task run time
  #TASKEND   Time: 1.052 seconds
  $output=~s{(TASKEND\s+Time: ).*?seconds}{${1}9.9 seconds}mg;

  #get rid of job runtime
  #runtime: 1.00 Second,
  $output=~s{runtime:.*?Second(s?)}{runtime: 9.999 Seconds}mg;

  #get rid of LOGIN line
  #$output = join("\n", grep { $_ !~ m{LOGIN\s+User:} } split(/\n/, $output) )."\n";  
  $output=~s{\n.*?\s+LOGIN\s+User:.*?\n}{\n}sg;
  
  #normalise Perl INI file from HYSCRIPT - PerlIni_OWRQPYKW
  $output=~s{PerlIni_[A-Z]{8}}{PerlIni_ZZZZZZZZ}g;
  
  #HYSCRIPT put in explicit path to Perl - START    C:\HYDSTRA\SYSTEMS\V100400\HYD\SYS\PERL\BIN\perl.exe
  #$output=~s{[A-Z]:\(.*)?perl}{PerlIni_ZZZZZZZZ}g;
  
  
  ::Prt('-L',"Opening masked output file [${rmasked}$testname.txt]\n");
  ::OpenFile(*MASKED,"${rmasked}$testname.txt",'>');
  ::Prt(*MASKED,$output);
  close(MASKED);



  #now pick up the graphics output which is in XML
  if(-f "${thtemp}wix00.xml"){
    $output=read_file("${thtemp}wix00.xml");
    
    #copy it to the raw output
    ::OpenFile(*hOUTPUT,"${rraw}$testname.xml",'>');
    ::Prt(*hOUTPUT,$output);
    close(hOUTPUT);
    
    #fix up the plot xml
    ::OpenFile(*hOUTPUT,"${rmasked}$testname.xml",'>');
    
    #fix up some dates
    $output=~s{${nowstr}\d{6}}{99999999999999}gx;
    $output=~s{\d\d:\d\d_${nowprm}}{99:99_99/99/9999}gx;
    $output=~s{${nowprm}}{99/99/9999}gx;
    $output=~s{${nowstr}\d{6}}{99999999999999}gx;
    $output=~s{${nowprt} \d\d:\d\d:\d\d}{9999/99/99 99:99:99}gx;
    
    #get rid of program version
    $output=~s{ V\d+ }{ V999 }g;

    #write it out
    ::Prt(*hOUTPUT,$output);
    close(hOUTPUT);
    
    
    #split top-level plot into hyplot_00_01.XML sub-plots
    ::PrintAndRun('-L',qq(  \@echo off & title $title & set HYTESTENV=1& set hyconf=$hyconf& hyplofil ${rmasked}$testname.xml wix\(${testname}_??.xml\) /single /hide),0,0);

    #remove the top-level plot, we don't need it any more
    unlink("${rmasked}$testname.xml");
    
    foreach my $file (::DOSFileList("${thtemp}${testname}*.xml")){    
      $file=lc($file);
      my $filedest=lc($rmasked.::FileNameExt($file));

      ::Prt('-L',"  Copying $file to $filedest\n");
      my $xml=read_file($file);
      #standardize timestamp created by rewriting the XML1 subfile
      $xml=~s{timestamp="\d{14}"}{timestamp="YYYYMMDDHHIIEE"}g;
      ::OpenFile(*XML,$filedest,'>',$xml); 
      close(XML);
      
      #plot it to PNG
      my $pngdest=$filedest;
      $pngdest=~s{xml$}{png};
      ::PrintAndRun('-L',qq(  \@echo off & title $title & set HYTESTENV=1& set hyconf=$hyconf& hyplofil $filedest png\($pngdest,1200,800\) /hide),0,0);
           
    }
    
    close(hOUTPUT);
  }

  else {
    ::Prt('-L',"No plot output found for $testname at ${thtemp}wix00.xml\n");
  }   
  return;  
}

=head2 compare

Compares all the test results and returns an HTML table of the test results. See the HYTEST.HSC documentation for an
example.

    Prt('-R',$hytest->compare);

=cut

sub compare{
  #compare test outputs for ldest and rdest, which must be registered in HYTEST.INI
  #returns an HTML string for the comparison table

  my ($self)=@_;
  
  #load the test results
  $self->_load;
  
  #create the output table
  $t = HyTable->New('hytest.htm',{tabletitle=>'HYTEST Summary Report',border=>0,tablecenter=>1});
  #build heading row for table
  $t->Row('next',['<p1><cs8><c>HYTEST Output']);
  $t->RowSkip(1);
  $t->Row('next',['<c><cs8>Run at '.::NowStr().'  from computer '.$ENV{COMPUTERNAME}.'  with destination '.ucfirst($c{rdest})]);
  $t->RowSkip(1);
  $t->Row('next',['Test','File','Result',ucfirst($c{ldest})."<br><r>Seconds",ucfirst($c{rdest})."<br><r>Seconds",'% Change','Speed','Approve?']);
  $t->Row('last',{align=>'left',class=>'head'});
  $t->Col([0..2,6],{align=>'left'});
  $t->Col([3..4],{align=>'right'});
  
  my $lpath=$c{lpath};
  my $rpath=$c{rpath};
  my $prevtest='';
 
  foreach my $file (@files){
    #skip over diff files for now
    next if ($file=~m{\.dif\.txt$|\.png$}x);
    my $fileext=::FileExt($file);
    
    ::Prt('-S',"Comparing $file\n");
    my $lf="${lpath}\\masked\\$file";
    my $rf="${rpath}\\masked\\$file";
    my $lfile=(-f $lf)?read_file($lf):'';
    my $rfile=(-f $rf)?read_file($rf):'';
    #::Prt('-L',"LFILE($lf)=[$lfile]\n\nRFILE($rf)=[$rfile]\n\n");

    #now see if the masked output equals the approved output
    my $result=($lfile eq $rfile)?'pass':'fail';
    
    #if different and the right file type, run gnudiff
    my $df=''; #diff file in destination directory
    if(::FileExt($file)=~m{txt$}){
      $df="$lf.dif.txt";
      if(-e $lf and -e $rf){
        ::PrintAndRun('-L',"gnudiff $lf $rf >$df",0,0);
      }
      unlink ($df) if (!-s $df);
    }

    #sort out some stuff about timing
    my $ltime=0;
    my $rtime=0;
 
    #check the timing against the approved timing
    my $lft=lc("${lpath}\\raw\\$file"); $lft=~s{_\d\d.png}{.png}; $lft=~s{\....$}{.txt}; #make sure we read the TXT file regardless of result type
    my $rft=lc("${rpath}\\raw\\$file"); $rft=~s{_\d\d.png}{.png}; $rft=~s{\....$}{.txt}; #make sure we read the TXT file regardless of result type
    my $lrawfile=(-f $lft)?read_file($lft):'';
    my $rrawfile=(-f $rft)?read_file($rft):'';

    my $approvedtime=0;
    my $elapsedtime=0;
    my $percdiff=0;
    if($lrawfile=~m{\[Run Time=(.*) seconds\]}){
      $approvedtime=$1;
    }
    if($rrawfile=~m{\[Run Time=(.*) seconds\]}){
      $elapsedtime=$1;
    }
    ::Prt('-L',"Elapsed time in $rft=$elapsedtime, Approved time in $lft=$approvedtime\n");
    
    if($elapsedtime!=0 and $approvedtime!=0){
      $percdiff=sprintf('%.1f',100*($elapsedtime-$approvedtime)/$approvedtime);
      if($percdiff !~m{-}){$percdiff="+$percdiff"};
    }
    
    my $perc_class='vslow';
    for my $i (0..3){
      if($percdiff<$perc[$i]){
        $perc_class=$PERC_CLASS[$i];
        last;
      }
    }

    #if one of the tests was missing, result is na
    if($approvedtime==0 or $elapsedtime==0){
      $perc_class='na';
    }

    #print result
    $percdiff.='%';
    my $testtype=($file=~m{xml|xml1|png}i)?'plot':'print';
    my $testname=$file;
    my $testroot;
    if($testname=~m{^(.*?_\d\d)}){
      $testroot=$1;
  } 
    my $testprint=$testroot;
    if($testroot eq $prevtest){
      $testprint='';
      $approvedtime='';
      $elapsedtime='';
      $percdiff='';
      $perc_class='';
    }
    $prevtest=$testroot;
    
    
    #print results row
    if($perc_class eq 'na'){$result='na'};
    my $approvetest='';
    $t->Row('next',['<l>'.$testprint,$testname,$result,$approvedtime,$elapsedtime,$percdiff,$perc_class]);
    $t->Cell('last',1,{href=>$rf});
    #$t->Cell('last',1,{href=>qq(javascript:RUN_HYDSTRA_APP("${runpath}hyview.exe /vs /c $rf ","$newconfig","$newaccess"))});
    $t->Cell('last',2,{class=>$result});
    $t->Cell('last',6,{class=>$perc_class});
    
    #if the diff file exists, link to it
    if(-f $df){
      $t->Cell('last',2,{href=>$df});
    }
    elsif($result eq 'pass' and $fileext ne 'png'){
      #$t->Cell('last',2,{href=>$lf});
    } 
    elsif($result eq 'na'){
     $t->Cell('last',2,{href=>(-e $lf)?$lf:$rf});
    }    
    #else maybe the plots need comparing
    elsif($testtype eq 'plot' and $result eq 'fail'){
      my $reportdir=$self->reportdir;

      ::Prt('-LS',"Comparing [$lf] with [$rf]\n");
      $t->Cell('last',2,{href=>qq(javascript:RUN_HYDSTRA_APP("${runpath}hyview.exe /vs /c $lf+$rf ","$newconfig","$newaccess"))});
    }
    
    #if test failed, make a link to approve the results
    if($result ne 'pass'){
      $t->Cell('last',7,'approve');
      $t->Cell('last',7,{class=>'fail',href=>qq(javascript:RUN_HYDSTRA_APP("${runpath}hyscript.exe /j=hytest_approve.hsc $rf S","$newconfig","$newaccess"))});
    }

  }
  
  #if required and able, go ahead and run Beyond Compare
  if($self->beyondcompare){
    #check for Beyond Compare at specified path
    my $bcpath=$c{config}{bcpath}//'';
    if($bcpath ne ''){
      if (!-f $bcpath){
        ::Prt('-WS',"*** ERROR - Could not find Beyond Compare at [$bcpath]\n");
      }
      else {

        #spawn Beyond Compare 
        my $pid=0;
        my $runline=qq(hystart "$bcpath" "$rpath" "$lpath" /expandall);
        ::Prt('-L',"Starting BC with [$runline]\n");
        Win32::Spawn($runpath.'hystart.exe',$runline,$pid);
        ::Prt('-L',"After starting BC\n");    
      }
    }
  }
  
  return $t->Page;
}

sub lpath {
  #return full path to left hand side
  my ($self)=@_;
  return $c{lpath};
}

sub rpath {
  #return full path to left hand side
  my ($self)=@_;
  return $c{rpath};
}

1; # library initialisation successful

=head1 COPYRIGHT

Copyright (c) 2013 Kisters Pty Ltd. All rights reserved.

=cut

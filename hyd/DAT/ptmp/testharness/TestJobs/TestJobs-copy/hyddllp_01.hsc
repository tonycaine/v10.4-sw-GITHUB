=setup

[Window]
Head = HYGIENE - Check Hydstra System Integrity

[Labels]
OUT = END   31 13 Output File


[Fields]
OUT = 33 13 INPUT   CHAR       30  0  FALSE   TRUE   0.0 0.0 '#PRINT(P           )'


[Perl]
=cut
#Test script for HYDLLLP calls


require 'hydlib.pl';
require 'hydtim.pl';
require 'hydata.pl';
use HydDllp;
use strict;
my %ini;
main: {
  #Open INI File from HYSCRIPT
  IniHash($ARGV[0],\%ini);
    
  OpenFile(*hREPORT,$ini{perl_parameters}{out},'>');
   
  Prt('-S',"Reading QUALCODE ... ");
  my $dll=HydDllp->New();
  my $ref=$dll->JSonCall({
    'function' => 'get_db_info', 
    'version' => 3, 
    'params' => {     
      'table_name'  => 'qualcode',
      'return_type' => 'array',
    }
  },10000000);
  Prt('-R',HashDump($ref),"\n\n\n");
  close(hREPORT);
}


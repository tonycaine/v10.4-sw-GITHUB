<#
want to use hymulti as controller for set of tests in diff configurations

1. get the set of hyconfig names
  These are coded for configuration patterns
2. write a script to set up and start a hytest job
3. run job getting stats
4. repeat for the other configs
#>

$tests= 'hyxmlout'
$file = 'F:\Hydstra\hymulti-TestEnvs.INI'
#$file = 'F:\dropbox\__powershell\data\hymulti-TestEnvs.INI'


function Invoke-Command() {
    param ( [string]$program = $(throw "Please specify a program" ),
            [string]$argumentString = "",
            [switch]$waitForExit )

    $psi = new-object "Diagnostics.ProcessStartInfo"
    $psi.FileName = $program 
    $psi.Arguments = $argumentString
    $proc = [Diagnostics.Process]::Start($psi)
    if ( $waitForExit ) {
        $proc.WaitForExit();
    }
}


<# need to use a constant ini path to the actual hyscript hytest02job #>
$inipath='F:\Hydstra\systems\v10.4-SW\hyd\DAT\INI\'


<#find the config name
#remove the path to diff group and just get the filename
eg. line
10.3 foxpro=H:\hydstra\prod\hyd\sys\run\hyxplore.exe    /noregdll,H:\hydstra\prod\hyd\hyconfig.fox.ini,f:\hydstra\config\hyaccess.ini
#>
$parseExpression='(.+)=(.*\\)(.+),(.*\\)(.+),(.+)'

<#
use the parseExpression above
read hi multi and get the set of lines containing the ini files and other info
#>


if ( ! (Test-Path -Path $file )) {
  "invalid somewhere: check file [$file] exists" | Out-Host 
  throw  "invalid somewhere: check file [$file] exists" 
}

 #[string]$file | Get-Content

#remove-variable iniContent 
$iniContent = Get-Content -path  $file| Select-String $parseExpression
#$iniContent

# now get a structure that has info want
#Remove-Variable properties
$properties = "IniLabel","RunPath","HyXplore","ConfigPath","ConfigFile","HyaccessIni","x"

#Remove-Variable iniObjects
$iniObjects = $iniContent |
  Convert-TextObject -pattern $parseExpression -PropertyName $properties


<# 2 - write a script for each config
set hyconfig.ini
set hyaccess.ini
set path to include hyd
hylogin
hyscript /j=inipath\hytest2.hsc parameterfile

then Execute Script
#>




for($iniCounter = 0; $iniCounter -lt $iniObjects.Length; $iniCounter++) {
	$row=$iniObjects[$iniCounter]	

	# get the values i need from the row
	$row=$iniObjects[$iniCounter]
	$hyconfig_ini =$row.configpath + $row.Configfile
	$hyaccess_ini = $row.hyaccessini
	$hyscript=$row.runpath+'hyscript.exe'
	$hyconfig_name=$row.Configfile
	
	$hyconfig_short_name = $hyconfig_name -replace 'hyconfig-',''
	
	$hyconfig_name | Out-Host

	#parameter file to use not the JOBCONFIG
	$parameters = @"
[parameters]
TESTPATH = &hyd-ptmppath.testharness\testjobs\
TESTS = $tests
LDEST = APPROVED
RDEST = TEST
CLEARRDEST = Yes
NUMREPEATS = 5
STATSPATH = &hyd-ptmppath.testharness\stats\
JOBCONFIG = $hyconfig_short_name
RUNCOMPARE = No
BC = No
OUT = S
"@

	#remember to delete this file before finish
	$parameterFile = [IO.Path]::GetTempFileName()
	$parameters | out-File -filepath $parameterFile -Encoding 'ASCII'

	#and get a file for the batch job, clear the temp but keep bat one for moment
	$BatchTmpFile = [IO.Path]::GetTempFileName() 
	$BatchFile =  $BatchTmpFile -replace '(.*)\.tmp','$1.bat'
	Remove-Item $BatchTmpFile

	#now set up the hydstra job to use that parameter file and do the tests ...

	$hyconfig_ini =$row.configpath + $row.Configfile
	$hyaccess_ini = $row.hyaccessini
	$hyscript=$row.runpath+'hyscript.exe'
	$script="START /W $hyscript /j=${inipath}hytest2.hsc @$parameterFile"


	$cmdTxt =  @"
setlocal
set hyconfig.ini= $hyconfig_ini
set hyaccess.ini= $hyaccess_ini
$script
"@

	$cmdTxt | out-File -filepath $BatchFile -Encoding 'ASCII'

	Invoke-command $BatchFile -waitForExit 
	Remove-Item $BatchFile
	Remove-Item $parameterFile
}
      

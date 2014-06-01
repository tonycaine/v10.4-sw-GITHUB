cd %ini%
start /w telview 'Default - HDT - GMC' /s=TSFILES(PROV) /v=10,100,110,130,300,2010,2012,2030,2080,2100

wait till loaded 
then 
Get-Process telview | Stop-Process
 
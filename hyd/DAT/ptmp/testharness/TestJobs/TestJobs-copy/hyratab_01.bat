echo REPORT 210004 100.00 141 0.000 0.000 0.010 BOTH P25 WIX(WIX??.XML) %print% 10 No No 0 No No No >%junkpath%hyratab.prm
echo TABLE -1 -1 >>%junkpath%hyratab.prm
hyratab @%junkpath%hyratab.prm /hide


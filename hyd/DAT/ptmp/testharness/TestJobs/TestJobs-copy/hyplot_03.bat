echo DATA 210004 A 100.00 100 MAXMIN LIN AUTO 0.0 NONE >%junkpath%hyplot.prm
echo PLOT 1 YEAR 1 DEFAULT 00:00_01/01/1970 1 DEFAULT %plot% >>%junkpath%hyplot.prm
hyplot @%junkpath%hyplot.prm /hide


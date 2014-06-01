set hytest.job.prm=%junkpath%hycsv.prm
echo DATA 210001 A 100.00 141.00 MEAN 																		> %hytest.job.prm%
echo TIME DAY 1.0000 0.00 00:00_01/01/2000 00:00_31/01/2000 END %print% No No NO "DD/MM/YYYY HH:II:EE"  	>>%hytest.job.prm%
hycsv @%hytest.job.prm%  /hide

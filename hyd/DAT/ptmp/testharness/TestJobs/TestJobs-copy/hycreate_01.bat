@rem copy %hytestpath%hycreate_01.ini %temppath%hycreate.ini
@rem copy %hytestpath%hycreate_01.txt %temppath%testdata.txt
hyfiler delete teststn 0 /quiet
hycreate teststn 0 100 1 inst 1 0 erase 0 %hytestpath%hycreate_01.txt inifile testini %print% /e=hycreate.ini=%hytestpath%hycreate_01.ini
hyrep dump teststn 0 no 01/01/1900 01/01/1900 +%print%
@rem fix up some things that change in the HYREP output
perl -i.bak -lne "print if (!m{Lines/sec|Scan time|CDays|BMins})" %print%

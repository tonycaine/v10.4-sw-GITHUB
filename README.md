### HyTest configuration used to test locating Hydstra Components #

Issue:
Have relatively poor performance, compared to a fully local foxpro system, when components are located on networked servers. Addionally push is to use, for great reasons, networked sql server and when do this need to be able to configure and test to get optimal performance.

Approach:
There are three main time consuming sub-components.

1. the database foxpro/sqlserver (db)
2. the timeseries data files (ts)
3. where all the work is written as logs, data, plots are generated

Have configured multiple (16) configurations where these are defined as local or networked.
Hytest.hsc then run against them. Hytest has also been modified. Instead of examimining the result, which here is assumed to be correct (from other testing), multiple runs of each test are done and the timings are collected.

The basic observation is that more network means slower system. The goal is to find the best compromise. That is, cannot support 100+ local systems but want/must give users a reasonable environment to work in.

Example Plot - HyCreate across configuations.
![hycreate_init.png](./documentation/hycreate_init.png)

Intention:
work is just initialised. goal is to test the differnet types of programs, some are db intensive, some are ts intensive, some write lots of report/output and feed results back to modifications of software hosting arrangements and to software vendor.

See Planning Doc.

Config Matrix:

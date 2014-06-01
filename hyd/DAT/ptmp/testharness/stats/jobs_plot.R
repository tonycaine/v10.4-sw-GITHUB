# load and plot the test jobs
require(ggplot2)

dir<-'F:\\Hydstra\\systems\\v10.4-SW\\hyd\\DAT\\PTMP\\testharness\\stats'
setwd(dir)

df<- read.csv("ALL_JOB_STATS.csv")
str(df)

#basic bar plot
p <- ggplot(df, aes(x=configname, y=elapsedtime)) + geom_bar(stat = "identity") +
  facet_wrap(~ testname)
p

#basis histogram
df1<-df[df$testname == 'HYCSV_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p



df1<-df[df$testname == 'hycreate_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p

df1<-df[df$testname == 'hyday_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hyday_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hydbutil_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hydbutil_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hyplot_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hyplot_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


df1<-df[df$testname == 'hyplot_03',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p

df1<-df[df$testname == 'hyratab_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p


# load and plot the test jobs
require(ggplot2)

dir<-'F:\\dropbox\\NOW\\___jobs\\2014-01-15-TestJobs'
setwd(dir)

df<- read.csv("ALL_JOB_STATS.csv")
str(df)


levels(df$configname)
configs<- c('lfp-lts-lt.ini','lfp-lts-mt.ini','lfp-mts-lt.ini','lfp-mts-mt.ini',
            'mfp-lts-lt.ini','mfp-lts-mt.ini','mfp-mts-lt.ini','mfp-mts-mt.ini',
            'lsql-lts-lt.ini','lsql-lts-mt.ini','lsql-mts-lt.ini','lsql-mts-mt.ini',
            'nsql-lts-lt.ini','nsql-lts-mt.ini','nsql-mts-lt.ini','nsql-mts-mt.ini')

df$configname<-factor(df$configname, configs)


#basic bar plot
p <- ggplot(df, aes(x=configname, y=elapsedtime)) + geom_bar(stat = "identity") +
  facet_wrap(~ testname) 

p

#basis histogram
df1<-df[df$testname == 'HYCSV_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname) 
p <- p + ggtitle('hycsv_01')
p



df1<-df[df$testname == 'hycreate_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hycreate_01')
p
#ggsave("hycreate_01.pdf", plot = p)

df1<-df[df$testname == 'hyday_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyday_01')
p


df1<-df[df$testname == 'hyday_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyday_02')
p


df1<-df[df$testname == 'hydbutil_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hydbutil_01')
p


df1<-df[df$testname == 'hydbutil_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hydbutil_02')
p


df1<-df[df$testname == 'hyplot_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyplot_01')
p


df1<-df[df$testname == 'hyplot_02',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyplot_02')
p


df1<-df[df$testname == 'hyplot_03',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyplot_03')
p

df1<-df[df$testname == 'hyratab_01',]
p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
p <- p + ggtitle('hyratab_01')
p


df2<-df[df$configname   == 'lfp-lts-lt.ini'    | 
          df$configname == 'mfp-mts-lt.ini'    | 
          df$configname == 'mfp-mts-mt.ini'    |
          df$configname == 'lsql-lts-lt.ini'   |
          df$configname == 'nsql-lts-lt.ini'   |
          df$configname == 'nsql-mts-lt.ini'   |
          df$configname == 'nsql-mts-mt.ini'
        ,]

str(df2)
ggplot(df2[df2$testname == 'hycreate_01',], aes(x=configname, y=elapsedtime)) + 
     geom_point(position=position_jitter(width=.1, height=0))


p <- ggplot(df2[df2$testname == 'hycreate_01',], aes(x=configname, y=elapsedtime, colour=configname)) +
  geom_point( size=5, position=position_jitter(width=.1, height=0))
p <- p + theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank())
p




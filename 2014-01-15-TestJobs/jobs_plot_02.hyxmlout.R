# load and plot the test jobs
require(ggplot2)

dir<-'F:\\dropbox\\NOW\\___jobs\\2014-01-15-TestJobs'
setwd(dir)

df<-null
df<- read.csv("ALL_JOB_STATS.hyxmlout.csv")
str(df)


levels(df$configname)
configs<- c('lfp-lts-lt.ini','lfp-lts-mt.ini','lfp-mts-lt.ini','lfp-mts-mt.ini',
            'mfp-lts-lt.ini','mfp-lts-mt.ini','mfp-mts-lt.ini','mfp-mts-mt.ini',
            'lsql-lts-lt.ini','lsql-lts-mt.ini','lsql-mts-lt.ini','lsql-mts-mt.ini',
            'nsql-lts-lt.ini','nsql-lts-mt.ini','nsql-mts-lt.ini','nsql-mts-mt.ini')

df$configname<-factor(df$configname, configs)

conf<-'hyxmlout_04_Latestdata_all'

df1<-df[df$testname == conf,]
#p <- ggplot(df1, aes(x=elapsedtime)) + geom_histogram() + facet_wrap(~ configname)
#p <- p + ggtitle(conf)
#p

#df2<-df[df$configname   == 'lfp-lts-lt.ini'    | 
#          df$configname == 'mfp-mts-lt.ini'    | 
#          df$configname == 'mfp-mts-mt.ini'    |
#          df$configname == 'lsql-lts-lt.ini'   |
#          df$configname == 'nsql-lts-lt.ini'   |
#          df$configname == 'nsql-mts-lt.ini'   |
#          df$configname == 'nsql-mts-mt.ini'
#        ,]
df2<-df1

str(df2)
levels(df2$testname)

df3<-df2[df2$testname==conf,]
maxElaspsed<-max(df3$elapsedtime)

#p <- ggplot(df2[df2$testname == config,], aes(x=configname, y=elapsedtime, colour=configname)) +
#  geom_point( size=5, position=position_jitter(width=.1, height=0))
#p <- p + theme(panel.grid.major = element_blank(),
#          panel.grid.minor = element_blank())
#p


p <- ggplot(df3, aes(x=configname, y=elapsedtime, colour=configname)) +
  geom_point( size=5, position=position_jitter(width=.1, height=0)) +
  ylim(0, max(df3$elapsedtime))+
  ggtitle(conf)
p


#p <- p + theme(panel.grid.major = element_blank(),
#               panel.grid.minor = element_blank())
#p

#'lfp-lts-lt.ini'
#'lfp-lts-mt.ini'
#'lfp-mts-lt.ini'
#'lfp-mts-mt.ini'
#'mfp-lts-lt.ini'
#'mfp-lts-mt.ini'
#'mfp-mts-lt.ini'
#'mfp-mts-mt.ini'
#'lsql-lts-lt.ini'
#'lsql-lts-mt.ini'
#'lsql-mts-lt.ini'
#'lsql-mts-mt.ini'
#'nsql-lts-lt.ini'
#'nsql-lts-mt.ini'
#'nsql-mts-lt.ini'
#'nsql-mts-mt.ini'

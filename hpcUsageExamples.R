source("hpcUsageMain.R")

# Example 1: Get the usage data since 2013 and break it down by year, discipline and university system.

ddply(subset(jlog_w_org,year>=2013),c("year","research_area","system"),summarize,Usage=sum(charge))

# Example 2: Get weekly utilization rate in 2018 for QB2.
ddply(subset(jlog_w_org,year==2018),c("week"),summarize,util=sum(charge)/(504*20*24*7))

# Example 3: Count by year the number of new PI's who apply for their first research alloction.
ralloc <- alloc_w_org[alloc_w_org$deposited > 50000,]
ralloc <- ralloc[order(ralloc$year),]
table(ralloc[! duplicated(ralloc$user),c("user","year")]$year)



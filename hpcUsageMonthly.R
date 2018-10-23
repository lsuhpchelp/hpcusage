# This is for the ITS effort of creating a data dashboard 
# for colleges and departments, where metrics for ITS 
# services can be found and consumed.

# Per request of Stephen White.

source("hpcUsageMain.R")

# Cutoff date: 3/1/2017
jrecent <- subset(jlog_w_org,stime >= "2017-03-01")

# Delete the jobs run off the 2000-SU "hpc_startup_*" allocations (<0.1% total usage).
jrecent <- jrecent[! grepl("hpc_startup",jrecent$project),]
jrecent <- jrecent[! grepl("bucket",jrecent$project),]
jrecent <- jrecent[! grepl("admin",jrecent$project),]

monthly <- ddply(jrecent,c("year","month","project"),summarize,usage=sum(charge))
monthly <- subset(monthly,! (year == year(today()) & month == month(today())))

alloc_all <- subset(alloc_w_org,select=c("project","title","name","email","research_area","org"))
merged <- merge(monthly,alloc_all,all.x=T,all=F,by="project",sort=F)
merged <- merged[complete.cases(merged),]
merged <- merged[! duplicated(merged),]
merged <- merged[with(merged,order(year,month)),]

cdate <- gsub("-","",as.character(today())) # today's date
prefix <- gsub("hpc","lsu",prefix) # prefix
csvfile <- paste0(toupper(prefix),"HPC_monthly_usage.",cdate,".csv")
write.csv(merged,file=csvfile,row.names=F)

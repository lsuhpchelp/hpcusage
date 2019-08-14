# change on 6/19/2019:
# 1. In the section of "Assign an institution to each allocation using the PI's email"
#(1) assign "lsu" to woodplc 
#(2) assign "latech" to arprodserv
#(3) assign "other" to missing values (NAs)
#(4) freq table to ensure no more strange name exists, i.e.:
#    table(alloc_w_org$org)  should only show 18 legitimate institutions 

# 2. added a section "Get the city and state for each loni allocation."

# 3. excluded "pi", "title" "description" and "sponsor" from alloc_w_org

# 4. define allocation type (Research vs. Startup) in the alloc_w_org

# 5. use the official name of the supercomputer in the jlog_w_org

# 6. replace missing values in the research_area, email, org, system and region the jlog_w_org

# 7. remove obs with years before 2013 in the alloc_w_org

# 8. output file name change


# Clean up job data.

jlog <- jlog[complete.cases(jlog),]
jlog$stime <- as.POSIXct(jlog$stime,origin='1970-01-01')
jlog$etime <- as.POSIXct(jlog$etime,origin='1970-01-01')
jlog$qtime <- as.POSIXct(jlog$qtime,origin='1970-01-01')
jlog$charge <- jlog$charge/3600
jlog$requested <- jlog$requested/3600
jlog$month <- month(jlog$stime)
jlog$year <- year(jlog$stime)
jlog$quarter <- quarter(jlog$stime, with_year=TRUE)
jlog$week <- week(jlog$stime)

# Clean up allocation data.

alloc$amount <- alloc$amount/3600
alloc$deposited <- alloc$deposited/3600
alloc$used <- as.integer(alloc$deposited - alloc$amount)
alloc$used <- alloc$used/alloc$deposited*100
alloc$quarters <- quarter(as.POSIXct(alloc$start_time,origin='1970-01-01'), with_year=TRUE)
alloc$year <- year(as.POSIXct(alloc$start_time,origin='1970-01-01'))
alloc$user <- tolower(alloc$user)

# Assign an institution to each allocation using the PI's email.
# Note: it's kind of messy, but it's the best we can do for now. It's a problem for LONI only.

alloc_w_org <- merge(alloc,ud,by="user",all.x=T)

if (prefix == "hpc_") {

  alloc_w_org$org <- "lsu"

} else {

  # Clean up the PI affiliation for historical data.
  # This part is hard coded. Check out the result from time to time. 
  # Legitimate institutions:
  # [1] "tulane"     "xula"       "subr"       "uno"        "latech"    
  # [6] "lsus"       "lsu"        "ulm"        "ull"        "nsula"
  #[11] "selu"       "lsuhsc"     "marybird"   "gram"       "lsmsa" 
  #[16] "mcneese"    "pbrc"       "other"

  alloc_w_org$org <- gsub("(anl|army|arcadis-us|buffalo|colostate|indiana|caltech|seahorsecoastal|vims|sura|corning|iit|northeastern|auburn|lehigh|usf|inventherm|vcsu|umassd|gmail|woodplc)","lsu",alloc_w_org$org)
  alloc_w_org$org <- gsub("wisc","subr",alloc_w_org$org)
  alloc_w_org$org <- gsub("(usach|dqsi|uark)","uno",alloc_w_org$org)
  alloc_w_org$org <- gsub("(icnanotox|af|^uh$|famu|umass|arprodserv)","latech",alloc_w_org$org)
  alloc_w_org$org <- gsub("louisiana","ull",alloc_w_org$org)
  alloc_w_org$org <- gsub("sandia","tulane",alloc_w_org$org)
  alloc_w_org$org <- gsub("mpg","other",alloc_w_org$org)
  alloc_w_org$org[is.na(alloc_w_org$org)]<-"other"

  alloc_w_org$org <- tolower(alloc_w_org$org)
}

# freq table to ensure no more strange name exists, i.e.: 
table(alloc_w_org$org)  # should only show 18 legitimate institutions

# Get the system for each allocation.

# LSU: lsus,lsu,lsuhsc,marybird,pbrc
# SU: subr
# LACIU: tulane,xula
# ULL: uno,latech,ulm,ull,selu,gram,mcneese,nsula
# Other: lsmsa,other
alloc_w_org$system <- mapvalues(alloc_w_org$org,
        from = c("lsus","lsu","lsuhsc","marybird","pbrc","subr","tulane","xula","uno","latech","ulm","ull","selu","gram","mcneese","nsula","lsmsa","other"),
        to = c(rep("lsu",5), "su", rep("laciu",2), rep("ull",8), rep("other",2))
)

# Get the region for each allocation.

# Northla: latech, lsus, ulm, nsula, lsuhsc, gram, lsmsa, 
# Southla: tulane, xula, subr,uno, lsu, ull, selu, marybird, mcneese, pbrc
# Other: other

alloc_w_org$region <- mapvalues(alloc_w_org$org,
        from = c("latech", "lsus", "ulm", "nsula", "lsuhsc", "gram", "lsmsa", "tulane", "xula", "subr", "uno", "lsu", "ull", "selu", "marybird", "mcneese", "pbrc", "other"),
        to = c(rep("north",7),rep("south",10),"other")
)

# Get the city and state for each loni allocation.

# Ruston: latech 
# Shreveport: lsus
# Monroe: ulm 
# Natchitoches: nsula, lsmsa
# New Orleans: lsuhsc, uno, tulane, xula
# Grambling: gram, 
# Baton Rouge: lsu, subr, pbrc, marybird
# Lafayette: ull 
# Hammond: selu 
# Lake Charles: mcneese 
# Grand Isle: other
if (prefix == "loni_") {
alloc_w_org$city <- mapvalues(alloc_w_org$org,
        from = c("latech", "lsus", "ulm", "nsula", "lsmsa", "lsuhsc", "uno", "tulane", "xula", "gram", "subr",  "lsu", "pbrc", "marybird", "ull", "selu", "mcneese",  "other"),
        to = c("Ruston","Shreveport","Monroe",rep("Natchitoches",2),rep("New Orleans",4),"Grambling",rep("Baton Rouge",4),"Lafayette","Hammond", "Lake Charles","Grand Isle")
)

alloc_w_org$state <- "Louisiana"
} 

# Assgin a discipline to each allocation.
# 1: Physics
# 2: Chemistry
# 3: Computer science and engineering
# 4: Biological sciences
# 5: Geoscience
# 6: Engineering
# 7: Material sciences

alloc_w_org[is.na(alloc_w_org$area1),]$area1 <- 1000
alloc_w_org[alloc_w_org$area1 >= 150 & alloc_w_org$area1 < 200,]$area1 <- 700
alloc_w_org[alloc_w_org$area1 >= 140 & alloc_w_org$area1 < 150,]$area1 <- 200
alloc_w_org$area <- as.numeric(alloc_w_org$area1) %/% 100
mapping = data.frame(key=c(1,2,3,4,5,6,7,8,9,10),area=c('Physics','Chemistry','Computer science and engineering','Biological sciences','Geosciences','Engineering','Material sciences',rep('Not specified',3)))
alloc_w_org$research_area <- with(mapping,area[match(alloc_w_org$area,key)])

# exclude "pi", "title" "description" and "sponsor" columns 
alloc_w_org <- alloc_w_org[,-c(7,9,14,24)]

# define allocation type
alloc_w_org$type <- "Research"
for(i in 1:nrow(alloc_w_org)){
if (alloc_w_org$deposited[i] <= 50000) {

  alloc_w_org$type[i] <- "Startup"
  }
}


# Trim the allocation data frame.
# Le Yan (8/14/2019): preserver the pi information from the alloc data frame so later each job will have a pi as well.

alloc_lean <- subset(alloc_w_org,select=c("user","name","project","org","email","system","region","research_area"))
alloc_lean <- alloc_lean[! duplicated(alloc_lean),]
names(alloc_lean)[1] <- "pi"

# Merge the jobs and allocation data frames.

jlog_w_org <- merge(jlog,alloc_lean,by="project",all.x=T)
jlog_w_org <- jlog_w_org[! duplicated(jlog_w_org),]


# Use the official name of the supercomputer
if (prefix == "hpc_") {

  jlog_w_org$machine=gsub("Dell_Cluster","Tezpur",jlog_w_org$machine) 
  jlog_w_org$machine=gsub("mike2","SuperMike-II",jlog_w_org$machine) 
  jlog_w_org$machine=gsub("supermic.cct-lsu.xsede","SuperMIC",jlog_w_org$machine) 

} else {

  jlog_w_org$machine=gsub("Dell_Cluster","Eric and others",jlog_w_org$machine) 
  jlog_w_org$machine=gsub("p5-575","Not specified",jlog_w_org$machine) 
  jlog_w_org$machine=gsub("queenbee.loni-lsu.teragrid","Queenbee2",jlog_w_org$machine) 
}

# Replace missing values in the research_area, email, org, system and region

jlog_w_org$research_area[is.na(jlog_w_org$research_area)]<-"Not specified"
jlog_w_org$email[is.na(jlog_w_org$email)]<-"Not specified"
jlog_w_org$org[is.na(jlog_w_org$org)]<-"Not specified"
jlog_w_org$system[is.na(jlog_w_org$system)]<-"Not specified"
jlog_w_org$region[is.na(jlog_w_org$region)]<-"Not specified"

# Remove observations with years before 2013

alloc_w_org <- alloc_w_org[alloc_w_org$year > 2012,]
jlog_w_org <- jlog_w_org[jlog_w_org$year > 2012,]

# Dump the allocation and job data frame into CSV files as the data source for  other applications such as Tableau.
cdate <- gsub("-","",as.character(today()))
fprefix <- gsub("hpc","lsu",prefix)

# allocfile and jobfile are for back-up with date in the file name
# allocfile2 and jobfile2 are for use in Tableau (unique name w/o date)
allocfile <- paste0(toupper(fprefix),"HPC_allocation_log.",cdate,"_clean",".csv")
allocfile2 <- paste0(toupper(fprefix),"HPC_allocation_log","_clean",".csv")
jobfile <- paste0(toupper(fprefix),"HPC_job_log.",cdate,"_clean",".csv")
jobfile2 <- paste0(toupper(fprefix),"HPC_job_log","_clean",".csv")

write.csv(alloc_w_org,file=allocfile,row.names=F,quote=F)
write.csv(alloc_w_org,file=allocfile2,row.names=F,quote=F)
write.csv(jlog_w_org,file=jobfile,row.names=F,quote=F)
write.csv(jlog_w_org,file=jobfile2,row.names=F,quote=F)



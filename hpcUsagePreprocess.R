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
  # This part is hard coded.
  # Legitimate institutions:
  # [1] "tulane"     "xula"       "subr"       "uno"        "latech"    
  # [6] "lsus"       "lsu"        "ulm"        "ull"        "nsula"
  #[11] "selu"       "lsuhsc"     "marybird"   "gram"       "lsmsa" 
  #[16] "mcneese"    "pbrc"       "other"

  alloc_w_org$org <- gsub("(anl|army|arcadis-us|buffalo|colostate|indiana|caltech|seahorsecoastal|vims|sura|corning|iit|northeastern|auburn|lehigh|usf|inventherm|vcsu|umassd|gmail)","lsu",alloc_w_org$org)
  alloc_w_org$org <- gsub("wisc","subr",alloc_w_org$org)
  alloc_w_org$org <- gsub("(usach|dqsi|uark)","uno",alloc_w_org$org)
  alloc_w_org$org <- gsub("(icnanotox|af|^uh$|famu|umass)","latech",alloc_w_org$org)
  alloc_w_org$org <- gsub("louisiana","ull",alloc_w_org$org)
  alloc_w_org$org <- gsub("sandia","tulane",alloc_w_org$org)
  alloc_w_org$org <- gsub("mpg","other",alloc_w_org$org)

  alloc_w_org$org <- tolower(alloc_w_org$org)

}

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

# Trim the allocation data frame.

alloc_lean <- subset(alloc_w_org,select=c("project","org","email","system","region","research_area"))
alloc_lean <- alloc_lean[! duplicated(alloc_lean),]

# Merge the jobs and allocation data frames.

jlog_w_org <- merge(jlog,alloc_lean,by="project",all.x=T)
jlog_w_org <- jlog_w_org[! duplicated(jlog_w_org),]

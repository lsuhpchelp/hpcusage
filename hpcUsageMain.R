options(stringsAsFactors=F)

# Load libraries.
library(stringr)
library(plyr)
library(lubridate)

# LONI or LSU HPC by parsing the host name.
org <- unlist(strsplit(system("hostname -a",intern=T),".",fixed=T))[2]
prefix <- paste0(org,"_")

# Get user information (uid, name, email, institution) from LDAP dump files.
source("hpcUsageGetUser.R")

# Connect and dump data from the Gold database.
source("hpcUsageGoldDump.R")

# Clean up and preprocess the dumped data.
source("hpcUsagePreprocess.R")

# Now we should have these dataframes for futher processing:
# reviewList: research allocations waiting to be reviewed; 
# alloc_w_org: all allocations with start time, size, pi, institution, system etc.
# jlog_w_org: all jobs with start time, charge, allocation, pi, institution, system etc.

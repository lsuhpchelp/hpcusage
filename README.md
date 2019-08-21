# HPC usage statistics
R code for the processing of HPC usage data for LONI and LSU HPC.

Note: the passwords for the gold database can only be found on HPC clusters. NEVER include them here!

How to use:
1. Find the password for the Gold database on HPC clusters and put them in a file "hpcUsage.conf", whose content should be like this:  

hpc_password => xxxxxxxxxxxxx  
loni_password => xxxxxxxxxxxxx  

2. Launch the R console on any LONI or HPC cluster;
3. At the prompt, run `source("hpcUsageExamples.R")`.

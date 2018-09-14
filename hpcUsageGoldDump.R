# Connect to gold database
if (prefix == "loni_") {
  # For LONI
  library(RMySQL)
  drv = dbDriver("MySQL")
  myconn = dbConnect(drv, user="gold", dbname="gold", host="gold04.hpc.lsu.edu", password="<you need to insert this>")
} else if (prefix == "hpc_") {
  # For HPC
  library(RPostgreSQL)
  drv = dbDriver("PostgreSQL")
  myconn = dbConnect(drv, user="gold", dbname="gold", host="postgres.cct.lsu.edu", password="<you need to insert this>")
} else {
  stop("Error: the prefix has to be hpc or loni!")
}

# SQL query for jobs
qpen <- "
select  g_job_id as id,
        g_user as user,
        g_charge as charge, 
        g_start_time as stime, 
        g_end_time as etime,
        g_queue as queue,
        g_nodes as nodes,
        g_processors as cores,
        g_project as project,
        g_machine as machine, 
        g_queue_time as qtime,
        g_requested_wall as requested
from g_job 
where g_deleted='False'
"
jlog <- dbGetQuery(myconn,qpen)

#SQL query for allocations
qpen <- paste0("
select sum(a.g_amount) as amount,
       sum(a.g_deposited) as deposited,
       a.g_start_time as start_time,
       a.g_end_time as end_time,
       p.g_name as project,
       sc.pi as pi,
       sc.username as user,
       sc.alloc_id as id,
       sc.researcharea1 as area1,
       sc.researcharea2 as area2,
       sc.researcharea3 as area3,
       sc.commercial as com,
       sc.descresearch as description,
       c.g_name as cgname,
       ap.g_account as ap_project
  from g_allocation a,
       g_project p,
       g_account c,
       scss_allocationsform sc,
       g_account_project ap
 where a.g_account = c.g_id
   and concat('",prefix,"',sc.pname) = p.g_name
   and sc.status = 'approved'
   and ap.g_name = p.g_name
   and a.g_deleted = 'False'
   and a.g_deposited > 0
   and ap.g_account = a.g_account
 group by p.g_name,
          a.g_start_time,
          a.g_end_time,
          sc.pi,
          sc.username,
          sc.alloc_id,
          c.g_name,
          sc.researcharea1,
          sc.researcharea2,
          sc.researcharea3,
        sc.commercial,
        sc.descresearch,
          c.g_name,
          ap.g_account
 order by ap.g_account
")

alloc <- dbGetQuery(myconn,qpen)

# Get the list of allocation requests waiting to be reviewed.
qpen <- "
select  distinct pname,pi,
        alloc_id,alloc_title,
        su_requested as su, 
        username, 
        machines 
from    scss_allocationsform
where   status = 'review'
"

reviewList <- dbGetQuery(myconn,qpen)

# Disconnect from the database server.

dbDisconnect(myconn)
dbUnloadDriver(drv)


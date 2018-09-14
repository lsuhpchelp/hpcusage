# Read uid, given name and email addresses from Sam's LDAP dump files.
# This should be a temporary measure until user data can be pulled directly from LDAP.

print("Do not forget to get the latest LDAP dump!!!\n")

# Sam's LDAP dump file:
fdump <- paste0(substr(prefix,1,nchar(prefix)-1),"dump.txt")

# Read data from the LDAP dump.
ldump <- readLines(fdump)
lstdump <- sapply(ldump,function(x) strsplit(x,'|',fixed=T))
d <- do.call(rbind.data.frame, lstdump)

# Keep only uid, name and email of users
ud <- d[,c(1,5,10)]
colnames(ud) <- c("user","name","email")

# Use email to get instituion.
ud$org <- tolower(unlist(lapply(strsplit(ud$email,"@|\\."),function(x) rev(x)[2])))

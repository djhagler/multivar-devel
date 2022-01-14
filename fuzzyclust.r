# fuzzyclust.r
#
# usage =  R --file fuzzyclust.r --args fname_data k membexp runs outdir forceflag maxattempts alpha
#
# Created:  04/17/17 by Don Hagler
# Last Mod: 04/18/17 by Don Hagler
#
# use version R2.10
#
# Based on code by Chi-Hua Chen
#

###########################################################

library(MCMCpack) # needs this library to run!  run install.packages
library(cluster)

###########################################################

opts = commandArgs(trailingOnly = TRUE);

fname_data = 'distmat.txt'
k = 2
membexp = 1.27
runs = 1
outdir = getwd()
forceflag = FALSE
maxattempts = 5
alpha = 1 # concentration parameter for Dirichlet distribution

if (length(opts)>0) {
  fname_data = opts[1]
}
if (length(opts)>1) {
  k = as.numeric(opts[2])
}
if (length(opts)>2) {
  membexp = as.numeric(opts[3])
}
if (length(opts)>3) {
  runs = as.numeric(opts[4])
}
if (length(opts)>4) {
  outdir = opts[5]
}
if (length(opts)>5) {
  forceflag = as.logical(opts[6])
}
if (length(opts)>6) {
  maxattempts = as.numeric(opts[7])
}
if (length(opts)>7) {
  alpha = as.numeric(opts[8])
}

###########################################################

print(sprintf("loading data from %s...",fname_data))
disttab = read.table(fname_data)
distmat = as.dist(disttab)
dm = dim(disttab)
n = dm[1]

###########################################################

dir.create(outdir,showWarnings=FALSE,recursive=TRUE)

outstem = sprintf("clust%d_membexp%0.2f_runs%d",k,membexp,runs)
fname_clust = sprintf("%s/%s_clusters.txt",outdir,outstem)
fname_silh = sprintf("%s/%s_silhouette.txt",outdir,outstem)

if (!file.exists(fname_clust) || !file.exists(fname_silh) || forceflag) {
  print(paste("running fuzzy clusters for",k,"..."))
  p = matrix(0, n, k)
  obj = matrix(0,1,runs) # container for objective function values
  alphavec = rep(alpha,k) # concentration parameter for Dirichlet distribution
  f = list(); # temporarily contains all the solutions produced by fanny for a certain k
  converged_once = FALSE
  for (j in 1:runs) {
    converged = FALSE
    nattempts = 0
    while (converged==FALSE) {    
      print(paste("cluster=",k,"run=",j,sep=" "))
      for (i in 1:n) {
        p[i,] = rdirichlet(1, alphavec)
      }
      f[[j]] = fanny(distmat, k, memb.exp = membexp, iniMem.p = p)
      obj[j] = f[[j]][["objective"]][["objective"]] # extract objective function value for each run
      converged = f[[j]][["convergence"]][["converged"]]
      if (converged==FALSE) {
        nattempts = nattempts + 1
        if (nattempts>=maxattempts) {
          print(sprintf('WARNING: failed to converge after %d attempts, quitting.',nattempts))
          break
        }
        print("failed to converge, retrying...")
      } else {
        converged_once = TRUE
      }
    }
  }
  if (converged_once==TRUE) {
    q = which(obj == min(obj), arr.ind = TRUE) # find index of minimum of the objective function
    q = q[2]
    mean_obj = apply(obj,1,mean)
    stdev_obj = apply(obj,1,sd)
    membership = f[[q]][["membership"]]
    silhouette = f[[q]][["silinfo"]]$avg.width
    write.table(membership,fname_clust)
    write(silhouette, file = fname_silh, append = FALSE, sep = " ")
  }
}

###########################################################

#quit("no",1,FALSE)



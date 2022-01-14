######################################
# get parameters from command line
######################################

# initialize parameters
p = 1
q = 2
fname_reg = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_surf/output/diff_batch/multivar_MD1wg_sm_surf_surf_diff_reg.csv"
fname_dat = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_surf/output/diff_batch/multivar_MD1wg_sm_surf_surf_diff_data.dat"
outdir = "./output"
outstem = "output"
outfix = 'univar_diff_stats'

# get input parameters
opts = commandArgs(trailingOnly = TRUE);
k = 0
if (length(opts)>k) {
  p = as.integer(opts[k+1])
}
k = k + 1
if (length(opts)>k) {
  q = as.integer(opts[k+1])
}
k = k + 1
if (length(opts)>k) {
  fname_reg = opts[k+1]
}
k = k + 1
if (length(opts)>k) {
  fname_dat = opts[k+1]
}
k = k + 1
if (length(opts)>k) {
  outdir = opts[k+1]
}
k = k + 1
if (length(opts)>k) {
  outstem = opts[k+1]
}
k = k + 1
if (length(opts)>k) {
  outfix = opts[k+1]
}
k = k + 1

######################################
# set other parameters
######################################

measlist = c()
measlist = c(measlist,"thick","area","sulc")
measlist = c(measlist,"FA_wm","LD_wm","TD_wm","T2w_wm","T1w_wm")
measlist = c(measlist,"FA_gm","LD_gm","TD_gm","T2w_gm","T1w_gm")
nmeas = length(measlist)

######################################
# load regressors
######################################

reg = read.csv(paste0(fname_reg), header = T)

######################################
# load data
######################################

fid = file(paste0(fname_dat), "rb")
ndims = readBin(fid, "integer", n=1, size=4, endian="little")
nv = matrix(0,1,ndims)
for (j in 1:ndims) {
  nv[j] = readBin(fid, "integer", n=1, size=4, endian="little")
}
nvals = prod(nv)
a = readBin(fid, "double", n=nvals, endian="little")
close(fid)
dat = array(a, dim = nv)
nverts = nv[1]

if (nmeas != nv[2]) {
  cat("ERROR: length of measlist does not match 2nd dim of data")
  q(save = "no", status = 1)
}

######################################
# difference stats for pairs of vertices
######################################

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

age = reg$Age_At_IMGExam
age = age - min(age) # subtract age by 3
age2 = age^2

# initialize output
n = length(p:q)
F.vals = array(NA, dim = c(n,nverts,nmeas))
p.vals = array(NA, dim = c(n,nverts,nmeas))

# loop over measures
for (m in 1:nmeas) {
  # loop over vertices p to q
  cat(sprintf("calculating for meas %s...\n",measlist[m]))
  for (k in 1:n) {
    i = p + k - 1
    cat(sprintf("calculating for vertex %i...\n",i))
    dat1 = dat[i,m,]
    # loop over all vertices
    for (j in 1:nverts) {
      if (i != j) {
        dat2 = dat[j,m,]
        dat.diff = as.vector(dat1 - dat2)
        # baseline model
        fit_base <- lm(dat.diff ~ DeviceSerialNumber + Gender 
                    + FDH_3_Household_Income + FDH_Highest_Education
                        + GAF_africa + GAF_amerind + GAF_eastAsia
                        + GAF_oceania + GAF_centralAsia, data = reg)
        # baseline model + age + age2
        fit_age <- lm(dat.diff ~ age + age2
                      + DeviceSerialNumber + Gender 
                    + FDH_3_Household_Income + FDH_Highest_Education
                        + GAF_africa + GAF_amerind + GAF_eastAsia
                        + GAF_oceania + GAF_centralAsia, data = reg)
        # likelihood ratio
        lrt_age = anova(fit_base, fit_age)
        F.vals[k,j,m] = lrt_age[2,5]
        p.vals[k,j,m] = lrt_age[2,6]
      } else {
        F.vals[k,j,m] = 0
        p.vals[k,j,m] = 1
      }
    }
  }
}

# save F to binary file
fname_out = sprintf("%s/%s_%s_F.dat",outdir,outstem,outfix)
B = F.vals
b = as.vector(B)
nb = dim(B)
nd = length(nb)
fid = file(fname_out, "wb")
writeBin(nd, fid)
for (k in nb) {
  writeBin(k, fid)
}
writeBin(b, fid)
close(fid)

# save p to binary file
fname_out = sprintf("%s/%s_%s_p.dat",outdir,outstem,outfix)
B = p.vals
b = as.vector(B)
nb = dim(B)
nd = length(nb)
fid = file(fname_out, "wb")
writeBin(nd, fid)
for (k in nb) {
  writeBin(k, fid)
}
writeBin(b, fid)
close(fid)


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
outfix = 'multivar_diff_stats'
gender_flag = TRUE

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
if (length(opts)>k) {
  gender_flag = as.logical(opts[k+1])
}
k = k + 1

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

######################################
# difference stats for pairs of vertices
######################################

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

age = reg$Age_At_IMGExam
age = age - min(age) # subtract age by 3
age2 = age^2

# initialize output
n = length(p:q)
Pillai.vals = matrix(NA,n,nverts)
F.vals = matrix(NA,n,nverts)
p.vals = matrix(NA,n,nverts)

# loop over vertices p to q
for (k in 1:n) {
  i = p + k - 1
  
  cat(sprintf("calculating for vertex %i...\n",i))
  
  dat1 = dat[i,,]
  
  # todo: use apply for vectorized calculation?
  
  # loop over all vertices
  for (j in 1:nverts) {
    if (i != j) {
      dat2 = dat[j,,]
      dat.diff = t(as.matrix(dat1 - dat2))

      if (gender_flag) {

        # baseline model
        fit_base <- manova(dat.diff ~ DeviceSerialNumber + Gender
                      + FDH_3_Household_Income + FDH_Highest_Education
                      + GAF_africa + GAF_amerind + GAF_eastAsia
                      + GAF_oceania + GAF_centralAsia, data = reg)

        # baseline model + age + age2
        fit_age <- manova(dat.diff ~ age + age2
                      + DeviceSerialNumber + Gender
                      + FDH_3_Household_Income + FDH_Highest_Education
                      + GAF_africa + GAF_amerind + GAF_eastAsia
                      + GAF_oceania + GAF_centralAsia, data = reg)
      } else {

        # baseline model
        fit_base <- manova(dat.diff ~ DeviceSerialNumber
                      + FDH_3_Household_Income + FDH_Highest_Education
                      + GAF_africa + GAF_amerind + GAF_eastAsia
                      + GAF_oceania + GAF_centralAsia, data = reg)

        # baseline model + age + age2
        fit_age <- manova(dat.diff ~ age + age2
                      + DeviceSerialNumber
                      + FDH_3_Household_Income + FDH_Highest_Education
                      + GAF_africa + GAF_amerind + GAF_eastAsia
                      + GAF_oceania + GAF_centralAsia, data = reg)
      
      }

      # likelihood ratio
      lrt_age = anova(fit_base, fit_age)
      
      # save results for vertex pair combination
      Pillai.vals[k,j] = lrt_age[2,4]
      F.vals[k,j] = lrt_age[2,5]
      p.vals[k,j] = lrt_age[2,8]
    } else {
      Pillai.vals[k,j] = 0
      F.vals[k,j] = 0
      p.vals[k,j] = 1
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

# save Pillai to binary file
fname_out = sprintf("%s/%s_%s_Pillai.dat",outdir,outstem,outfix)
B = Pillai.vals
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


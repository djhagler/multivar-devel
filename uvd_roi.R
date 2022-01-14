######################################
# get parameters from command line
######################################

# initialize parameters
fname_reg = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff/output/MDwg_aparc_sel_multivar_reg.csv"
fname_dat = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_ROI/output/MDwg_aparc_sel_multivar_pericalcarine_vs_caudalmiddlefrontal.csv"
outdir = "./output"
outstem = "MDwg_aparc_sel_pericalcarine_vs_caudalmiddlefrontal"
outfix = 'univar_diff_stats'

# get input parameters
opts = commandArgs(trailingOnly = TRUE);
k = 0
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
measlist = c(measlist,"FA_gm","FA_wm")
measlist = c(measlist,"MD_gm","MD_wm")
measlist = c(measlist,"LD_gm","LD_wm")
measlist = c(measlist,"TD_gm","TD_wm")
measlist = c(measlist,"T1w_gm","T1w_wm")
measlist = c(measlist,"T2w_gm","T2w_wm")
measlist = c(measlist,"area")
measlist = c(measlist,"thick")
measlist = c(measlist,"sulc")

######################################
# load regressors and data
######################################

reg = read.csv(paste0(fname_reg), header = T)
dat = read.csv(paste0(fname_dat), header = T)

######################################
# difference stats for set of input files (A & B)
######################################

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

fname_out = paste0(outdir,"/",outstem,"_",outfix,".csv")

age = reg$Age_At_IMGExam
age = age - min(age) # subtract age by 3
age2 = age^2

dat.diff = as.matrix(dat)

F.vals = c()
p.vals = c()

for(ii in 1:length(measlist)){
  m.diff = dat.diff[,ii]
  # baseline model
  fit_base <- lm(m.diff ~ DeviceSerialNumber + Gender 
              + FDH_3_Household_Income + FDH_Highest_Education
                  + GAF_africa + GAF_amerind + GAF_eastAsia
                  + GAF_oceania + GAF_centralAsia, data = reg)
  # baseline model + age + age2
  fit_age <- lm(m.diff ~ age + age2
                + DeviceSerialNumber + Gender 
              + FDH_3_Household_Income + FDH_Highest_Education
                  + GAF_africa + GAF_amerind + GAF_eastAsia
                  + GAF_oceania + GAF_centralAsia, data = reg)
  # likelihood ratio
  lrt_age = anova(fit_base, fit_age)
  F.vals[ii] = lrt_age[2,5]
  p.vals[ii] = lrt_age[2,6]
}

# create table
matrix = cbind(measlist,F.vals,p.vals)
colnames(matrix) = c("meas","F","p")

# save as csv file
write.csv(matrix, file = fname_out, row.names = FALSE)


######################################
# get parameters from command line
######################################

# initialize parameters
fname_reg = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_ROI/output/MDwg_aparc_sel_multivar_reg.csv"
fname_dat = "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_ROI/output/MDwg_aparc_sel_multivar_pericalcarine_vs_caudalmiddlefrontal.csv"
outdir = "./output"
outstem = "MDwg_aparc_sel_pericalcarine_vs_caudalmiddlefrontal"
outfix = 'multivar_diff_stats'

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
# likelihood ratio
lrt_age = anova(fit_base, fit_age)
# save results for roi combination
Pillai.val = lrt_age[2,4]
F.val = lrt_age[2,5]
p.val = lrt_age[2,8]

# create table
matrix = cbind(Pillai.val,F.val,p.val)
colnames(matrix) = c("Pillai","F","p")

# save as csv file
write.csv(matrix, file = fname_out, row.names = FALSE)


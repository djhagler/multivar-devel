######################################
# get parameters from command line
######################################

# initialize parameters
instem = "MDwg_aparc_sel"
forceflag = FALSE

# get input parameters
opts = commandArgs(trailingOnly = TRUE);

if (length(opts)>0) {
  instem = opts[1]
}
if (length(opts)>1) {
  forceflag = as.logical(opts[2])
}

######################################
# set other parameters
######################################

rootdir <- "/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_ROI"
instem_info <- "merged_broca_vs_premotor_plus_demog2.csv"
outfix = 'multivar'

indir <- paste0(rootdir,"/data")
outdir <- paste0(rootdir,"/output")

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
# load demographics data
######################################

d = read.csv(paste0(indir,"/",instem_info), header = T)
d = d[,c(1,20:29)]
d = d[complete.cases(d),]
regnames = names(d)

######################################
# difference stats for each set of input files
######################################

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

full_indir = paste0(indir,"/",instem)
outstem = instem
fname_reg = paste0(outdir,"/",outstem,"_",outfix,"_reg.csv")
fname_dat = paste0(outdir,"/",outstem,"_",outfix,"_dat.csv")

if (!file.exists(fname_reg) || !file.exists(fname_dat) || forceflag) {
  setwd(full_indir)
  
  # file names    
  all_files = list.files()
  all_files = all_files[grepl(".csv",all_files)]
  files = c()
  for(ii in 1:length(measlist)){
    files = c(files,all_files[grepl(measlist[ii],all_files)])
  }
  
  # load all files with merge by intersection
  d1 = read.csv(files[1], header = T)
  dat.all = merge(d,d1, by = "VisitID")
  for(ii in 2:length(files)){
    dat.merge = read.csv(files[ii], header = T)
    dat.all = merge(dat.all,dat.merge, by = "VisitID")
  }
  
  # average lh & rh
  lh = dat.all[,grepl("lh",names(dat.all))]
  rh = dat.all[,grepl("rh",names(dat.all))]
  dat = (lh + rh)/2
  split = strsplit(names(dat), "[.]")
  names(dat) = unlist(lapply(split,
                    function(x){paste(x[c(1,3)],collapse = '.')}))
                    
  # regressors
  reg = dat.all[,regnames]
  
  # save as csv files
  setwd(outdir)
  write.csv(reg, file = fname_reg, row.names = FALSE)
  write.csv(dat, file = fname_dat, row.names = FALSE)
}

dat = read.csv(fname_dat, header = T)
split = strsplit(names(dat), "[.]")
rois = unique(sapply(split, function(x) {paste(x[1])}))
  
for(ii in 1:length(rois)){
  roiname = rois[ii]
  fname_roi = paste0(outdir,"/",outstem,"_",outfix,"_",roiname,".csv")
  if (!file.exists(fname_roi) || forceflag) {
    roi_dat = dat[,grepl(roiname,names(dat))]
    write.csv(roi_dat, file = fname_roi, row.names = FALSE)
  }
}


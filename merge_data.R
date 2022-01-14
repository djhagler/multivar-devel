merge_mvdev_data <- function(rootdir,instem_info,outfix_data,instem_data,infix_data,measlist,forceflag){
	
  indir <- paste0(rootdir,"/data")
  outdir <- paste0(rootdir,"/output")
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
	
  # load demographics data
  d = read.csv(paste0(indir,"/",instem_info), header = T)
  d = d[,c(1,20:29)]
  d = d[complete.cases(d),]
	
  # load data for set of input files
  full_indir = paste0(indir,"/",instem_data)
  outstem = instem_data
  fname_merged = paste0(outdir,"/",outstem,"_",outfix_data,".csv")
  
  if (!file.exists(fname_merged) || forceflag) {
	setwd(full_indir)
	
	# file names	  
	all_files = list.files()
	all_files = all_files[grepl(".csv",all_files)]
    files = c()
    for(ii in 1:length(measlist)){
  		files = c(files,all_files[grepl(sprintf("%s_%s",measlist[ii],infix_data),all_files)])
	}
	  
	# load all files with merge by intersection
	d1 = read.csv(files[1], header = T)	  
	dat.all = merge(d,d1, by = "VisitID")
	for(ii in 2:length(files)){
		dat.merge = read.csv(files[ii], header = T)
		dat.all = merge(dat.all,dat.merge, by = "VisitID")
	}
	
	# save merged data table to csv file
    setwd(outdir)
    write.csv(dat.all, file = fname_merged, row.names = FALSE)
  
  } else {
    setwd(outdir)
  	dat.all = read.csv(fname_merged, header = T)
  }

  return(dat.all)
}


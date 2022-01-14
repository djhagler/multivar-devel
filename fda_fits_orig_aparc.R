######################################
## set parameters
######################################

rootdir <- "/Users/dhagler/Documents/papers/multivar_devel/fits"
instem_info <- "merged_broca_vs_premotor_plus_demog2.csv"
outfix = "orig"
infix = "resid"
instem_data_list = c("MD1wg_aparc_resid")
pwidth = 3.5
pheight = 2.4
agelabel = "Age_At_IMGExam"
legendflag = FALSE
labelflag = FALSE
#legendflag = TRUE
#labelflag = TRUE
forceflag = FALSE

indir <- paste0(rootdir,"/data")
outdir <- paste0(rootdir,"/output")

measlist = c()
measlist = c(measlist,"FA_gm","FA_wm")
measlist = c(measlist,"LD_gm","LD_wm")
measlist = c(measlist,"MD_gm","MD_wm")
measlist = c(measlist,"TD_gm","TD_wm")
measlist = c(measlist,"T1w_gm","T1w_wm")
measlist = c(measlist,"T2w_gm","T2w_wm")
measlist = c(measlist,"area")
measlist = c(measlist,"thick")
measlist = c(measlist,"sulc")

# plot colors
cols =     c("red2",     "green3",   "blue",          "yellow2")
colshade = c("violetred2","palegreen","dodgerblue", "khaki1")

######################################
## add packages
######################################

require(fda)

######################################
## define functions
######################################

# resample data
resampler <- function(data) {
  n <- nrow(data)
  resample.rows <- sample(1:n,size=n,replace=TRUE)
  return(data[resample.rows,])
}
# estimate spline
spline.estimator <- function(data,m=300) {
  fit <- smooth.basis(argvals=data[,1],y=data[,2],bbasis)$fd  # need to change in the loop
  eval.grid <- seq(from=min(data[,1]),to=max(data[,1]),length.out=m)
  return(eval.fd(eval.grid, fit)) # We only want the predicted values
}
# confidence intervals
spline.cis <- function(data,B,alpha=0.05,m=300) {
  spline.main <- spline.estimator(data,m=m)
  spline.boots <- replicate(B,spline.estimator(resampler(data),m=m))  # bootstrap
  cis.lower <- 2*spline.main - apply(spline.boots,1,quantile,probs=1-alpha/2)
  cis.upper <- 2*spline.main - apply(spline.boots,1,quantile,probs=alpha/2)
  return(list(main.curve=spline.main,lower.ci=cis.lower,upper.ci=cis.upper,
              x=seq(from=min(data[,1]),to=max(data[,1]),length.out=m)))
}
# transparent colors in plots
t_col <- function(color, percent = 50, name = NULL) {
  #	  color = color name, percent = % transparency
  ## Get RGB values for named color
  rgb.val <- col2rgb(color)
  ## Make new color using input color as base and alpha set by transparency
  t.col <- rgb(rgb.val[1], rgb.val[2], rgb.val[3],
               max = 255,
               alpha = (100-percent)*255/100,
               names = name)
  ## Save the color
  invisible(t.col)
}

######################################
# plots for each set of input files
######################################

for(kk in 1:length(instem_data_list)){
	## load data files	
	instem_data = instem_data_list[kk]
	full_indir = paste0(indir,"/",instem_data)
	outstem = instem_data
	setwd(full_indir)
	all_files = list.files()
	all_files = all_files[grepl(paste0(infix,".csv"),all_files)]
	files = c()
	for(ii in 1:length(measlist)){
		files = c(files,all_files[grepl(measlist[ii],all_files)])
	}
	all = lapply(files, read.csv)
	files.short = unlist(lapply(files, function(x){gsub(".csv","",x)}))
	nfiles = length(files.short)
		
	# merge all to get intersectional list of subjects
	d1 = all[[1]]
	d1[,grepl(agelabel,names(d1))] = NULL
	dat.all = merge(d,d1, by = "VisitID")
	for(ii in 2:length(files)){
		d2 = all[[ii]]
		d2[,grepl(agelabel,names(d2))] = NULL
		dat.all = merge(dat.all,d2, by = "VisitID")
	}
	all_VisitIDs = dat.all[,"VisitID", drop=FALSE]

	## spline fits
	dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
	datafile <- paste0(outdir,"/",outstem,"_fda_fits.Rdata")
	if (!file.exists(datafile) || forceflag) {
		sp.cis = list()
		range = list()
		dat.list = list()
		age.list = list()
		## calculate splines for each data file
		ptm <- proc.time()		
		for(jj in 1:length(files)){
		  dat = all[[jj]]
		  # merge with list of intersectional subjects
		  dat = merge(dat,all_VisitIDs, by = "VisitID")
		  # get age		  
		  age.list[[jj]] = dat[,grepl(agelabel,names(dat))]
		  age = age.list[[jj]]
		  ## create bspline
		  rangeval = range(age)
		  bbasis = create.bspline.basis(rangeval, nbasis = 5, norder = 4)
		  ## average left and right
		  lh = dat[,grepl("lh",names(dat))]
		  rh = dat[,grepl("rh",names(dat))]
		  avg = (lh + rh)/2
		  split = strsplit(names(avg), "[.]")
		  names(avg) = unlist(lapply(split, function(x){paste(x[c(1,3)],collapse = '.')}))
		  
		  # save into dat.list
		  dat.list[[jj]] = avg

		  sp.cis[[jj]] = list()
		  range[[jj]] = list()
		  for(ii in 1:length(avg)){
		    data = data.frame(x = age, y=avg[,ii])
		    sp.cis[[jj]][[ii]] <- spline.cis(data , B=1000 , alpha=0.05)
		    range[[jj]][[ii]] = range(sp.cis[[jj]][[ii]][c("lower.ci","upper.ci")])
		  }
		}
		proc.time() - ptm		
#		save.image(file=datafile)
		save(sp.cis,range,dat.list,age.list,file=datafile)
	}
	load(datafile)
	
	## plot spline fits
	full_outfix = outfix
	if (legendflag == TRUE) {
	  full_outfix = paste0(full_outfix,"_legend")
	}
	if (labelflag == TRUE) {
	  full_outfix = paste0(full_outfix,"_label")
	}
	subdir = paste0(outdir,"/",outstem,"_",full_outfix)
	
	dir.create(subdir, showWarnings = FALSE, recursive = TRUE)	
	for(jj in 1:length(files)){  
	  file = files.short[jj]
	  mypath = paste0(subdir,"/" , file ,"_", full_outfix,".pdf")
	  pdf(file = mypath, width = pwidth, height = pheight)
	  data = dat.list[[jj]]
	  range2 = range[[jj]]
	  age = age.list[[jj]]
	  
	  ## make plotting canvas
	  if (legendflag == TRUE) {
	  	xrange = range(age)+c(0,6)
	  } else {
	  	xrange = range(age)
	  }
	  if (labelflag == TRUE) {
	    par(oma = c(0,0,0,0), mar = c(4,4,3,1))
		plot(data[,1],data[,2], xlab = "age", ylab = file, main = file, xlim = xrange, ylim = range(range2), type = "n")
	  } else {
	    par(oma = c(0,0,0,0), mar = c(2,2,1,1))
		plot(data[,1],data[,2], xlab = "", ylab = "", main = "", xlim = xrange, ylim = range(range2), type = "n")
	  }
	  for(ii in 1:length(data)){
	    ## confidence interval: for shaded region
	    sp = sp.cis[[jj]][[ii]]
	    polygon(c(rev(sp$x), sp$x), c(rev(sp$upper.ci), sp$lower.ci), col = t_col(colshade[ii]), border = NA)
	    lines(x=sp$x , y=sp$main.curve, lwd = 2, col = t_col(cols[ii], percent = 20))
	  }
	  if (legendflag == TRUE) {
	  	legend.names = names(data)
	  	legend('bottomright', legend.names , lty = 1,lwd = 2, col = cols, box.lty=0, cex = .55)
	  }
	  dev.off()
	}
}

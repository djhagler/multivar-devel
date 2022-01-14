library(ggplot2)

######################################
## set parameters
######################################

rootdir <- "/Users/dhagler/Documents/papers/multivar_devel/fits"
instem_info <- "merged_broca_vs_premotor_plus_demog2.csv"
infix = "resid"
instem_data_list = c("MD1wg_6clust_resid")
pwidth = 5.0
pheight = 2.4
agelabel = "Age_At_IMGExam"
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

measlist_plot_order = c()
measlist_plot_order = c(measlist_plot_order,"area")
measlist_plot_order = c(measlist_plot_order,"thick")
measlist_plot_order = c(measlist_plot_order,"sulc")
measlist_plot_order = c(measlist_plot_order,"T1w_wm","T1w_gm")
measlist_plot_order = c(measlist_plot_order,"T2w_wm","T2w_gm")
measlist_plot_order = c(measlist_plot_order,"FA_wm","FA_gm")
measlist_plot_order = c(measlist_plot_order,"LD_wm","LD_gm")
measlist_plot_order = c(measlist_plot_order,"MD_wm","MD_gm")
measlist_plot_order = c(measlist_plot_order,"TD_wm","TD_gm")

roilist = toupper(c("roi1","roi2","roi3","roi4","roi5","roi6"))

# plot colors
cols =     c("blue4",         "deepskyblue", "turquoise",  "yellow", "orangered3",  "red4")
colshade = c("lightskyblue1", "lightblue",   "cadetblue1", "bisque", "sandybrown" , "rosybrown")

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
# load demographics data
######################################

d = read.csv(paste0(indir,"/",instem_info), header = T)
d = d[,c(1,20:29)]
d = d[complete.cases(d),]

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
		## calculate splines for each data file (measure)
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
		save(sp.cis,range,dat.list,age.list,file=datafile)
	}
	load(datafile)
	
	## plot change for each ROI (y-axis) as a function of measure (x-axis)
	fname_out = paste0(outdir,"/",outstem,"_change.png")
	# compile values into data frame
	df = c()
	cpal = c()
	for(rr in 1:length(roilist)){
		tdf = data.frame(measure=measlist,roi=rep(roilist[rr],length(measlist)))
		cpal[rr] = t_col(cols[rr], percent = 20)
		change = c()
		for(mm in 1:length(measlist)){
		    sp = sp.cis[[mm]][[rr]]
		    y0 = sp$main.curve[1]
			dy = 100*(sp$main.curve - y0)/y0
			abs_dy = abs(dy)
			max_abs_dy = max(abs_dy)
			idx_max = which(abs_dy==max_abs_dy)
			max_dy = dy[idx_max]
		    change[mm] = max_dy
		}
		tdf$change = change
		df = rbind(df,tdf)
	}
	
	p <- ggplot(df, aes(x = measure, y = change, color=roi)) +
			geom_line(aes(group=roi)) +
			geom_point(size=3) +
			scale_color_manual(values=cpal) +
			scale_x_discrete(limits=measlist_plot_order,
							 label=gsub('_',' ',measlist_plot_order)) +
			theme(axis.text.x = element_text(size=9, angle=90),
				  axis.title = element_text(size=9),
				  legend.title = element_blank()) +
			ylab("Percent Change") +
			xlab("Imaging-Derived Measure")
	
	ggsave(plot=last_plot(), file=fname_out, dpi = 300, width = 6, height = 5)
}

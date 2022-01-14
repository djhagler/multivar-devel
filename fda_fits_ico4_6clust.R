######################################
## set parameters
######################################

rootdir <- "/Users/dhagler/Documents/papers/multivar_devel/fits"
infix = "_plus_demog"
instem_data_list = c("MD1wg_6clust_resid_ico4")
pwidth = 3.5
pheight = 2.4
agelabel = "Age_At_IMGExam"
legendflag = FALSE
labelflag = FALSE
#legendflag = TRUE
#labelflag = TRUE
forceflag = FALSE
initflag = TRUE
#initflag = FALSE
avgflag = TRUE
#avgflag = FALSE
#sdflag = FALSE
sdflag = TRUE
#traceflag = TRUE
traceflag = FALSE
pfrac = 0.05
transperc = 70

indir <- paste0(rootdir,"/data")
outdir <- paste0(rootdir,"/output")

measlist = c()
#measlist = c(measlist,"FA_wm")
measlist = c(measlist,"FA_gm","FA_wm")
measlist = c(measlist,"LD_gm","LD_wm")
measlist = c(measlist,"MD_gm","MD_wm")
measlist = c(measlist,"TD_gm","TD_wm")
measlist = c(measlist,"T1w_gm","T1w_wm")
measlist = c(measlist,"T2w_gm","T2w_wm")
measlist = c(measlist,"area")
measlist = c(measlist,"thick")
measlist = c(measlist,"sulc")

roilist = c("roi1","roi2","roi3","roi4","roi5","roi6")

# plot colors
cols =     c("blue4",         "deepskyblue", "turquoise",  "yellow", "orangered3",  "red4")
colshade = c("lightskyblue1", "lightblue",   "cadetblue1", "bisque", "sandybrown" , "rosybrown")

if (initflag==TRUE) {
	outfix = "init" 
} else {
	outfix = "orig"
}
if (avgflag==TRUE) {
	outfix = paste0(outfix,"_avg")
}
if (sdflag==TRUE) {
	outfix = paste0(outfix,"_sd")
}
if (traceflag==TRUE) {
	outfix = paste0(outfix,"_trace")
}

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

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

for(kk in 1:length(instem_data_list)){
	## load data files	
	instem_data = instem_data_list[kk]
	full_indir = paste0(indir,"/",instem_data)
	outstem = instem_data
	
  	infofile <- paste0(outdir,"/",outstem,"_all_data.Rdata")
	if (!file.exists(infofile) || forceflag) {
		
		print("loading data from csv files...")
		
		# load data from csv files
		setwd(full_indir)
		all_files = list.files()
		suffix = paste0(infix,".csv")
		all_files = all_files[grepl(suffix,all_files)]
		files = c()
		for(mm in 1:length(measlist)){
			files = c(files,all_files[grepl(measlist[mm],all_files)])
		}
		all = lapply(files, read.csv)
		files.short = unlist(lapply(files, function(x){gsub(suffix,"",x)}))
		nfiles = length(files.short)
			
		# merge all to get intersectional list of subjects
		all_VisitIDs = all[[1]][,"VisitID", drop=FALSE]
		for(ii in 2:length(files)){
			tmp_VisitIDs = all[[ii]][,"VisitID", drop=FALSE]
			all_VisitIDs = merge(all_VisitIDs, tmp_VisitIDs, by = "VisitID")
		}
		save(all_VisitIDs,all,files,files.short,file= infofile)
	}
	load(infofile)
	
	# calculate splines for each data file
	for(jj in 1:length(files)){  
	  	file = files.short[jj]
	  	
	  	datafile <- paste0(outdir,"/",outstem,"_",file,"_fda_fits.Rdata")
		if (!file.exists(datafile) || forceflag) {
			
			print(sprintf("calculating splines for %s...",file))
			
			ptm <- proc.time()		

			dat = all[[jj]]
			# merge with list of intersectional subjects
			dat = merge(dat,all_VisitIDs, by = "VisitID")

			# get age		  
			age = dat[,grepl(agelabel,names(dat))]
			
			# create bspline
			rangeval = range(age)
			bbasis = create.bspline.basis(rangeval, nbasis = 5, norder = 4)
			  
	     	# concatenate left and right, rename columns
			lh = dat[,grepl("lh",names(dat))]
			rh = dat[,grepl("rh",names(dat))]
			both = cbind(lh,rh)
			split = strsplit(names(both), "[.]")
			names(both) = unlist(lapply(split, function(x){paste(x[c(2,4)],collapse = '.')}))
			data = both
			  
			splines = list()
			for(dd in 1:length(data)){
			  	tmpdata = data.frame(x = age, y = data[,dd])
			  	nvals = 300
			  	sp.vals = spline.estimator(tmpdata,m=nvals)
				splines[[dd]] = list(y=sp.vals,x=seq(from=min(tmpdata[,1]),to=max(tmpdata[,1]),length.out=nvals))
			}
			proc.time() - ptm
			save(splines,data,age,file=datafile)
		}
	}

  	# plot splines for each measure
	for(mm in 1:length(measlist)){
		meas = measlist[mm]
		# find files that match this meas	
		i_meas = grepl(meas,files.short)
		meas_files = files.short[i_meas]

		print(sprintf("plotting splines for %s...",meas))
		
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
	
	  	mypath = paste0(subdir,"/" , meas ,"_", full_outfix,".pdf")
	  	pdf(file = mypath, width = pwidth, height = pheight)
	  
		minval = Inf;
		maxval = -Inf;
		for(rr in 1:length(roilist)){
			roi = roilist[rr]
			i_roi = grepl(roi,meas_files)
			file = meas_files[i_roi]
			datafile <- paste0(outdir,"/",outstem,"_",file,"_fda_fits.Rdata")
			load(datafile)
			nverts = length(data)
			sp = splines[[1]]
			ntpoints = length(sp$x)
			# compile spline values into matrix
			sp.mat <- matrix(, nrow = nverts, ncol = ntpoints)
			for(dd in 1:nverts) {
				sp = splines[[dd]]
				sp.mat[dd,] = sp$y
				if (initflag == TRUE) {
					sp.mat[dd,] = sp.mat[dd,] - sp.mat[dd,1]
				}
			}
			sp.mean = apply(sp.mat,2,mean)
			sp.stdev = apply(sp.mat,2,sd)
			minval = min(minval,sp.mean-sp.stdev)
			maxval = max(maxval,sp.mean+sp.stdev)
		}
		yrange = c(minval,maxval)
	  	print(sprintf("for %s, minval = %0.5f, maxval = %0.5f",meas,minval,maxval))
	  	  	
	  	## make plotting canvas
	  	if (legendflag == TRUE) {
	  		xrange = range(age)+c(0,6)
	  	} else {
	  		xrange = range(age)
	  	}
	  		
	  	if (labelflag == TRUE) {
	    	par(oma = c(0,0,0,0), mar = c(4,4,3,1))
			plot(data[,1],data[,2], xlab = "age", ylab = file,
				 main = file, xlim = xrange, ylim = yrange, type = "n")
	  	} else {
	    	par(oma = c(0,0,0,0), mar = c(2,2,1,1))
			plot(data[,1],data[,2], xlab = "", ylab = "",
				main = "", xlim = xrange, ylim = yrange, type = "n")
	  	}
	  
	  	# loop over ROIs
		for(rr in 1:length(roilist)){
		  	col = t_col(cols[rr], percent = transperc)
			roi = roilist[rr]
			i_roi = grepl(roi,meas_files)
			file = meas_files[i_roi]
			datafile <- paste0(outdir,"/",outstem,"_",file,"_fda_fits.Rdata")
			load(datafile)
			
			nverts = length(data)

			if (avgflag == TRUE) {
				# compile spline values into matrix
				sp = splines[[1]]
				ntpoints = length(sp$x)
				sp.mat <- matrix(, nrow = nverts, ncol = ntpoints)
				for(dd in 1:nverts) {
					sp = splines[[dd]]
					sp.mat[dd,] = sp$y
					if (initflag == TRUE) {
						sp.mat[dd,] = sp.mat[dd,] - sp.mat[dd,1]
					}
				}
				sp.mean = apply(sp.mat,2,mean)
				sp.stdev = apply(sp.mat,2,sd)
			
				if (sdflag == TRUE) {
				    polygon(c(rev(sp$x), sp$x), c(rev(sp.mean + sp.stdev),
				    			sp.mean - sp.stdev), col = t_col(colshade[rr], percent = 80), border = NA)		
				}
				lines(x=sp$x, y=sp.mean, lw = 2, col = t_col(cols[rr], percent = 1))	
			}
			
			if (traceflag == TRUE) {
				v = round(seq(from=1,to=nverts,length.out=nverts*pfrac))			  
			  	for(dd in v){
					sp = splines[[dd]]
					if (initflag == TRUE) {
			   		 	lines(x=sp$x , y=sp$y-sp$y[1], lwd = 0.01, col = col)			
					} else {
			    		lines(x=sp$x , y=sp$y, lwd = 0.01, col = col)			
					}
				}
			}

		}
	
	  	if (legendflag == TRUE) {
	  		legend.names = names(data)
	  		legend('bottomright', legend.names , lty = 1,lwd = 1, col = cols, box.lty=0, cex = .55)
	  	}
	  	dev.off()
  	}  	
}

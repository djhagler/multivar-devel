######################################
# set parameters
######################################

rootdir <- "/Users/dhagler/Documents/papers/multivar_devel/fits"
instem_info <- "merged_broca_vs_premotor_plus_demog2.csv"
outfix = 'multivar_diff_stats'
outfix_data = 'merged_data'
instem_data_list = c("MD1wg_aparc","MD1wg_2clust","MD1wg_6clust","thick_3clust")
infix_list = c("aparc","MD1wg_sm_clusters2","MD1wg_sm_clusters6","thick_sm_clusters3")
forceflag = TRUE
forceflag_data = FALSE

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

######################################
# difference stats for each set of input files
######################################

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
source(paste0(rootdir,'/scripts/merge_data.R'))

for(jj in 1:length(instem_data_list)){
  instem_data = instem_data_list[jj]
  infix = infix_list[jj]  
  full_indir = paste0(indir,"/",instem_data)
  outstem = instem_data
  fname_out = paste0(outdir,"/",outstem,"_",outfix,".csv")
  fname_out_corr = paste0(outdir,"/",outstem,"_",outfix,"_corr",".csv")
  
  if (!file.exists(fname_out) || !file.exists(fname_out_corr) || forceflag) {
	setwd(full_indir)
	
	# load data, merging by intersection across all measures
	dat.all = merge_mvdev_data(rootdir,instem_info,outfix_data,instem_data,infix,measlist,forceflag_data)
	  
    # average lh & rh
	lh = dat.all[,grepl("lh",names(dat.all))]
	rh = dat.all[,grepl("rh",names(dat.all))]
	dat = (lh + rh)/2
	split = strsplit(names(dat), "[.]")
	names(dat) = unlist(lapply(split,
							function(x){paste(x[c(1,3)],collapse = '.')}))
	age = dat.all$Age_At_IMGExam
	# make list of ROI's
	ROIs = gsub(paste0(".",measlist[1],"*") , "" ,
						names(dat[ , grepl( measlist[1] , names(dat))])) 

	expand = combn(ROIs,2)
    Pillai.vals = c()
	f.vals = c()
	p.vals = c()
	p.vals.corr = c()
	ndf.vals = c()
	ddf.vals = c()
	roipair = c()
	  
	age = age - min(age) # subtract age by 3
	age2 = age^2
	for(ii in 1:length(expand[1,])){
    	dat1 = dat[,grepl(expand[1,ii], names(dat))]
        dat2 = dat[,grepl(expand[2,ii], names(dat))]
        dat.diff = dat1 - dat2
        names(dat.diff) = paste0(names(dat1) , "." , names(dat2))
        dat.diff = as.matrix(dat.diff)
		# baseline model
		fit_base <- manova(dat.diff ~ DeviceSerialNumber + Gender
									   + FDH_3_Household_Income + FDH_Highest_Education
									   + GAF_africa + GAF_amerind + GAF_eastAsia
									   + GAF_oceania + GAF_centralAsia, data = dat.all)
		# baseline model + age + age2
        fit_age <- manova(dat.diff ~ age + age2
									   + DeviceSerialNumber + Gender
									   + FDH_3_Household_Income + FDH_Highest_Education
									   + GAF_africa + GAF_amerind + GAF_eastAsia
									   + GAF_oceania + GAF_centralAsia, data = dat.all)
									   
		# likelihood ratio
		lrt_age = anova(fit_base, fit_age)
		# save results for roi combination
	    roipair[ii] = paste(expand[1,ii],"vs", expand[2,ii])
	    Pillai.vals[ii] = lrt_age[2,4]
		f.vals[ii] = lrt_age[2,5]
		p.vals[ii] = lrt_age[2,8]
		# numerator degrees of freedom
		ndf.vals[ii] = lrt_age[2,6]
		# denominator  degrees of freedom
		ddf.vals[ii] = lrt_age[2,7]
				 
		if (ii==1) {		
		    base_df = fit_base$df
		    age_df = fit_age$df
		    trend_df1 = lrt_age[2,6]
		    trend_df2 = lrt_age[2,7]
		    
			print(paste0("N = ",length(age)))  
			print(paste0("base df  = ",base_df))		    
			print(paste0("age df  = ",age_df))		    
			print(paste0("trend df = [",trend_df1,",",trend_df2,"]"))		    
		}
	  }

	  # format table
	  matrix = cbind(Pillai.vals,f.vals,p.vals,ndf.vals,ddf.vals)
	  rownames(matrix) = roipair
	  colnames(matrix) = c("Pillai","F","p","Ddof","Ndof")	  
			
      # save as csv file
      setwd(outdir)
	  write.csv(matrix, file = fname_out)
	  	  
	  # apply Bonferroni correction (multiply by number of p values)
	  p.vals.corr = p.adjust(p.vals, method = "bonferroni", n=length(p.vals))
	  	  
	  matrix = cbind(Pillai.vals,f.vals,p.vals.corr,ndf.vals,ddf.vals)
	  rownames(matrix) = roipair
	  colnames(matrix) = c("Pillai","F","pcorr","Ddof","Ndof")
			
      # save as csv file
      setwd(outdir)
	  write.csv(matrix, file = fname_out_corr)	  
  }
}

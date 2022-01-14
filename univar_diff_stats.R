######################################
# set parameters
######################################

rootdir <- "/Users/dhagler/Documents/papers/multivar_devel/fits"
instem_info <- "merged_broca_vs_premotor_plus_demog2.csv"
outfix_data = 'merged_data'
outfix = 'univar_diff_stats'
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
  fname_out2 = paste0(outdir,"/",outstem,"_",outfix,"2",".csv")
  fname_out_corr = paste0(outdir,"/",outstem,"_",outfix,"_corr",".csv")

  if (!file.exists(fname_out) || !file.exists(fname_out2)  || !file.exists(fname_out_corr) || forceflag) {
		
		# load data, merging by intersection across all measures
		dat.all = merge_mvdev_data(rootdir,instem_info,outfix_data,instem_data,infix,measlist,forceflag_data)
		all_VisitIDs = dat.all[,"VisitID", drop=FALSE]
		
		# file names					
		setwd(full_indir)
		all_files = list.files()
		all_files = all_files[grepl(".csv",all_files)]
		files = c()
		for(ii in 1:length(measlist)){
      		files = c(files,all_files[grepl(sprintf("%s_%s",measlist[ii],infix),all_files)])
		}
		
		# load all files
		all = lapply(files, read.csv)
		files.short = unlist(lapply(files, function(x){gsub(".csv","",x)}))
 		nfiles = length(files.short)
 		
		# difference stats for each input files
		matrix1 = matrix(ncol = 4)
		for(ii in 1:nfiles){
			  file = files.short[ii]
			  dat = all[[ii]]
			  # merge dat (or, roi_summaries files) with file that includes covariates
			  d2 = merge(dat,d, by = "VisitID")
			  # merge with list of intersectional subjects
			  d2 = merge(d2,all_VisitIDs, by = "VisitID")
			  # get age
			  age = d2$Age_At_IMGExam
			  #average lh & rh
			  lh = d2[,grepl("lh",names(d2))]
			  rh = d2[,grepl("rh",names(d2))]
			  avg = (lh + rh)/2
			  split = strsplit(names(avg), "[.]")
			  # roi names
			  names(avg) = unlist(lapply(split, function(x){paste(x[c(1)],collapse = '.')}))
			  # make list of pairwise combinations of rois
			  ROIs = names(avg)
			  expand = combn(ROIs,2)
			  basel.d = c()
			  basel.p = c()
			  basel.df = c()
			  slope.d = c()
			  slope.p = c()
			  quad.d = c()
			  quad.p = c()
			  trend.F = c()
			  trend.p = c()
			  trend.df = c()
			  roipair = c()
			  comparison = c()
			  
			  age = age - min(age) # subtract age by 3
			  age2 = age^2
			  for(kk in 1:length(expand[1,])){
			    c1 = avg[,expand[1,kk]]
			    c2 = avg[,expand[2,kk]]
			    c.diff = c1 - c2
			    # baseline model
			    fit_base <- lm(c.diff ~ DeviceSerialNumber + Gender 
			    					  + FDH_3_Household_Income + FDH_Highest_Education
			    				        + GAF_africa + GAF_amerind + GAF_eastAsia
			    				        + GAF_oceania + GAF_centralAsia, data = d2)
			    				        			    			        
			    # baseline model + age + age2
			    fit_age <- lm(c.diff ~ age + age2
			    					   + DeviceSerialNumber + Gender 
			    					  + FDH_3_Household_Income + FDH_Highest_Education
			    				        + GAF_africa + GAF_amerind + GAF_eastAsia
			    				        + GAF_oceania + GAF_centralAsia, data = d2)
				# intercept
			    coef = summary(fit_age)$coefficients[c("(Intercept)","age","age2"),]
			    df = summary(fit_age)$df[2]
			    basel.d[kk] = as.numeric(coef[1,1] / (coef[1,2] * sqrt(df) ))
			    basel.p[kk] = coef[1,4]

				# age
			    slope.d[kk] = as.numeric(coef[2,1] / (coef[2,2] * sqrt(df) ))
			    slope.p[kk] = coef[2,4]

				# age2
			    quad.d[kk] = as.numeric(coef[3,1] / (coef[3,2] * sqrt(df) ))
			    quad.p[kk] = coef[3,4]

			    # likelihood ratio
			    lrt_age = anova(fit_base, fit_age)
			    trend.F[kk] = lrt_age[2,5]
			    trend.p[kk] = lrt_age[2,6]
			    
			    # identifiers
			    roipair[kk] = paste(expand[1,kk],"vs", expand[2,kk])
			    comparison[kk] = paste(file, expand[1,kk], expand[2,kk])

				# report dof
				if (kk==1) {
				    base_df1 = summary(fit_base)$df[1]
				    base_df2 = summary(fit_base)$df[2]
				    age_df1 = summary(fit_age)$df[1]
				    age_df2 = summary(fit_age)$df[2]
				    trend_df1 = lrt_age[1,1]
				    trend_df2 = lrt_age[2,1]
				    
					print(paste0("comparison = ",comparison[kk]))
					print(paste0("N = ",length(age)))  
					print(paste0("base df  = [",base_df1,",",base_df2,"]"))		    
					print(paste0("age df  = [",age_df1,",",age_df2,"]"))		    
					print(paste0("trend df = [",trend_df1,",",trend_df2,"]"))		    
				}
			  }
			  matrix2 = cbind(basel.d, basel.p, trend.F, trend.p)
			  rownames(matrix2) = comparison
			  matrix1 = rbind(matrix1,matrix2)
		}
		matrix1 = matrix1[-1,]
		matrix1 = as.data.frame(matrix1)
		matrix1$comparison = rownames(matrix1)
		rownames(matrix1) = NULL
		matrix1 = matrix1[,c(5,1:4)]
		
		p = .05
		# number of tests (2 tests: slope and intercept)
		numtests = 2*length(matrix1[,1])
		# bonferroni correction
		p.corrected = p/numtests
		
		# format table
		snames = c("base d","base p","base sig","trend F","trend p","trend sig")
		cnames = c("Measure")
		matrix3 = data.frame("Measure" = NA, check.names = F)
		matrix3_corr = data.frame("Measure" = NA, check.names = F)
		for(ii in 1:length(snames)){
		  sname = snames[ii]				
		  for(kk in 1:length(roipair)){
		    roipairname = roipair[kk]
		    cnames = c(cnames,paste0(roipairname," ",sname))
		    matrix3 = cbind(matrix3,data.frame("stat" = NA, check.names = F))
		    matrix3_corr = cbind(matrix3_corr,data.frame("stat" = NA, check.names = F))
		  }
		}
		colnames(matrix3) = cnames
		colnames(matrix3_corr) = cnames
		for(ii in 1:nfiles){
		  matrix4 = matrix1[grepl(files.short[ii], matrix1$comparison),]
		  basel.d = formatC(matrix4$basel.d, format = 'f',digits = 3)
		  basel.p = formatC(matrix4$basel.p, format = 'g',digits = 2)
		  basel.p.corr = p.adjust(basel.p, method = "bonferroni", n=numtests)
		  basel.sig = formatC(matrix4$basel.p < p.corrected, format = 'd')
		  trend.F = formatC(matrix4$trend.F, format = 'f',digits = 3)
		  trend.p = formatC(matrix4$trend.p, format = 'g',digits = 2)
		  trend.p.corr = p.adjust(trend.p, method = "bonferroni", n=numtests)
		  trend.sig = formatC(matrix4$trend.p < p.corrected, format = 'd')
		  matrix3[ii,] = c(files.short[ii],basel.d,basel.p,basel.sig,trend.F,trend.p,trend.sig)
		  matrix3_corr[ii,] = c(files.short[ii],basel.d,basel.p.corr,basel.sig,trend.F,trend.p.corr,trend.sig)
		}
		# save as csv file
        setwd(outdir)
		write.csv(matrix3, file = fname_out)
		write.csv(matrix3_corr, file = fname_out_corr)		

		# reformat table
		snames = c("baseline","trend")
		cnames = c("Measure")
		matrix4 = data.frame("Measure" = NA, check.names = F)
		for(ii in 1:length(snames)){
		  sname = snames[ii]				
		  for(kk in 1:length(roipair)){
		    roipairname = roipair[kk]
		    cnames = c(cnames,paste0(roipairname," ",sname))
		    matrix4 = cbind(matrix4,data.frame("stat" = NA, check.names = F))
		  }
		}
		colnames(matrix4) = cnames
		for(ii in 1:nfiles){
		  matrix5 = matrix1[grepl(files.short[ii], matrix1$comparison),]
		  basel = formatC(round(matrix5$basel.d,3), format = 'f',digits = 1)
		  trend = formatC(round(matrix5$trend.F,3), format = 'f',digits = 1)
		  basel.signif = matrix5$basel.p < p.corrected
		  trend.signif = matrix5$trend.p < p.corrected
	  	  basel[basel.signif] = paste0(basel[basel.signif],"*")
	      trend[trend.signif] = paste0(trend[trend.signif],"*")
		  matrix4[ii,] = c(files.short[ii], basel,trend)
		}
		# save as csv file
        setwd(outdir)
		write.csv(matrix4, file = fname_out2)

	}
}

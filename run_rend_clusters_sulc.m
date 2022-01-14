rootdir  = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
diffstem = 'univar_MD1wg_sm_surf_surf_diff';
measname = 'sulc_sm';
clustnums = [2,6];
clust_infix = [];
membexp = 1.25;
numruns = 100;
indiv_flag = 0;
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

infodir = sprintf('%s/diff_surf/output/diff_batch',rootdir);
clustdir = sprintf('%s/clusters/output/clust_%s%s',...
  rootdir,measname,clust_infix);
outdir = sprintf('%s/clusters/output/clusters_resurf',rootdir);

for i=1:length(clustnums)
  clustnum = clustnums(i);
  instem = sprintf('clust%d_membexp%0.2f_runs%d_clusters',...
    clustnum,membexp,numruns);
  outstem = sprintf('%s_clusters%d',measname,clustnum);
  fname_clusters = sprintf('%s/%s.txt',clustdir,instem);
  fname_info = sprintf('%s/%s_info.mat',infodir,diffstem);
  resurface_clusters(fname_clusters,fname_info,outdir,outstem,forceflag);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indir = outdir;
outdir = sprintf('%s/clusters/output/plots',rootdir);

for i=1:length(clustnums)
  clustnum = clustnums(i);
  instem = sprintf('%s_clusters%d',measname,clustnum);
  rend_clusters(instem,indir,outdir,forceflag,indiv_flag);
end;


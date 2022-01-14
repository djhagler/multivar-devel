rootdir  = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
diffstem = 'multivar_MD1wg_sm_surf_surf_diff';
measname = 'MD1wg_sm_M';
clustnums = [2,6];
clust_infix = [];
membexp = 1.2;
numruns = 100;
indiv_flag = 1;
forceflag = 0;


clust_orders = {...
  []...
  [1,2,5,3,4,6]...
};
%  []...
hemilist = {'lh','rh'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

infodir = sprintf('%s/diff_surf/output/diff_batch',rootdir);
clustdir = sprintf('%s/clusters/output/clust_%s%s',...
  rootdir,measname,clust_infix);
outdir = sprintf('%s/clusters/output/clusters_resurf',rootdir);

for i=1:length(clustnums)
  clustnum = clustnums(i);
  % convert clusters from txt to mgz
  instem = sprintf('clust%d_membexp%0.2f_runs%d_clusters',...
    clustnum,membexp,numruns);
  outstem = sprintf('%s_clusters%d',measname,clustnum);
  fname_clusters = sprintf('%s/%s.txt',clustdir,instem);
  fname_info = sprintf('%s/%s_info.mat',infodir,diffstem);
  resurface_clusters(fname_clusters,fname_info,outdir,outstem,forceflag);
  % reorder clusters
  ind_order = clust_orders{i};
  if ~isempty(ind_order)
    nhemi = length(hemilist);
    new_outstem = [outstem '_reorder'];
    for h=1:nhemi
      hemi = hemilist{h};
      fname_in = sprintf('%s/%s-%s.mgz',outdir,outstem,hemi);
      if ~exist(fname_in,'file')
        error('file %s not found',fname_in);
      end;
      fname_out = sprintf('%s/%s-%s.mgz',outdir,new_outstem,hemi);
      if ~exist(fname_out,'file') || forceflag
        vol = fs_load_mgh(fname_in);
        vol = vol(:,:,:,ind_order);
        fs_save_mgh(vol,fname_out);
      end;
    end;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indir = outdir;
outdir = sprintf('%s/clusters/output/plots',rootdir);

for i=1:length(clustnums)
  clustnum = clustnums(i);
  instem = sprintf('%s_clusters%d',measname,clustnum);
  if ~isempty(clust_orders{i}), instem = [outstem '_reorder']; end;  
  rend_clusters(instem,indir,outdir,forceflag,indiv_flag);
end;


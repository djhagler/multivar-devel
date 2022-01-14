indir = [pwd '/output'];
outdir = [pwd '/output'];
outstem = 'compare_clusters_meas';
nclust = 2;
membexp = 1.2;
nruns = 100;

measlist = {...
  'MD1wg',...
  'Dwg','Dg','Dw',...
  'M1','M',...
  'FA_gm','FA_wm',...
  'LD_gm','LD_wm',...
  'TD_gm','TD_wm',...
  'T2w_gm','T2w_wm',...
  'area','sulc','thick',...
  'T1w_gm','T1w_wm'};
            
membexplist = [1.2,1.25];            
forceflag = 0;

if ~exist('fig_size','var') || isempty(fig_size), fig_size = [4 4]; end;
if ~exist('tif_dpi','var') || isempty(tif_dpi), tif_dpi = 300; end;
if ~exist('eps_flag','var') || isempty(eps_flag), eps_flag = 0; end;
if ~exist('visible_flag','var') || isempty(visible_flag), visible_flag = 0; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nmeas = length(measlist);
mmil_mkdir(outdir);

fname_out = sprintf('%s/%s_n%d.mat',outdir,outstem,nclust);
if ~exist(fname_out,'file') || forceflag
  ARmat = ones(nmeas,nmeas); RImat = ones(nmeas,nmeas);
  for i=1:nmeas
    meas1 = measlist{i};
    sdir1 = sprintf('clust_%s_sm',meas1);
    for k=1:length(membexplist)
      membexp = membexplist(k);
      instem = sprintf('clust%d_membexp%0.2f_runs%d_clusters.txt',nclust,membexp,nruns);
      fname1 = sprintf('%s/%s/%s',indir,sdir1,instem);
      if exist(fname1,'file'), break; end;
    end;
    if ~exist(fname1,'file'), error('file %s not found',fname1); end;
    for j=1:nmeas
      if i==j, continue; end;
      meas2 = measlist{j};
      sdir2 = sprintf('clust_%s_sm',meas2);
      for k=1:length(membexplist)
        membexp = membexplist(k);
        instem = sprintf('clust%d_membexp%0.2f_runs%d_clusters.txt',nclust,membexp,nruns);
        fname2 = sprintf('%s/%s/%s',indir,sdir2,instem);
        if exist(fname2,'file'), break; end;
      end;
      if ~exist(fname2,'file'), error('file %s not found',fname2); end;
      fprintf('%s: comparing clusters for meas %s vs %s...\n',...
        mfilename,meas1,meas2);
      clusters1 = mmil_readtext(fname1,' ');
      clusters2 = mmil_readtext(fname2,' ');
      clustvals1 = cell2mat(clusters1(2:end,2:end));
      clustvals2 = cell2mat(clusters2(2:end,2:end));
      [tmp,indmax1] = max(clustvals1,[],2);
      [tmp,indmax2] = max(clustvals2,[],2);
      [AR,RI] = randindex(indmax1,indmax2);
      ARmat(i,j) = AR;
      RImat(i,j) = RI;
      fprintf('AR = %0.3f  RI = %0.3f\n',AR,RI);
    end;
  end;
  save(fname_out,'measlist','ARmat','RImat');
else
  load(fname_out);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1); clf;
imagesc(ARmat,[0,1]);
colorbar
title('adjusted Rand index');

fname_tif = sprintf('%s/%s_%dclust_ARI.tif',outdir,outstem,nclust);
mmil_save_fig(gcf,fname_tif,fig_size,tif_dpi,eps_flag,visible_flag);

figure(2); clf;
imagesc(RImat,[0,1]);
colorbar
title('Rand index');

fname_tif = sprintf('%s/%s_%dclust_RI.tif',outdir,outstem,nclust);
mmil_save_fig(gcf,fname_tif,fig_size,tif_dpi,eps_flag,visible_flag);

return;


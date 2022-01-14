function plot_silhouette(measname,varargin)
%function plot_silhouette(measname,[options])
%
% Required parameters:
%   measname: measure name
%
% Optional parameters:
%   'rootdir': root directory
%     {default = pwd}
%   'fig_size': figure size (inches)
%     {default = [4 4]}
%   'tif_dpi': dots per inch for output tif file
%     {default = 300}
%   'eps_flag': [0|1] also create eps file
%     {default = 0}
%   'visible_flag: [0|1] make plot visible
%     {default = 1}
%   'numclust': vector of numbers of clusters
%     {default = [2:10]}
%   'membexp': membership exponent parameter for fuzzy clustering
%     {default = 1.25}
%   'numruns': number of runs performed for fuzzy clustering
%     {default = 1}
%   'nvalid_thresh': minimum number of cluster numbers with solutions
%     {default = 0}
%   'slim': y-axis limits
%     {default = [0 1]}
%   'legend_flag': [0|1] include plot legend
%     {default = 1}
%   'forceflag': overwrite exising output
%     {default = 0}
%
% Created:  06/20/17 by Don Hagler
% Last Mod: 06/20/17 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,1), return; end;
parms = mmil_args2parms(varargin,{...
  'measname',measname,[],...
  ...
  'rootdir',pwd,[],...
  'fig_size',[4 4],[],...
  'tif_dpi',300,[],...
  'eps_flag',false,[false true],...
  'visible_flag',true,[false true],...
  'numclust',[2:10],[],...
  'membexp',1.25,[],...
  'numruns',100,[],...
  'nvalid_thresh',0,[0 Inf],...
  'slim',[0,1],[],...
  'legend_flag',true,[false true],...
  'forceflag',false,[false true],...
});

parms.indir = sprintf('%s/output/clust_%s%s',...
  parms.rootdir,parms.measname);
parms.outdir = sprintf('%s/output/silhouette_plots',parms.rootdir);
parms.outstem  = sprintf('clust_%s_silhouette',parms.measname);
parms.clim = [parms.numclust(1)-1,parms.numclust(end)+1];
parms.membexplist = cellfun(@(x) sprintf('membexp = %0.3f',x),num2cell(parms.membexp),'UniformOutput',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_tif = sprintf('%s/%s.tif',parms.outdir,parms.outstem);
if ~exist(fname_tif,'file') || parms.forceflag

  nclusts = length(parms.numclust);
  nexp = length(parms.membexp);
  svals = nan(nclusts,nexp);
  for j=1:nexp
    m = parms.membexp(j);
    for i=1:nclusts
      c = parms.numclust(i);
      fname = sprintf('%s/clust%d_membexp%0.2f_runs%d_silhouette.txt',...
        parms.indir,c,m,parms.numruns);
      if ~exist(fname,'file')
        fprintf('WARNING: %s not found\n',fname);
        continue;
      end;
      mstr = [];
      mstr = textread(fname,'%f');
      svals(i,j) = mstr;
    end;
  end;
  
  nvalid = sum(~isnan(svals),1);
  ind_valid = find(nvalid >= parms.nvalid_thresh);
  if isempty(ind_valid)
    fprintf('%s: WARNING: no values with number of valid clusters greater than %d\n',...
      mfilename,parms.nvalid_thresh);
  else
    svals = svals(:,ind_valid);
    parms.membexplist = parms.membexplist(ind_valid);
  end;
  
  if parms.visible_flag
    figure(1); clf;
  else
    figure;
  end;
  plot(parms.numclust,svals,'.-');
  xlim(parms.clim);
  ylim(parms.slim);
  xlabel('number of clusters');
  ylabel('silhouette value');
  if parms.legend_flag
    legend(parms.membexplist,'location','EastOutside');
  end;
  
  mmil_mkdir(parms.outdir);
  mmil_save_fig(gcf,fname_tif,parms.fig_size,...
    parms.tif_dpi,parms.eps_flag,parms.visible_flag)
end;


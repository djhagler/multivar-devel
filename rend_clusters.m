function rend_clusters(instem,indir,outdir,forceflag,indiv_flag)
%function rend_clusters(instem,indir,outdir,forceflag,indiv_flag)

if ~exist('instem','var') || isempty(instem)
  instem = 'clusters';
end;
outstem = instem;
if ~exist('indir','var') || isempty(indir)
  indir = [pwd '/clusters_resurf'];
end;
if ~exist('outdir','var') || isempty(outdir)
  outdir = [pwd '/plots'];
end;
if ~exist('forceflag','var') || isempty(forceflag)
  forceflag = 0;
end;
if ~exist('indiv_flag','var') || isempty(indiv_flag)
  indiv_flag = 0;
end;

subj = 'fsaverage';
subjdir = [getenv('FREESURFER_HOME') '/subjects'];
hemilist = {'lh','rh'};
%viewlist = {'lat','med','ven','sup','pos'};
viewlist = {'lat','med'};
surflist = {'inflated'};
nsmooth = 10; % smoothing steps after resampling back to ico7

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parms = [];
parms.fmin = 0.01;
parms.fmid = 0.25;
parms.fmax = 0.5;
parms.colorscale = 'category';
parms.cmap = 'jet';
parms.curvflag = 1;
parms.subjdir = subjdir;
parms.surfdir = [pwd '/surfs'];
parms.tif_flag = 1;
parms.tif_dpi = 100;
parms.outdir = outdir;
parms.visible_flag = 0;
parms.forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(outdir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% resample to ico 7
ico_in = 4;
ico_out = 7;
subj_in = sprintf('fsaverage%d',ico_in);

tp = [];
tp.outdir = outdir;
tp.trgsubj = 'fsaverage';
tp.subjdir = [getenv('FREESURFER_HOME') '/subjects'];
tp.smooth_out = nsmooth;
tp.verbose = 0;
tp.forceflag = forceflag;

for h=1:length(hemilist)
  hemi = hemilist{h};
  tp.fname_out = sprintf('%s/%s_ico%d_sm%d-%s.mgz',...
      indir,instem,ico_out,nsmooth,hemi);
  if ~exist(tp.fname_out,'file') || forceflag
    fprintf('%s: resampling clusters for %s...\n',mfilename,hemi);
    fname_in = sprintf('%s/%s-%s.mgz',...
        indir,instem,hemi);
    args = mmil_parms2args(tp);
    fprintf('%s: resampling %s to ico %d...\n',mfilename,fname_in,ico_out);
    fname_out = fs_surf2surf(fname_in,subj_in,args{:});
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
for h=1:length(hemilist)
  hemi = hemilist{h};
  fname_in = sprintf('%s/%s_ico%d_sm%d-%s.mgz',...
    indir,instem,ico_out,nsmooth,hemi);
  for s=1:length(surflist)
    parms.surfname = surflist{s};
    for m=1:length(viewlist)
      parms.view = viewlist{m};
      parms.outstem = sprintf('%s-%s-%s-%s',...
        outstem,hemi,parms.surfname,parms.view);
      fname_out = sprintf('%s/%s.tif',outdir,parms.outstem);
      if ~exist(fname_out,'file') || parms.forceflag
        args = mmil_parms2args(parms);
        sv_surf_view(subj,fname_in,args{:});
      end;
    end;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if indiv_flag
  parms.colorscale = 'linear';
  parms.cmap = 'mmil_cmap_blueblackred';
  for h=1:length(hemilist)
    hemi = hemilist{h};
    fname_in = sprintf('%s/%s_ico%d_sm%d-%s.mgz',...
      indir,instem,ico_out,nsmooth,hemi);
    for s=1:length(surflist)
      parms.surfname = surflist{s};
      for m=1:length(viewlist)
        parms.view = viewlist{m};
        parms.outstem = sprintf('%s-%s-%s-%s',...
          outstem,hemi,parms.surfname,parms.view);
        %% todo: check if output files exist
        %%       one for each cluster
  %      fname_out = sprintf('%s/%s.tif',outdir,parms.outstem);
  %      if ~exist(fname_out,'file') || parms.forceflag
          args = mmil_parms2args(parms);
          sv_surf_view(subj,fname_in,args{:});
  %      end;
      end;
    end;
  end;
end;


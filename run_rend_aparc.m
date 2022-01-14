outdir = [pwd '/output/plots'];
subj = 'fsaverage';
subjdir = [getenv('FREESURFER_HOME') '/subjects'];
hemilist = {'lh','rh'};
%viewlist = {'lat','med','ven','sup','pos'};
viewlist = {'lat','med'};
surflist = {'inflated'};
indiv_flag = 0;
roi_instem = 'aparc';
roi_inext = '.annot';
roi_outext = '.mgh';
roinames_sel = {'pericalcarine','caudalmiddlefrontal',...
                'rostralmiddlefrontal','transversetemporal'};
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outstem = roi_instem;
roidir = sprintf('%s/%s/label',subjdir,subj);
nhemi = length(hemilist);

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

parms.cmap = [...
 1 0 0;...
 0 1 0;...
 0 0 1;...
 1 1 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(outdir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert aparc to mgz file
fnames_roi = cell(nhemi,1);
nroi = []; i_roi = [];
for h=1:nhemi
  hemi = hemilist{h};
  fname_roi = sprintf('%s/%s.%s%s',roidir,hemi,roi_instem,roi_inext);
  fname_roi_out = sprintf('%s/%s-%s%s',outdir,roi_instem,hemi,roi_outext);
  [roinums,roinames,ctab] = fs_read_annotation(fname_roi);
  nverts = length(roinums);
  nroi_all = length(roinames);
  if ~isempty(roinames_sel)
    [tmp,i_roi,i_sel] = intersect(roinames,roinames_sel);
    [i_sel,i_sort] = sort(i_sel);
    i_roi = i_roi(i_sort);
    roinames = roinames(i_roi);
  else
    i_roi = 1:nroi_all;
  end;
  if isempty(nroi)
    nroi = length(i_roi);
    roinames_mat = cell(nroi,nhemi);
  else
    if length(roinames)~=nroi
      error('number of ROIs does not match between hemispheres');
      %% NOTE: if this is the case, need to run each hemisphere separately
    end;
  end;
  if ~exist(fname_roi_out,'file') || parms.forceflag
    vals = zeros(nverts,nroi);
    for r=1:nroi
      k = find(roinums==i_roi(r));
      vals(k,r) = 1;
    end;
    vals = reshape(vals,[nverts,1,1,nroi]);
    fs_save_mgh(vals,fname_roi_out);
  end;
  fnames_roi{h} = fname_roi_out;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for h=1:length(hemilist)
  hemi = hemilist{h};
  fname_in = fnames_roi{h};
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
    fname_in = fnames_roi{h};
    for s=1:length(surflist)
      parms.surfname = surflist{s};
      for m=1:length(viewlist)
        parms.view = viewlist{m};
        parms.outstem = sprintf('%s-%s-%s-%s',...
          outstem,hemi,parms.surfname,parms.view);
        %% todo: check if output files exist
        %%       one for each cluster (-1, -2, etc.)
  %      fname_out = sprintf('%s/%s.tif',outdir,parms.outstem);
  %      if ~exist(fname_out,'file') || parms.forceflag
          args = mmil_parms2args(parms);
          sv_surf_view(subj,fname_in,args{:});
  %      end;
      end;
    end;
  end;
end;

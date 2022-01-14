function resurface_clusters(fname_clusters,fname_info,outdir,outstem,forceflag)
%function resurface_clusters(fname_clusters,fname_info,[outdir],[outstem],[forceflag])
%
% Created:  10/06/16 by Don Hagler
% Last Mod: 10/06/16 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,2), return; end;

if ~exist('outdir','var') || isempty(outdir)
  outdir = pwd;
end;
if ~exist('outstem','var') || isempty(outstem)
  outstem = 'clusters';
end;
if ~exist('forceflag','var') || isempty(forceflag)
  forceflag = 0;
end;

hemilist = {'lh','rh'};

%% todo: replace with environment variables or input varargin
subjdir = '/space/syn02/1/data/MMILDB/BACKUP/md7/1/pubsw/packages/freesurfer/RH4-x86_64-R530/subjects';
subjname = 'fsaverage4';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clusters = mmil_readtext(fname_clusters,' ');
info = load(fname_info);

mmil_mkdir(outdir);

cluster_vals = cell2mat(clusters(2:end,2:end));

nclustverts = info.nverts;
nclusts = size(cluster_vals,2);

q = 0;
for h=1:length(hemilist)
  hemi = hemilist{h};
  nverts_hemi = info.nverts_hemi(h);
  verts_hemi = info.verts_hemi{h};
  % select indices for this hemisphere
  p = q + 1;
  q = p + nverts_hemi - 1;
  fname_out = sprintf('%s/%s-%s.mgz',outdir,outstem,hemi);
  if ~exist(fname_out,'file') || forceflag
    % read total nverts
    fname_surf = sprintf('%s/%s/surf/%s.white',subjdir,subjname,hemi);
    fprintf('%s: reading number of vertices from %s...\n',mfilename,fname_surf);
    nverts = fs_read_surf_nverts(fname_surf);
    vals = zeros(nverts,1,1,nclusts);
    vals(verts_hemi,1,1,:) = reshape(cluster_vals(p:q,:),[length(p:q),1,1,nclusts]);
    fs_save_mgh(vals,fname_out);
  end;
end;


function create_distmat_univar_diff_batch(instem,outstem,nbatches)
%function create_distmat_univar_diff_batch([instem],[outstem],[nbatches])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('instem','var') || isempty(instem)
  instem = 'univar_surf_surf_diff';
end;
if ~exist('outstem','var') || isempty(outstem)
  outstem = 'distmat_diff';
end;
if ~exist('nbatches','var') || isempty(nbatches)
  nbatches = 200;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_surf/output/diff_batch';
outdir = [pwd '/output/distmats'];
nverts = 4661;
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% load one file to get measlist
batch_size = ceil(nverts/nbatches);
p = 1;
q = p + batch_size - 1;
jstem = sprintf('v%04d_to_v%04d',p,q);
fname_in = sprintf('%s/%s_%s.mat',indir,instem,jstem);
if ~exist(fname_in,'file')
  error('file %s not found',fname_in);
end;
fprintf('%s: loading %s...\n',mfilename,fname_in);
data = load(fname_in);

measlist = data.measlist;
nmeas = data.nmeas;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for m=1:nmeas
  meas = measlist{m};
  fname_F = sprintf('%s/%s_%s_F.txt',outdir,outstem,meas);
  if ~exist(fname_F) || forceflag
    fprintf('%s: creating distmat for %s...\n',mfilename,meas);
    F = zeros(nverts,nverts);
    q = 0;
    % collect output from batch processing
    for j=1:nbatches
      p = q + 1;
      if p>nverts, break; end;
      q = min(nverts,p + batch_size - 1);
      jstem = sprintf('v%04d_to_v%04d',p,q);
      fname_in = sprintf('%s/%s_%s.mat',indir,instem,jstem);
      if ~exist(fname_in,'file')
        error('file %s not found',fname_in);
      end;
      fprintf('%s: loading %s...\n',mfilename,fname_in);
      data = load(fname_in);
      F(p:q,:) = data.F(:,:,m);
    end;
    F(isnan(F)) = 0;
    % save output
    mmil_mkdir(outdir);  
    fprintf('%s: saving distmat to %s...\n',mfilename,fname_F);
    save(fname_F,'F','-ascii');
  end;
end;

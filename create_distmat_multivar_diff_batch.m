function create_distmat_multivar_diff_batch(instem,outstem,nbatches,sqrt_flag)
%function create_distmat_multivar_diff_batch([instem],[outstem],[nbatches],[sqrt_flag])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('instem','var') || isempty(instem)
  instem = 'multivar_surf_surf_diff';
end;
if ~exist('outstem','var') || isempty(outstem)
  outstem = 'distmat_diff';
end;
if ~exist('nbatches','var') || isempty(nbatches)
  nbatches = 200;
end;
if ~exist('sqrt_flag','var') || isempty(sqrt_flag)
  sqrt_flag = 0;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indir = '/space/md8/1/data/dhagler/work/projects/multivar_devel/diff_surf/output/diff_batch';
outdir = [pwd '/output/distmats'];
nverts = 4661;
forceflag = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_F = sprintf('%s/%s_F.txt',outdir,outstem);

if ~exist(fname_F) || forceflag
  batch_size = ceil(nverts/nbatches);
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
    F(p:q,:) = data.F;
  end;
  F(isnan(F)) = 0;
  if sqrt_flag, F = sqrt(F); end;
  % save output
  mmil_mkdir(outdir);  
  save(fname_F,'F','-ascii');
end;


function stats = r_multivar_diff_array(p,q,fname_reg,fname_dat,varargin)
%function stats = r_multivar_diff_array(p,q,fname_reg,fname_dat,[options])
%
% Required Input:
%   p: starting index
%   q: ending index
%   fname_reg: name of csv containing regressors
%   fname_dat: name of binary data file
%
% Optional Input:
%   'outdir': output directory
%     {default = [pwd '/multivar_diff']}
%   'outstem': output file stem
%     {default = 'output'}
%   'outfix': output file suffix
%     {default = 'multivar_diff_stats'}
%   'gender_flag': [0|1] include gender as covariate
%     {default = 1}
%   'forceflag': overwrite existing output
%     {default = 0}
%
% Created:  07/30/18 by Don Hagler
% Prev Mod: 07/31/18 by Don Hagler
% Last Mod: 11/05/18 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,3), return; end;

parms = mmil_args2parms(varargin,{...
  'outdir',[pwd '/mvd'],[],...
  'outstem','output',[],...
  'outfix','multivar_diff_stats',[],...
  'gender_flag',true,[false true],...
  'forceflag',false,[false true],...
  ...
  'fname_script','/space/md8/1/data/dhagler/work/projects/multivar_devel/R/mvd_array.R',[],...
});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(fname_reg,'file')
  error('file %s not found',fname_reg);
end;
if ~exist(fname_dat,'file')
  error('file %s not found',fname_dat);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_out = sprintf('%s/%s_%s_F.dat',parms.outdir,parms.outstem,parms.outfix);
if ~exist(fname_out,'file') || parms.forceflag
  cmd = sprintf('R2.15 --vanilla --file=%s --args',parms.fname_script);
  cmd = sprintf('%s %d',cmd,p);
  cmd = sprintf('%s %d',cmd,q);
  cmd = sprintf('%s %s',cmd,fname_reg);
  cmd = sprintf('%s %s',cmd,fname_dat);
  cmd = sprintf('%s %s',cmd,parms.outdir);
  cmd = sprintf('%s %s',cmd,parms.outstem);
  cmd = sprintf('%s %s',cmd,parms.outfix);
  if parms.gender_flag
    cmd = sprintf('%s TRUE',cmd);
  else
    cmd = sprintf('%s FALSE',cmd);
  end;
  fprintf('%s\n',cmd);
  [s,r] = unix(cmd);
  if s
    error('cmd %s failed:\n%s',cmd,r);
  else
    fprintf('%s\n',r);  
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(fname_out,'file')
  error('file %s not found',fname_out);
end;

% load binary data files
stats.F = load_data(fname_out);

fname_out = sprintf('%s/%s_%s_Pillai.dat',parms.outdir,parms.outstem,parms.outfix);
if exist(fname_out,'file')
  stats.Pillai = load_data(fname_out);
end;

fname_out = sprintf('%s/%s_%s_p.dat',parms.outdir,parms.outstem,parms.outfix);
if exist(fname_out,'file')
  stats.p = load_data(fname_out);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = load_data(fname_data)
  data = [];
  fid = fopen(fname_data,'r');
  if fid<0, error('failed to open %s for reading',fname_data); end;
  nd = fread(fid,1,'integer*4');
  vz = zeros(1,nd);
  for i=1:nd
    vz(i) = fread(fid,1,'integer*4');
  end;
  nv = prod(vz);
  d = fread(fid,nv,'double');
  fclose(fid);
  data = reshape(d,vz);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


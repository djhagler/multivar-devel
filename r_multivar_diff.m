function stats = r_multivar_diff(fname_reg,fname_dat,varargin)
%function stats = r_multivar_diff(fname_reg,fname_dat,[options])
%
% Required Input:
%   fname_reg
%   fname_dat
%
% Optional Input:
%   'outdir': output directory
%     {default = [pwd '/multivar_diff']}
%   'outstem': output file stem
%     {default = 'output'}
%   'outfix': output file suffix
%     {default = 'multivar_diff_stats'}
%   'forceflag': overwrite existing output
%     {default = 0}
%
% Created:  07/01/18 by Don Hagler
% Prev Mod: 07/17/18 by Don Hagler
% Last Mod: 07/22/18 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~mmil_check_nargs(nargin,3), return; end;

parms = mmil_args2parms(varargin,{...
  'outdir',[pwd '/mvd'],[],...
  'outstem','output',[],...
  'outfix','multivar_diff_stats',[],...
  'forceflag',false,[false true],...
  ...
  'fname_script','/space/md8/1/data/dhagler/work/projects/multivar_devel/R/mvd.R',[],...
});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(fname_reg,'file')
  error('file %s not found',fname_reg);
end;
if ~exist(fname_dat,'file')
  error('file %s not found',fname_dat);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fname_out = sprintf('%s/%s_%s.csv',parms.outdir,parms.outstem,parms.outfix);
if ~exist(fname_out,'file') || parms.forceflag
  cmd = sprintf('R2.15 --vanilla --file=%s --args',parms.fname_script);
  cmd = sprintf('%s %s',cmd,fname_reg);
  cmd = sprintf('%s %s',cmd,fname_dat);
  cmd = sprintf('%s %s',cmd,parms.outdir);
  cmd = sprintf('%s %s',cmd,parms.outstem);
  cmd = sprintf('%s %s',cmd,parms.outfix);
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
stats = mmil_csv2struct(fname_out);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return;

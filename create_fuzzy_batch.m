function create_fuzzy_batch(fname_data,varargin)
%function create_fuzzy_batch(fname_data,[options])
%
% required input:
%   fname_data: input file name
%   
% optional input:
%   'batchname': name of batch directory
%     {default = 'fuzzyclust'}
%   'outdir': output directory
%     {default = pwd}
%   'numclust': number of clusters to form
%     may be a vector
%     {default = [2:20]}
%   'numruns': number of random start interations to run
%     {default = 1}
%   'membexp': membership exponential
%     ranges from 1 to 2
%     lower values are crisper, higer values are fuzzyier
%     may be a vector
%     {default = 1.27}
%   'maxattempts': maximum number of failure to converge before quitting
%     [default = 5}
%   'forceflag': [0|1] overwrite existing files
%     {default = 0}
%
% Created:  04/17/17 by Don Hagler
% Prev Mod: 04/22/17 by Don Hagler
% Last Mod: 08/06/18 by Don Hagler
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check input
if ~mmil_check_nargs(nargin,1), return; end;
parms = mmil_args2parms(varargin,{...
  'batchname','fuzzyclust',[],...
  'outdir',pwd,[],...
  'numclust',[2:20],[2,2000],...
  'numruns',1,[1,1000],...
  'membexp',1.27,[1,2],...
  'maxattempts',5,[1,1000],...
  'alpha',1,[1,100],...
  'forceflag',false,[false true],...
  ...
  'rscript','fuzzyclust.r',[],...
  'rcmd','R2.10',[],...
});

% create output batch directory
root_batchdir = sprintf('%s/batchdirs',getenv('HOME'));
mmil_mkdir(root_batchdir);
batchdir = sprintf('%s/batchdirs/%s',getenv('HOME'),parms.batchname);
scriptlistfname = sprintf('%s/scriptlist.txt',batchdir);
if exist(batchdir,'dir')
  cmd = sprintf('rm -rf %s\n',batchdir);
  fprintf('cmd = %s',cmd);
  [status,result] = unix(cmd);
  if status
    fprintf('%s: WARNING: cmd %s failed:\n%s',mfilename,cmd,result);
  end;
end;

% create scriptlist
mmil_mkdir(batchdir)
fid = fopen(scriptlistfname,'w');
if fid==-1
  error('failed to open scriptlist file %s for writing\n',scriptlistfname);
end;
fclose(fid);

% create jobs
j=1;
for i=1:numel(parms.numclust)
  k=parms.numclust(i);
  for m=1:numel(parms.membexp)
    membexp = parms.membexp(m);

    % set job file stem
    jstem = sprintf('clust%d_membexp%0.2f',k,membexp);
    if length(jstem)>30, jstem = jstem(1:30); end;
    jstem = regexprep(jstem,'[\^\-\.]','_');

    % create job
    fprintf('%s: creating job for %s...\n',mfilename,jstem);
    jobID = sprintf('job_%03d_%s',j,jstem); j = j+1;
    jobfname = sprintf('%s/%s.csh',batchdir,jobID);
    
    % write csh script to run R
    fid = fopen(jobfname,'wt');
    fprintf(fid,'#!/bin/csh\n');
    fprintf(fid,'\n');
    fprintf(fid,'set fname_data = %s\n',fname_data);
    fprintf(fid,'set k = %d\n',k);
    fprintf(fid,'set membexp = %0.2f\n',membexp);
    fprintf(fid,'set runs = %d\n',parms.numruns);
    fprintf(fid,'set outdir = %s\n',parms.outdir);
    if parms.forceflag
      fprintf(fid,'set forceflag = TRUE\n');
    else
      fprintf(fid,'set forceflag = FALSE\n');
    end;
    fprintf(fid,'set maxattempts = %d\n',parms.maxattempts);
    fprintf(fid,'set alpha = %0.2f\n',parms.alpha);
    fprintf(fid,'\n');
    fprintf(fid,'%s --vanilla --file=%s --args $fname_data $k $membexp $runs $outdir $forceflag $maxattempts $alpha\n',...
      parms.rcmd,parms.rscript);
    fclose(fid);
    % add to list
    fid = fopen(scriptlistfname,'a');
    fprintf(fid,'%s\n',jobID);
    fclose(fid);
  end
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if j==1
  fprintf('%s: WARNING: no jobs created\n',mfilename);
else
  fprintf('\n%%%% Now login to a cluster and run this:\n');
  fprintf('    qcshjobs %s\n',parms.batchname);
  fprintf('\n%%%% Or run this:\n');
  fprintf('    bcshjobs %s\n',parms.batchname);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


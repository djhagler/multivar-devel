ProjID = 'mvdev';
rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
indir = 'diff_surf';
outdir = 'clusters';
instem = 'distmat_MD1wg_sm_diff_H1';
meas = 'MD1wg';
outfix = '_sm_H1';

parms = [];
parms.numclust = [2:10];
parms.membexp = 1.2;
parms.numruns = 100;
parms.maxattempts = 1;
parms.rscript = '/home/dhagler/R/fuzzyclust.r';
parms.forceflag = 0;

parms.numclust = [2,6];
%parms.numruns = 1;
%parms.maxattempts = 3;

clustername = 'mmilcluster4';
batchcmd = 'qcshjobs';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parms.batchname = sprintf('%s_fuzzyclust_%s%s',ProjID,meas,outfix);
parms.outdir = sprintf('%s/%s/output/clust_%s%s',rootdir,outdir,meas,outfix);
fname_data = sprintf('%s/%s/output/distmats/%s_F.txt',rootdir,indir,instem);

args = mmil_parms2args(parms);
create_fuzzy_batch(fname_data,args{:});

cmd = sprintf('ssh %s %s %s',clustername,batchcmd,parms.batchname);
[s,r] = unix(cmd);
if s, error(r); end;
fprintf('%s\n',r);

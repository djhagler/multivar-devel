ProjID = 'mvdev';
rootdir = '/space/md8/1/data/dhagler/work/projects/multivar_devel';
indir = 'diff_surf';
outdir = 'clusters';
meas = 'MD1wg';
instem_stem = 'distmat_MD1wg_sm_diff';
outfix_stem = '_sm_diff';

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

niters = 10;
nhalves = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i=1:niters
  for j=1:nhalves
    instem = sprintf('%s%d_H%d',instem_stem,i,j);
    outfix = sprintf('%s%d_H%d',outfix_stem,i,j);
    
    parms.batchname = sprintf('%s_fuzzyclust_%s%s',ProjID,meas,outfix);
    parms.outdir = sprintf('%s/%s/output/clust_%s%s',rootdir,outdir,meas,outfix);
    fname_data = sprintf('%s/%s/output/distmats/%s_F.txt',rootdir,indir,instem);

    args = mmil_parms2args(parms);
    create_fuzzy_batch(fname_data,args{:});

    cmd = sprintf('ssh %s %s %s',clustername,batchcmd,parms.batchname);
    [s,r] = unix(cmd);
    if s, error(r); end;
    fprintf('%s\n',r);
  end;
end;



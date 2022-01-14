indir = [pwd '/output'];
outdir = [pwd '/output'];
outstem = 'compare_clusters_genders';
nclust = 6;
membexp = 1.2;
nruns = 100;
niters = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(outdir);
fname_out = sprintf('%s/%s.txt',outdir,outstem);
fid = fopen(fname_out,'wt');
if fid<0, error('failed to open %s for writing',fname_out); end;

fprintf('%s: comparing clusters for genders...\n',mfilename);

sdir1 = 'clust_MD1wg_sm_M';
sdir2 = 'clust_MD1wg_sm_F';

instem = sprintf('clust%d_membexp%0.2f_runs%d_clusters.txt',nclust,membexp,nruns);

fname1 = sprintf('%s/%s/%s',indir,sdir1,instem);
fname2 = sprintf('%s/%s/%s',indir,sdir2,instem);

clusters1 = mmil_readtext(fname1,' ');
clusters2 = mmil_readtext(fname2,' ');

clustvals1 = cell2mat(clusters1(2:end,2:end));
clustvals2 = cell2mat(clusters2(2:end,2:end));

[tmp,indmax1] = max(clustvals1,[],2);
[tmp,indmax2] = max(clustvals2,[],2);

[AR,RI] = randindex(indmax1,indmax2);

fprintf('AR = %0.3f  RI = %0.3f\n',AR,RI);
fprintf(fid,'M vs F: AR = %0.3f  RI = %0.3f\n',AR,RI);


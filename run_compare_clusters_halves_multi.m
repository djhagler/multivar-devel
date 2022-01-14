indir = [pwd '/output'];
outdir = [pwd '/output'];
outstem = 'compare_clusters_halves_multi';
nclust = 6;
membexp = 1.2;
nruns = 100;
niters = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mmil_mkdir(outdir);
fname_out = sprintf('%s/%s.txt',outdir,outstem);
fid = fopen(fname_out,'wt');
if fid<0, error('failed to open %s for writing',fname_out); end;

ARvec = nan(niters,1); RIvec = nan(niters,1);
for i=1:niters

  fprintf('%s: comparing clusters for iter %d...\n',...
    mfilename,i);

  sdir1 = sprintf('clust_MD1wg_sm_diff%d_H1',i);
  sdir2 = sprintf('clust_MD1wg_sm_diff%d_H2',i);

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
  ARvec(i) = AR;
  RIvec(i) = RI;
  
  fprintf('AR = %0.3f  RI = %0.3f\n',AR,RI);
  fprintf(fid,'iter %d: AR = %0.3f  RI = %0.3f\n',i,AR,RI);
end;

minAR = min(ARvec);
maxAR = max(ARvec);
meanAR = mean(ARvec);
stdAR = std(ARvec);
medianAR = median(ARvec);

fprintf('min AR = %0.3f, max AR = %0.3f\n',minAR,maxAR);
fprintf('mean AR = %0.3f, stdev AR = %0.3f\n',meanAR,stdAR);
fprintf('median AR = %0.3f\n',medianAR);

fprintf(fid,'min AR = %0.3f, max AR = %0.3f\n',minAR,maxAR);
fprintf(fid,'mean AR = %0.3f, stdev AR = %0.3f\n',meanAR,stdAR);
fprintf(fid,'median AR = %0.3f\n',medianAR);


minRI = min(RIvec);
maxRI = max(RIvec);
meanRI = mean(RIvec);
stdRI = std(RIvec);
medianRI = median(RIvec);

fprintf('min RI = %0.3f, max RI = %0.3f\n',minRI,maxRI);
fprintf('mean RI = %0.3f, stdev RI = %0.3f\n',meanRI,stdRI);
fprintf('median RI = %0.3f\n',medianRI);

fprintf(fid,'min RI = %0.3f, max RI = %0.3f\n',minRI,maxRI);
fprintf(fid,'mean RI = %0.3f, stdev RI = %0.3f\n',meanRI,stdRI);
fprintf(fid,'median RI = %0.3f\n',medianRI);

fclose(fid);


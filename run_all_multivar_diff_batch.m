%run_multivar_Dwg_diff_batch
%[s,r] = unix('ssh mmilcluster4 qmatjobs4 multivar_Dwg_sm_diff');
%if s,error(r); end; fprintf('%s\n',r);
run_multivar_M1_diff_batch
[s,r] = unix('ssh mmilcluster4 qmatjobs4 multivar_M1_sm_diff');
if s,error(r); end; fprintf('%s\n',r);
run_multivar_Dg_diff_batch
[s,r] = unix('ssh mmilcluster4 qmatjobs4 multivar_Dg_sm_diff');
if s,error(r); end; fprintf('%s\n',r);
run_multivar_Dw_diff_batch
[s,r] = unix('ssh mmilcluster4 qmatjobs4 multivar_Dw_sm_diff');
if s,error(r); end; fprintf('%s\n',r);
run_multivar_M_diff_batch
[s,r] = unix('ssh mmilcluster4 qmatjobs4 multivar_M_sm_diff');
if s,error(r); end; fprintf('%s\n',r);


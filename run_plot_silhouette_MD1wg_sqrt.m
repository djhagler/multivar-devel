measname = 'MD1wg_sm_sqrt';

parms = [];
parms.rootdir = pwd;
parms.fig_size = [2 2];
parms.tif_dpi = 300;
parms.eps_flag = 1;
parms.visible_flag = 0;
parms.numclust = [2:10];
parms.membexp = 1.2;
parms.numruns = 100;
parms.nvalid_thresh = 0;
%parms.slim = [0.15,0.35];
parms.slim = [0.15,0.8];
parms.legend_flag = 0;
parms.forceflag = 1;

%parms.membexp = [1.1,1.15,1.2,1.25,1.3,1.4,1.5];
parms.membexp = [1.1,1.2,1.4];
%parms.membexp = [1.1,1.2];
parms.numruns = 1;
parms.slim = [0,0.4];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

args = mmil_parms2args(parms);
plot_silhouette(measname,args{:});


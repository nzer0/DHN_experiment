function visualize(data, frm_num, color)
darwin2bvh(data, frm_num);
addpath('MOCAP_Toolbox');
addpath('NDLUTIL');
bvhPlayFile('DarwinMove.bvh', color);

end
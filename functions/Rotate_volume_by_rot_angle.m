function [v] = Rotate_volume_by_rot_angle(volume,rot_angle,is_image)

% volume can be image or segmentation, is_image = 1 for image 
if is_image == 1
    interp = 'linear';
else
    interp = 'nearest';
end

min_val = min(volume(:));
tic
[~,M_z] = Rotation_Matrix_From_Three_Axis(0,0,-rot_angle.first_z,0);
tform_z = affine3d(M_z);
v = imwarp(volume,tform_z,'FillValue',min_val,'interp',interp);
disp(['finish first rot; two rots left']);
[~,M_x] = Rotation_Matrix_From_Three_Axis(-rot_angle.second_x,0,0,0);
tform_x = affine3d(M_x);
v = imwarp(v,tform_x,'FillValue',min_val,'interp',interp);
disp(['finish second rot; one rot left']);
[~,M_y] = Rotation_Matrix_From_Three_Axis(0,0,rot_angle.third_z,0);
tform_y = affine3d(M_y');
v = imwarp(v,tform_y,'FillValue',min_val,'interp',interp);
disp(['finish all rotation']);
toc
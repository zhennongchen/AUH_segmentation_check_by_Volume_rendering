%% add path for functions (modify for your own workstation)
clear all;close all
%%%% define the code path in which you save these scripts
code_path = '/Users/zhennongchen/Documents/GitHub/AUH_segmentation_check_by_Volume_rendering/';
addpath(genpath(code_path));

%%%% define the data path in which you save image and segmentation data
data_path = '/Users/zhennongchen/Documents/Zhennong_CT_Data/AUH/';

% load pre-set rendering configuration
load([code_path,'config_LV_rendering.mat'])
%% Define patients (modify for your own workstation)
%%%% define the patient 
patient = '62/62pre';

% find out time frames in this patient
files = dir([data_path,patient,'/img-nii/*.nii.gz']);
timeframes = [];
for i = 1: size(files,1)
    n = files(i).name;
    s = split(n,'.');
    timeframes = [timeframes str2num(s{1})+1];
end
timeframes = sort(timeframes);
clear n s files i
%% Define movie information (modify for your own workstation)
%%%% step 1: define the view angles
% degree 0 = anterolateral, 60 = inferolateral, 120 = inferior
% 180 = inferoseptal, 240 = ateroseptal, 300 = anterior
view_angles = [300,240,180,120,60,0];

%%%% step 2a: define whether you want to view from the top of MV plane as well
view_top = 1;
top_position = [-2 0 4]; % default, change the third number to smaller if you want to view more closely.change the first to tilt your angle, but always keep the second as 0.

%%%% step 2b: define whther you want to view from the apex
view_apex = 1;
apex_position = [2 0 -3]; % default,change the third number to larger if you want to view more closely.change the first to tilt your angle, but always keep the second as 0.

%%%% step 3: define movie save format
% Default = 'MPEG-4', can also be 'Motion JPEG AVI' but will have
% compressiong loss
format = 'MPEG-4';

%%%% step 3: define movie file name
p = split(patient,'/');
movie_name = [p{2},'_volume_rendering_for_plane_check'];
save_path = [data_path,patient,'/',p{2},'_volume_rendering_for_plane_check'];
clear p
%% Load and process segmentation data (just run)
for t = timeframes
    %%% load raw data
    img_data = load_nii([data_path,patient,'/img-nii/',num2str(t-1),'.nii.gz']);
    image = Transform_nii_to_dcm_coordinate(double(img_data.img),0);
    if t-1 < 10
        seg_data = load_nii([data_path,patient,'/seg-nii/','seg_0',num2str(t-1),'.nii.gz']);
    else
        seg_data = load_nii([data_path,patient,'/seg-nii/','seg_',num2str(t-1),'.nii.gz']);
    end
    seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
    % segmentation of LV only
    seg_lv = double((seg==1));
    hdr = img_data.hdr;
    disp(['finish loading time frame ',num2str(t-1)]);

    %%% find the correct orientation by clicking landmarks
    if t == 1
        rot_angle = Obtain_Reorientation_Angle_for_Patient(image,seg,0,0);
    end

    %%% rotate the segmentation
    [seg_lv_rot] = Rotate_volume_by_rot_angle(seg_lv,rot_angle,0);
    if t == 1
        % define a bounding box to minimize the image size
        [box] = Bounding_box(seg_lv_rot,30);
    end
    seg_lv_rot = seg_lv_rot(box(1):box(2),box(3):box(4),box(5):box(6));
    Data_processed(t).seg_lv_rot = seg_lv_rot;
    disp(['finish processing time frame ',num2str(t-1)]);
    clear seg_lv_rot
end
clear t
%% make movies (just run)
writerObj = VideoWriter(save_path,format);
writeObj.Quality = 100;
writerObj.FrameRate = round(size(timeframes,2)/2);
open(writerObj);

for angle = view_angles
    [config_new] = Get_New_Config_After_Rotation(config_LV_rendering,angle);
    for t = timeframes
        h = figure('pos',[10 10 500 500]);
        volshow(Data_processed(t).seg_lv_rot,config_new,'ScaleFactor',[1,1,1]); 
        frame = getframe(h);
        writeVideo(writerObj, frame);
        close all
        clear h frame
    end
    disp(['finish angle ',num2str(angle)]);
    clear config_new t
end
if view_top == 1
    config_new = config_LV_rendering;
    config_new.CameraPosition = top_position;
    for t = timeframes
        h = figure('pos',[10 10 500 500]);
        volshow(Data_processed(t).seg_lv_rot,config_new,'ScaleFactor',[1,1,1]); 
        frame = getframe(h);
        writeVideo(writerObj, frame);
        close all
        clear h frame
    end
    disp(['finish top view']);
end

if view_apex == 1
    config_new = config_LV_rendering;
    config_new.CameraPosition = apex_position;
    for t = timeframes
        h = figure('pos',[10 10 500 500]);
        volshow(Data_processed(t).seg_lv_rot,config_new,'ScaleFactor',[1,1,1]); 
        frame = getframe(h);
        writeVideo(writerObj, frame);
        close all
        clear h frame
    end
    disp(['finish apex view']);
end
close(writerObj);
close all
disp(['Done making movie'])
% %%
% config_new = config_LV_rendering;
% config_new.CameraPosition = [2 0 -3];
% volshow(Data_processed(10).seg_lv_rot,config_new)
%         
        
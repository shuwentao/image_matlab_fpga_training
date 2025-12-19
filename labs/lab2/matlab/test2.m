% ===================== 1. 读取并预处理图像 =====================
% 读取 Barbara.bmp 并转为灰度图
img = imread('/home/wentao/Downloads/图像处理常用/Barbara.bmp');
if size(img, 3) == 3  % 若为彩色图，转为灰度图
    img_gray = rgb2gray(img);
else
    img_gray = img;
end
[row, col] = size(img_gray);  % 获取图像尺寸：行×列
fprintf('原图尺寸：%d 行 × %d 列\n', row, col);

pixel_row = img_gray';  % 转置：行变列，列变行
pixel_1d = pixel_row(:);  % 展开为一维数组（按行顺序）


%打印图像灰度到文件
fid = fopen('Barbara_gray_pixels.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(pixel_1d)
    fprintf(fid, '%02x\n', pixel_1d(i));  
end
fclose(fid); 


start_x_pos = 99 %ppc=2 start_x must be an odd number.Within the FPGA configuration context, the value of crop_start_x is calculated as (start_x_pos + 1) divided by 2
start_y_pos = 100
crop_width = 150
crop_height = 150
end_x_pos = start_x_pos + 150 
end_y_pos = start_y_pos + 150

cropped = img_gray(start_y_pos:(end_y_pos-1),start_x_pos:(end_x_pos-1));


%打印左右padding的图像灰度到文件
pixel_row = cropped';  % 转置：行变列，列变行
pixel_1d = pixel_row(:);  % 展开为一维数组（按行顺序）

fid = fopen('Barbara_gray_pixels_crop.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(pixel_1d)
    fprintf(fid, '%02x\n', pixel_1d(i));  
end
fclose(fid); 

figure('Name', 'Barbara 灰度图左右镜像 Padding 对比');
% 子图1：原图
subplot(1,2,1);
imshow(img_gray);
title(sprintf('原图（%d×%d）', row, col));
axis on;  % 显示坐标轴，便于观察列数变化

% 子图2：填充后图像
subplot(1,2,2);
imshow(cropped);
title(sprintf('左右裁剪图像\n'));
axis on;


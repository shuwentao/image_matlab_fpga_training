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

% ===================== 2. 定义左右镜像 Padding 参数 =====================
pad_col = 2;  % 左右各填充 50 列（可自定义，如 100、200 等）
pad_row = 2;  % 上下各填充 50 列（可自定义，如 100、200 等）
% padSize 格式：[行填充数 列填充数] → 行填充0，列填充pad_col



% ===================== 3. 执行左右镜像 Padding =====================
% 2. 手动实现列维度反射填充
% 左侧反射填充：取原图 2~pad_cols+1 列，反向索引（反射）
left_reflect = img_gray(:, 1+pad_col:-1:2);  
% 右侧反射填充：取原图 end-1:-1:end-pad_cols 列，反向索引（反射）
right_reflect = img_gray(:, end-1:-1:end-pad_col);  
% 验证填充后尺寸：行不变，列 = 原列数 + 2×pad_col
img_reflect_manual = [left_reflect, img_gray, right_reflect];


%打印左右padding的图像灰度到文件
pixel_row = img_reflect_manual';  % 转置：行变列，列变行
pixel_1d = pixel_row(:);  % 展开为一维数组（按行顺序）

fid = fopen('Barbara_gray_pixels_col.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(pixel_1d)
    fprintf(fid, '%02x\n', pixel_1d(i));  
end
fclose(fid); 



% ===================== 4. 执行上下镜像 Padding =====================
top_reflect = img_reflect_manual(1+pad_row:-1:2,:);
bottom_reflect = img_reflect_manual(end-1:-1:end-pad_row,:);

img_reflect_manual2 = [top_reflect;img_reflect_manual;bottom_reflect];

[row_pad, col_pad] = size(img_reflect_manual2);
fprintf('填充后尺寸：%d 行 × %d 列\n', row_pad, col_pad);

pixel_row = img_reflect_manual2';  % 转置：行变列，列变行
pixel_1d = pixel_row(:);  % 展开为一维数组（按行顺序）

%打印上下padding的图像灰度到文件
fid = fopen('Barbara_gray_pixels_col_row.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(pixel_1d)
    fprintf(fid, '%02x\n', pixel_1d(i));  
end
fclose(fid); 

% ===================== 5. 可视化对比 =====================
figure('Name', 'Barbara 灰度图左右镜像 Padding 对比');
% 子图1：原图
subplot(1,2,1);
imshow(img_gray);
title(sprintf('原图（%d×%d）', row, col));
axis on;  % 显示坐标轴，便于观察列数变化

% 子图2：填充后图像
subplot(1,2,2);
imshow(img_reflect_manual2);
title(sprintf('左右镜像填充后（%d×%d）\n（左右各填充%d列）', row_pad, col_pad, pad_col));
axis on;

% ===================== 可选：保存填充后的图像 =====================
%imwrite(img_padded, 'Barbara_gray_padded_symmetric.png');
%fprintf('填充后的图像已保存为：Barbara_gray_padded_symmetric.png\n');
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

% ===================== 2. 定义左右镜像 Padding 参数 =====================
pad_col = 2;  % 左右各填充 50 列（可自定义，如 100、200 等）
% padSize 格式：[行填充数 列填充数] → 行填充0，列填充pad_col
padSize = [0, pad_col];  
pad_method = 'symmetric';  % 镜像填充（对称）
pad_direction = 'both';    % 左右都填充（仅列维度）

% ===================== 3. 执行左右镜像 Padding =====================
img_padded = padarray(img_gray, padSize, pad_method, pad_direction);
% 验证填充后尺寸：行不变，列 = 原列数 + 2×pad_col
[row_pad, col_pad] = size(img_padded);
fprintf('填充后尺寸：%d 行 × %d 列\n', row_pad, col_pad);

% ===================== 4. 可视化对比 =====================
figure('Name', 'Barbara 灰度图左右镜像 Padding 对比');
% 子图1：原图
subplot(1,2,1);
imshow(img_gray);
title(sprintf('原图（%d×%d）', row, col));
axis on;  % 显示坐标轴，便于观察列数变化

% 子图2：填充后图像
subplot(1,2,2);
imshow(img_padded);
title(sprintf('左右镜像填充后（%d×%d）\n（左右各填充%d列）', row_pad, col_pad, pad_col));
axis on;

% ===================== 可选：保存填充后的图像 =====================
%imwrite(img_padded, 'Barbara_gray_padded_symmetric.png');
%fprintf('填充后的图像已保存为：Barbara_gray_padded_symmetric.png\n');
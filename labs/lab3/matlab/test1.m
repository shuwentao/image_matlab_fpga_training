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
% 转为 double 类型并归一化（0-1），避免 uint8 溢出
img_double = im2double(img_gray);  

% ===================== 2. 定义数字增益系数 =====================
gain_factor = 1.8;  % 增益系数：1.8（增强亮度），可改为 0.5（减弱）


% ===================== 3. 应用数字增益 =====================
img_gain_double = img_double * gain_factor;
% 截断超出 0-1 范围的值（归一化后）
img_gain_double(img_gain_double > 1) = 1;  % 上限1（对应255）
img_gain_double(img_gain_double < 0) = 0;  % 下限0（对应0）

% ===================== 4. 转回 uint8 类型（可选）=====================
img_gain_uint8 = im2uint8(img_gain_double);

%打印图像灰度到文件
img_gain_uint8_row = img_gain_uint8'
img_gain_uint8_1d = img_gain_uint8_row(:)
fid = fopen('Barbara_gray_pixels_gain.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(img_gain_uint8_1d)
    fprintf(fid, '%02x\n', img_gain_uint8_1d(i));  
end
fclose(fid); 

% ===================== 5. 可视化对比 =====================
figure('Name', '图像数字增益效果');
subplot(1,2,1); imshow(img_gray); title('原图（无增益）');
subplot(1,2,2); imshow(img_gain_uint8); title(['数字增益（k=', num2str(gain_factor), '）']);

% ===================== 6. 保存增益后的图像 =====================
%imwrite(img_gain_uint8, 'Barbara_digital_gain.png');
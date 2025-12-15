% 1. 读取 BMP 图像（自动识别路径、格式、尺寸、位深）
img = imread('/home/wentao/Downloads/图像处理常用/Barbara.bmp');  % 若文件不在当前路径，需写绝对路径（如 'D:\images\Barbara.bmp'）

% 2. 检查图像信息（可选，确认维度、类型）
disp('图像尺寸（行×列×通道）：');
disp(size(img));  % 灰度图输出 [512 512]，彩色图输出 [512 512 3]
disp('图像数据类型：');
disp(class(img)); % 通常为 uint8（8bit）

% 3. 显示图像
figure('Name','Barbara.bmp 原图');
imshow(img);  % 灰度图直接显示，彩色图自动按RGB渲染
title('Barbara.bmp (512×512)');

pixel_row = img';  % 转置：行变列，列变行
pixel_1d = pixel_row(:);  % 展开为一维数组（按行顺序）

fid = fopen('Barbara_gray_pixels.txt', 'w');  % 新建/覆盖文件
if fid == -1
    error('无法创建文件，请检查路径权限');
end
for i = 1:length(pixel_1d)
    fprintf(fid, '%02x\n', pixel_1d(i));  
end
fclose(fid); 



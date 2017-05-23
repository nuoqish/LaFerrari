#!/bin/sh


# 参数说明
# -inputDir： 输入图片的目录
# -inputImage：测试图片文件名
# -inputTrimap: 测试图片对应的输入三值图（初始分割图）

# -inputER: 对输入三值图进行腐蚀的半径大小，这里设置为30，可以酌情减小以提高速度
# -inputLevel
# -outputAlpha: 输入遮罩图


./AlphaSolver -inputImage ./testImage/15465-600-1400-1600-2000.png -inputTrimap ./testImage/15465-trimap-600-1400-1600-2000.png -inputER 10 -inputLevel 1 -outputAlpha ./testImage/15465-alpha.png




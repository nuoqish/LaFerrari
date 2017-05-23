//
//  AlphaMattor.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "AlphaMattor.hpp"

#include "TrimapSegmentator.hpp"
#include "LNSPMattor.hpp"

Rect makeRect(Vec4i region, double scale, double erodeRatio = 1) {
    
    double xoff = (region[3] - region[1]) * (erodeRatio - 1);
    double yoff = (region[2] - region[0]) * (erodeRatio - 1);
    double x = region[1] - xoff;
    double y = region[0] - yoff;
    double width = (region[3] - region[1]) + 2 * xoff;
    double height = (region[2] - region[0]) + 2 * yoff;
    
    return Rect_<int>(int(x * scale),
                      int(y * scale),
                      int(width * scale),
                      int(height * scale));
}


void erodeTrimap(cv::Mat1b &_trimap, int r)
{
    if (r <= 0) {
        return;
    }
    
    cv::Mat1b &trimap = (cv::Mat1b&)_trimap;
    
    int w = trimap.cols;
    int h = trimap.rows;
    
    cv::Mat1b foreground(trimap.size(), (uchar)0);
    cv::Mat1b background(trimap.size(), (uchar)0);
    
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
        {
            if (trimap(y, x) == 0)
                background(y, x) = 1;
            else if (trimap(y, x) == 255)
                foreground(y, x) = 1;
        }
    
    
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(r, r));
    
    cv::erode(background, background, kernel);
    cv::erode(foreground, foreground, kernel);
    
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
        {
            if (background(y, x) == 0 && foreground(y, x) == 0)
                trimap(y, x) = 128;
        }
}


AlphaMattor::AlphaMattor() {
    
}

AlphaMattor::~AlphaMattor() {
    
}

void AlphaMattor::process(Mat1b &dstAlpha, Mat4b &dstForegroundWithAlpha,
                          Mat3b &srcImage, Mat1b &srcTrimap, Mat1b &srcLabel,
                          int trimapErodeRadius, int label) {
    
    
    erodeTrimap(srcTrimap, trimapErodeRadius);
    
    //imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-trimap.png", srcTrimap);
    
    TrimapSegmentator trimapSegmentator;
    LNSPMattor lnspMattor;
    
    
    if (dstAlpha.rows == 0 || dstAlpha.cols == 0) {
        srcTrimap.copyTo(dstAlpha);
    }
    if (dstForegroundWithAlpha.rows == 0 || dstForegroundWithAlpha.cols ==0) {
        dstForegroundWithAlpha = Mat4b(srcImage.rows, srcImage.cols);
    }
    double scale = max((double)srcTrimap.rows / srcLabel.rows, (double)srcTrimap.cols / srcLabel.cols);
    
    if (label == -1) {
        vector<Vec4i> segRegions;
        trimapSegmentator.process(segRegions, srcTrimap, srcLabel);
        for (int i = 0; i < segRegions.size(); i++) {
            
            
            Rect rect = makeRect(segRegions[i], scale, 1);
            Mat1b alpha = dstAlpha(rect);
            Mat4b foregroundAlpha = dstForegroundWithAlpha(rect);
            Mat3b image = srcImage(rect);
            Mat1b trimap = srcTrimap(rect);
            
            char fn[256];
            sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
            imwrite(fn, image);
            sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-trimap-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
            imwrite(fn, trimap);
            
            
            //        lnspMattor.process(alpha, foregroundAlpha, image, trimap);
            //
            //        sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-fore-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
            //        imwrite(fn, foregroundAlpha);
            
        }
    }
    else {
        Vec4i region = trimapSegmentator.calcRegionForLabel(srcLabel, label);
        if (region[0] != (srcLabel.rows - 1) && region[1] != (srcLabel.cols - 1)) {
            Rect rect = makeRect(region, scale, 1.2);
            Mat1b alpha = dstAlpha(rect);
            Mat4b foregroundAlpha = dstForegroundWithAlpha(rect);
            Mat3b image = srcImage(rect);
            Mat1b trimap = srcTrimap(rect);
            
            char fn[256];
            sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
            imwrite(fn, image);
            sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-trimap-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
            imwrite(fn, trimap);
            
//            lnspMattor.process(alpha, foregroundAlpha, image, trimap);
//            
//            sprintf(fn, "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/15465-fore-%d-%d-%d-%d.png", rect.x, rect.y, rect.width, rect.height);
//            imwrite(fn, foregroundAlpha);
            
            
        }
        
        
    }
    
    
    
}

//
//  AlphaSolver.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "AlphaSolver.hpp"

#include "PLNSPMattor.hpp"



void erodeTrimapFB(cv::Mat1b &_trimap, int r)
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



void AlphaSolver::computeAlpha(Mat1d &dstAlpha, Mat3b &srcImage, Mat1b &srcTrimap, int erodeRadius, int level, int winRadius, float lamda, double tolerance, int maxIters) {
    
    clock_t tic = clock();
    
    if (erodeRadius > 0) {
        erodeTrimapFB(srcTrimap, erodeRadius);
    }
    
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    
    Mat3d image(rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            image(i, j)[0] = srcImage(i, j)[0] / 255.;
            image(i, j)[1] = srcImage(i, j)[1] / 255.;
            image(i, j)[2] = srcImage(i, j)[2] / 255.;
        }
    }

    PLNSPMattor::solveAlpha(dstAlpha, image, srcTrimap, level, winRadius, lamda, tolerance, maxIters);
    
    printf("total process time cost time: %.3f ms\n", 1000. *(clock() - tic) / CLOCKS_PER_SEC);
    
    
}

void AlphaSolver::computeAlpha(Mat1b &dstAlpha, Mat3b &srcImage, Mat1b &srcTrimap, int erodeRadius, int level, int winRadius, float lamda, double tolerance, int maxIters) {
    
    Mat1d alpha;
    computeAlpha(alpha, srcImage, srcTrimap, erodeRadius, level, winRadius, lamda, tolerance, maxIters);
    
    if (dstAlpha.rows != alpha.rows || dstAlpha.cols != alpha.cols) {
        dstAlpha = Mat1b(alpha.rows, alpha.cols);
    }
    
    for (int i = 0; i < alpha.rows; i++) {
        for (int j = 0; j < alpha.cols; j++) {
            dstAlpha(i,j) = uint8_t(max(0., min(255., alpha(i, j) * 255.)));
        }
    }
    
}



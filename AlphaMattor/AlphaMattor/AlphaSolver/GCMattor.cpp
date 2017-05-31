//
//  GCMattor.cpp
//  LaFerrari
//
//  Created by stanshen on 17/5/25.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#include "GCMattor.hpp"

class GCMattorInfo {
public:
    GCMattorInfo(){reset();}
    ~GCMattorInfo(){}
    Mat& getFgdModel() {
        return fgdModel;
    }
    Mat& getBgdModel() {
        return bgdModel;
    }
    Mat1b& getGrabcutResult() {
        return grabcutResult;
    }
    Rect& getCropRect() {
        return cropRect;
    }
    void reset() {
        isFinished = false;
        grabcutResult = Mat1b(0,0);
        cropRect = Rect_<int>(0,0,0,0);
    }

public:
    bool isFinished;
    
private:
    Mat fgdModel;
    Mat bgdModel;
    Mat1b grabcutResult;
    Rect cropRect;
    
};


GCMattor::GCMattor() {
    _mattorInfo = new GCMattorInfo();
}

GCMattor::~GCMattor() {
    if (_mattorInfo) {
        delete _mattorInfo;
        _mattorInfo = NULL;
    }
}



Rect_<int> GCMattor::extractForegroundRect(Mat& image) {
    
    cv::Rect_<int> rect;
    
    Mat gray;
    cvtColor(image, gray, COLOR_BGR2GRAY);
    Mat1b result;
    double thresh = 0;
    threshold(gray, result, thresh, 255, THRESH_BINARY_INV + THRESH_OTSU);
    
    int top = image.rows - 1;
    int bottom = 0;
    int left = image.cols - 1;
    int right = 0;
    
    for (int i = 0; i < image.rows; i++) {
        for (int j = 0; j < image.cols; j++) {
            if (result(i,j) == 255) {
                if (i < top) {
                    top = i;
                }
                if (i > bottom) {
                    bottom = i;
                }
                if (j < left) {
                    left = j;
                }
                if (j > right) {
                    right = j;
                }
            }
        }
    }
    
    return Rect_<int>(left, top, right - left, bottom - top);
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


void localSmooth(Mat3b& srcImage, Mat1b& srcTrimap, Mat1b& dstAlpha, Mat4b& dstForegroundAlpha, int radius) {
    Mat1b alpha;
    srcTrimap.copyTo(alpha);
    erodeTrimap(alpha, radius);
    double sigma_d2 = radius;
    double sigma_c2 = 10000;
    for (int i = 0; i < srcTrimap.rows; i++) {
        for (int j = 0; j < srcTrimap.cols; j++) {
            if (alpha(i,j) == 128) {
                int imin = max(i - radius, 0);
                int imax = min(i + radius, srcTrimap.rows - 1);
                int jmin = max(j - radius, 0);
                int jmax = min(j + radius, srcTrimap.cols - 1);
                double Wa = 0,Wsum = 0;
                for (int ii = imin; ii <= imax; ii++) {
                    for (int jj = jmin; jj <= jmax; jj++) {
                        double d2 = (ii - i) * (ii - i) + (jj - j) * (jj - j);
                        double c2 = (srcImage(ii,jj)[0] - srcImage(i,j)[0]) * (srcImage(ii,jj)[0] - srcImage(i,j)[0]) +
                        (srcImage(ii,jj)[1] - srcImage(i,j)[1]) * (srcImage(ii,jj)[1] - srcImage(i,j)[1]) +
                        (srcImage(ii,jj)[2] - srcImage(i,j)[2]) * (srcImage(ii,jj)[2] - srcImage(i,j)[2]);
                        double W = exp(-d2 / sigma_d2 - c2 / sigma_c2);
                        Wa += W * (srcTrimap(ii,jj));
                        Wsum += W;
                        
                    }
                }
                
                Wa /= Wsum;
                dstForegroundAlpha(i,j)[0] = uint8_t(dstForegroundAlpha(i,j)[0] * Wa / 255);
                dstForegroundAlpha(i,j)[1] = uint8_t(dstForegroundAlpha(i,j)[1] * Wa / 255);
                dstForegroundAlpha(i,j)[2] = uint8_t(dstForegroundAlpha(i,j)[2] * Wa / 255);
                alpha(i,j) = uint8_t(max(0., min(255., Wa)));;
            }
            
            
            dstForegroundAlpha(i,j)[3] = alpha(i,j);
            
        }
    }
    alpha.copyTo(dstAlpha);
    
}

void GCMattor::calcForegroundAlpha(Mat4b& dstForegroundAlpha, Mat1b& dstMaskMono, Mat4b& srcImage,
                         cv::Rect& cropRect, Mat1b& grabcutResult, Mat& fgdModel, Mat& bgdModel, int radius, int mode) {
    Mat3b image;
    cvtColor(srcImage, image, cv::COLOR_RGBA2RGB);
    
    if (cropRect.area() == 0) {
        cropRect = extractForegroundRect(image);
    }
    clock_t tic = clock();
    grabCut(image, grabcutResult, cropRect, bgdModel, fgdModel, 2, mode);
    printf("gc cost time: %.3f ms\n", 1000. * (clock() - tic) / CLOCKS_PER_SEC);
    compare(grabcutResult, GC_PR_FGD, dstMaskMono, CMP_EQ);
    clock_t tic2 = clock();
    srcImage.copyTo(dstForegroundAlpha);
    localSmooth(image, dstMaskMono, dstMaskMono, dstForegroundAlpha, radius);
    printf("ls cost time: %.3f ms\n", 1000. * (clock() - tic2) / CLOCKS_PER_SEC);
    
}

void GCMattor::process(Mat4b &dstForegroundAlpha, Mat1b &dstMaskMono, Mat4b &srcImage, Rect& cropRect, int radius, int gc_mode) {
    
    Mat& fgdModel = _mattorInfo->getFgdModel();
    Mat& bgdModel = _mattorInfo->getBgdModel();
    Mat1b& grabcutResult = _mattorInfo->getGrabcutResult();
    
    _mattorInfo->isFinished = false;
    calcForegroundAlpha(dstForegroundAlpha, dstMaskMono, srcImage, cropRect, grabcutResult, fgdModel, bgdModel, radius, gc_mode);
    _mattorInfo->isFinished = true;
    
}

void GCMattor::process(Mat4b &dstForegroundAlpha, Mat1b &dstMaskMono, Mat4b &srcImage, int radius, int gc_mode) {
    
    Mat& fgdModel = _mattorInfo->getFgdModel();
    Mat& bgdModel = _mattorInfo->getBgdModel();
    Mat1b& grabcutResult = _mattorInfo->getGrabcutResult();
    Rect& cropRect = _mattorInfo->getCropRect();
    _mattorInfo->isFinished = false;
    calcForegroundAlpha(dstForegroundAlpha, dstMaskMono, srcImage, cropRect, grabcutResult, fgdModel, bgdModel, radius, gc_mode);
    _mattorInfo->isFinished = true;
    
}

bool GCMattor::isFinished() {
    return _mattorInfo->isFinished;
}

void GCMattor::setValue(int row, int col, uint8_t value) {
    if (!isFinished()) {
        return;
    }
    Mat1b grabcutResult = _mattorInfo->getGrabcutResult();
    grabcutResult(row, col) = value;
}

void GCMattor::setCropRect(cv::Rect cropRect) {
    if (!isFinished()) {
        return;
    }
    Rect& rect = _mattorInfo->getCropRect();
    rect = Rect_<int>(cropRect.x, cropRect.y, cropRect.width, cropRect.height);
}

cv::Rect GCMattor::getCropRect() {
    return _mattorInfo->getCropRect();
}

void GCMattor::reset() {
    if (!isFinished()) {
        return;
    }
    _mattorInfo->reset();
}










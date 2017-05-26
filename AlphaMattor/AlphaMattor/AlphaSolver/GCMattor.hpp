//
//  GCMattor.hpp
//  LaFerrari
//
//  Created by stanshen on 17/5/25.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#ifndef GCMattor_hpp
#define GCMattor_hpp

#include <stdio.h>
#import <opencv2/opencv.hpp>
using namespace cv;
using namespace std;

class GCMattorInfo;

class GCMattor {
    
public:
    GCMattor();
    ~GCMattor();
    void setValue(int row, int col, uint8_t value);
    void process(Mat4b& dstForegroundAlpha, Mat1b& dstMaskMono, Mat4b& srcImage, cv::Rect& cropRect, int radius, int gc_mode);
    bool isFinished();
    
public:
    static Rect_<int> extractForegroundRect(Mat& image);
    static void calcForegroundAlpha(Mat4b& dstForegroundAlpha, Mat1b& dstMaskMono, Mat4b& srcImage,
                                    cv::Rect& cropRect, Mat1b& grabcutResult, Mat& fgdModel, Mat& bgdModel, int radius, int gc_mode);
    
    

    
private:
    
    GCMattorInfo *_mattorInfo;
    
};




#endif /* GCMattor_hpp */

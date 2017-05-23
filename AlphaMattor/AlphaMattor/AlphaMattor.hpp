//
//  AlphaMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/23.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef AlphaMattor_hpp
#define AlphaMattor_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>
using namespace std;
using namespace cv;

class AlphaMattor {
public:
    AlphaMattor();
    ~AlphaMattor();
    void process(Mat1b& dstAlpha, Mat4b& dstForegroundWithAlpha, Mat3b& srcImage, Mat1b& srcTrimap, Mat1b& srcLabelMap, int trimapErodeRadius = 0, int label = -1);
};


#endif /* AlphaMattor_hpp */

//
//  LNSPMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/21.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef LNSPMattor_hpp
#define LNSPMattor_hpp

#include <stdio.h>


#include <opencv2/opencv.hpp>


using namespace std;
using namespace cv;


class LNSPMattor {
    
public:
    
    static void process(Mat1b& dstAlpha, Mat4b& dstForegroundWithAlpha, Mat3b& srcImage, Mat1b& srcTrimap, int winRadius = 1, float lamda = 1000);
    static void solveAlpha(Mat1d& dstAlpha, Mat3d& srcImage, Mat1b& srcTrimap, int winRadius = 1, float lamda = 1000, double tolerance = 1.e-7, int maxIters = 1000);
    
};

#endif /* LNSPMattor_hpp */

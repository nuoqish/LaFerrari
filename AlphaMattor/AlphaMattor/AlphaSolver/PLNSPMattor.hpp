//
//  PLNSPMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/14.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef PLNSPMattor_hpp
#define PLNSPMattor_hpp

#include <stdio.h>


#include <opencv2/opencv.hpp>


using namespace std;
using namespace cv;


class PLNSPMattor {
    
public:
    
    static void solveAlpha(Mat1d& dstAlpha, Mat3d& srcImage, Mat1b& srcTrimap, int level = 4, int winRadius = 1, float lamda = 1000, double tolerance = 1.e-7, int maxIters = 1000);
    static void process(Mat1b& dstAlpha, Mat4b& dstForegroundWithAlpha, Mat3b& srcImage, Mat1b& srcTrimap, int winRadius = 1, float lamda = 1000);
    
};

#endif /* PLNSPMattor_hpp */

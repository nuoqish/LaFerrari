//
//  CFMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/16.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef CFMattor_hpp
#define CFMattor_hpp

#include <stdio.h>

#include <opencv2/opencv.hpp>


using namespace std;
using namespace cv;


class CFMattor {
    
public:
    CFMattor();
    ~CFMattor();
    void process(Mat1b& dstAlpha, Mat4b& dstForegroundWithAlpha, Mat3b& srcImage, Mat1b& srcTrimap, int winRadius = 1, float lamda = 100);
    
};

#endif /* CFMattor_hpp */

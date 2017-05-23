//
//  KNNMattor.hpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/8.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#ifndef KNNMattor_hpp
#define KNNMattor_hpp

#include <stdio.h>

#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>


//#include <boost/numeric/ublas/matrix_sparse.hpp>

using namespace std;
using namespace cv;


class KNNMattor {
    
public:
    KNNMattor();
    ~KNNMattor();
    void process(Mat3b& srcImage, Mat1b& srcTrimap, Mat1b& dstAlpha);
    
};



#endif /* KNNMattor_hpp */

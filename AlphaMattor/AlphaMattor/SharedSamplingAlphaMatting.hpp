//
//  SharedSamplingAlphaMatting.hpp
//  AlphaMatting
//

#ifndef SharedSamplingAlphaMatting_hpp
#define SharedSamplingAlphaMatting_hpp

#include <stdio.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#define DEBUG_PRINT_LOG 1

class SharedSamplingAlphaMatting {
    
public:
    SharedSamplingAlphaMatting();
    ~SharedSamplingAlphaMatting();
    
    void solveAlphaAndForeground(cv::Mat1b& dstAlpha, cv::Mat3b& dstForeground, cv::Mat4b& dstForegroundAlpha,
                                        cv::Mat3b& srcImage, cv::Mat1b& srcTrimap,
                                        unsigned int kT = 0,
                                        int kI = 10, double kC = 5.0, double kG = 4);

   
};



#endif /* SharedSamplingAlphaMatting_hpp */

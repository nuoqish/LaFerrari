//
//  main.cpp
//  AlphaMatting
//

#include <iostream>
#include <string>
#include <time.h>
#include <stdio.h>

#include "AlphaSolver.hpp"
#include "PLNSPMattor.hpp"

//#include "SharedSamplingAlphaMatting.hpp"

#include "SSMattor.hpp"

using namespace cv;
using namespace std;

int testSegment(string filename) {
    // Load the image
    Mat src = imread(filename);
    // Check if everything was fine
    if (!src.data)
        return -1;
    
    Mat gray;
    cvtColor(src, gray, COLOR_BGR2GRAY);
    Mat result;
    double thresh = 0;
    threshold(gray, result, thresh, 255, THRESH_BINARY_INV + THRESH_OTSU);
    //imshow("thresh", result);
    //cvWaitKey();
    imwrite(filename + ".thresh.png", result);
    return 0;
}

Mat3b blendColor(Mat3b& dst, Mat4b& srcA, int bkColor[3]) {
    
    dst = Mat3b(srcA.rows, srcA.cols);
    
    //Vec3b back(255,255,255);
    
    for (int i = 0; i < srcA.rows; i++) {
        for (int j = 0; j < srcA.cols; j++) {
            
            uint8_t a = srcA(i,j)[3];
            
            dst(i,j)[0] = (unsigned char)(srcA(i,j)[0] * a / 255. + bkColor[0] * (255 - a) / 255.);
            dst(i,j)[1] = (unsigned char)(srcA(i,j)[1] * a / 255. + bkColor[1] * (255 - a) / 255.);
            dst(i,j)[2] = (unsigned char)(srcA(i,j)[2] * a / 255. + bkColor[2] * (255 - a) / 255.);
            
        }
    }
    return dst;
}


int main(int argc, const char * argv[]) {
    
    
    //string dir = "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/";
    //string dir = "/Users/longyan/Desktop/";
    string dir = "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/testimages/包包/包包JPG/";
    
    string inMap = dir + "VOL3_单品_包包_39.jpeg";
    string triMap = dir + "test_000_trimap.png";
    string alphaMap = dir + "test_000-alpha-ss.png";
    string blendMap = dir + "test_000-forground-ss.png";
    
    
    Mat3b image = cv::imread(inMap,cv::IMREAD_COLOR);
    Mat1b trimap = cv::imread(triMap,cv::IMREAD_GRAYSCALE);
    Mat1b alpha;
    Mat3b foreground;
    Mat4b foregroundAlpha;
    
    //AlphaSolver::computeAlpha(alpha, image, trimap, 0, 6);
    //PLNSPMattor::process(alpha, foreground, image, trimap);
    
    
    //SharedSamplingAlphaMatting sm;sm.solveAlphaAndForeground(alpha, foreground, foregroundAlpha, image, trimap);
    
    //SSMattor::solveAlphaAndForeground(trimap, foregroundAlpha, image, trimap);
    
    testSegment(inMap);
    
    for (int i = 1; i <= 17; i++) {
        string a = to_string(10);
        string filename = "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/testimages/鞋子/鞋子JPG/VOL3_单品_鞋子_" + to_string(i / 10) + to_string(i % 10) + ".jpeg";
        
        testSegment(filename);
    }
    
    
    
    
    int bkColor[3] = {120, 30, 255};
    Mat3b blender;
    blendColor(blender, foregroundAlpha, bkColor);
    
    imwrite(alphaMap, trimap);
    imwrite(blendMap, blender);
    
    return 0;
    

}

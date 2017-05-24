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
#include "guidedfilter.h"

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



void erodeTrimapxx(cv::Mat1b &_trimap, int r)
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


Mat1b localSmooth(Mat3b& srcImage, Mat1b& srcTrimap, int radius) {
    Mat1b alpha;
    srcTrimap.copyTo(alpha);
    erodeTrimapxx(alpha, radius);
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
                alpha(i,j) = uint8_t(max(0., min(255., Wa / Wsum)));
            }
        }
    }
    
    return alpha;
}


int main(int argc, const char * argv[]) {
    
    
    //string dir = "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/";
    string dir = "/Users/stanshen/Desktop/";
    //string dir = "/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/testimages/包包/包包JPG/";
    
    string inMap = dir + "VOL3_11.jpeg";
    string triMap = dir + "VOL3_11_trimap.png";
    string alphaMap = dir + "VOL3_11_alpha-bf-4.png";
    string blendMap = dir + "VOL3_11_blend-gf-10.png";
    
    
    Mat3b image = cv::imread(inMap,cv::IMREAD_COLOR);
    Mat1b trimap = cv::imread(triMap,cv::IMREAD_GRAYSCALE);
    Mat1b alpha;
    Mat3b foreground;
    Mat4b foregroundAlpha;
    
    //AlphaSolver::computeAlpha(alpha, image, trimap, 0, 6);
    //PLNSPMattor::process(alpha, foreground, image, trimap);
    
    
    //SharedSamplingAlphaMatting sm;sm.solveAlphaAndForeground(alpha, foreground, foregroundAlpha, image, trimap);
    
    //SSMattor::solveAlphaAndForeground(alpha, foregroundAlpha, image, trimap, 10);

    
    //alpha = guidedFilter(image, trimap, 4, 1.e-6);
    
    
    alpha = localSmooth(image, trimap, 10);
    
    
    
    int bkColor[3] = {120, 30, 255};
    Mat3b blender;
    //blendColor(blender, foregroundAlpha, bkColor);
    
    imwrite(alphaMap, alpha);
    //imwrite(blendMap, blender);
    
    return 0;
    

}

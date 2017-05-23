//
//  PLNSPMattor.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/14.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "PLNSPMattor.hpp"

#include "LNSPMattor.hpp"
#include "FBSolver.hpp"


#include "../Eigen/Eigen"
using namespace Eigen;

void downSampleTrimap(Mat1b& dstTrimap, Mat1b& srcTrimap) {
    int rows = (srcTrimap.rows + 1) / 2;
    int cols = (srcTrimap.cols + 1) / 2;
    
    if (dstTrimap.rows != rows || dstTrimap.cols != cols) {
        dstTrimap = Mat1b(rows, cols);
    }
    
    for (int i = 0; i < rows - 1; i++) {
        for (int j = 0; j < cols - 1; j++) {
            dstTrimap(i, j) = srcTrimap(i * 2, j * 2);
        }
    }
    
    if (srcTrimap.rows % 2) {
        for (int j = 0; j < cols - 1; j++) {
            dstTrimap(rows - 1, j) = srcTrimap(srcTrimap.rows - 1, j * 2);
        }
    }
    if (srcTrimap.cols % 2) {
        for (int i = 0; i < rows - 1; i++) {
            dstTrimap(i, cols - 1) = srcTrimap(i * 2, srcTrimap.cols - 1);
        }
    }
    if (srcTrimap.rows % 2 && srcTrimap.cols % 2) {
        dstTrimap(rows - 1, cols - 1) = srcTrimap(srcTrimap.rows - 1, srcTrimap.cols - 1);
    }
    
}

void downSampleImage(Mat3d& dstImage, Mat3d& srcImage) {
    int rows = (srcImage.rows + 1) / 2;
    int cols = (srcImage.cols + 1) / 2;
    
    if (dstImage.rows != rows || dstImage.cols != cols) {
        dstImage = Mat3d(rows, cols);
    }
    
    Mat3f tmpImage;srcImage.copyTo(tmpImage);
    
    
    
    for (int i = 0; i < srcImage.rows; i++) {
        for (int j = 2; j < srcImage.cols - 2; j += 2) {
            tmpImage(i, j) = (srcImage(i, j - 2) + srcImage(i, j - 1) * 4 + srcImage(i, j) * 6 + srcImage(i, j + 1) * 4 + srcImage(i, j + 2)) / 16;

        }
    }
    
    for (int i = 1; i < rows - 1; i++) {
        for (int j = 0; j < cols - 1; j++) {
            int i2 = i * 2;
            int j2 = j * 2;
            
            dstImage(i, j) = (tmpImage(i2 - 2, j2) + tmpImage(i2 - 1, j2) * 4 + tmpImage(i2, j2) * 6 + tmpImage(i2 + 1, j2) * 4 + tmpImage(i2 + 2, j2)) / 16;
            
        }
    }
    for (int j = 0; j < cols - 1; j++) {
        dstImage(0, j) = srcImage(0, j * 2);
        dstImage(rows - 1, j) = srcImage(srcImage.rows - 1, j * 2);
    }
    for (int i = 0; i < rows - 1; i++) {
        dstImage(i, cols - 1) = srcImage(i * 2, srcImage.cols - 1);
    }
    
    
}

void getLinearCoeff(Mat4d& coeff, Mat1d& alpha, Mat3f image) {
    
    int rows = image.rows;
    int cols = image.cols;
    int channels = image.channels();
    int winRadius = 1;
    int nebSize = (2 * winRadius + 1) * (2 * winRadius + 1);
    double epsilon = 0.0003;
    MatrixXd G(nebSize + channels, channels + 1);
    VectorXd X(channels + 1), A(nebSize + channels);
    
    if (coeff.rows != rows || coeff.cols != cols) {
        coeff = Mat4d(rows, cols);
    }
    memset(coeff.data, 0, coeff.total() * coeff.elemSize());
    
    for (int i = 1; i < rows - 1; i++) {
        for (int j = 1; j < cols - 1; j++) {
            A[0] = alpha(i - 1, j - 1);
            A[1] = alpha(i - 1, j);
            A[2] = alpha(i - 1, j + 1);
            A[3] = alpha(i, j - 1);
            A[4] = alpha(i, j);
            A[5] = alpha(i, j + 1);
            A[6] = alpha(i + 1, j - 1);
            A[7] = alpha(i + 1, j);
            A[8] = alpha(i + 1, j + 1);
            A[9] = A[10] = A[11] = 0;
            
            if (A.sum() < 0.0001) {
                continue;
            }
            
            G.setZero();
            
            G(0, 0) = image(i - 1, j - 1)[0];
            G(0, 1) = image(i - 1, j - 1)[1];
            G(0, 2) = image(i - 1, j - 1)[2];
            G(0, 3) = 1;
            
            G(1, 0) = image(i - 1, j)[0];
            G(1, 1) = image(i - 1, j)[1];
            G(1, 2) = image(i - 1, j)[2];
            G(1, 3) = 1;
            
            G(2, 0) = image(i - 1, j + 1)[0];
            G(2, 1) = image(i - 1, j + 1)[1];
            G(2, 2) = image(i - 1, j + 1)[2];
            G(2, 3) = 1;
            
            G(3, 0) = image(i, j - 1)[0];
            G(3, 1) = image(i, j - 1)[1];
            G(3, 2) = image(i, j - 1)[2];
            G(3, 3) = 1;
            
            G(4, 0) = image(i, j)[0];
            G(4, 1) = image(i, j)[1];
            G(4, 2) = image(i, j)[2];
            G(4, 3) = 1;
            
            G(5, 0) = image(i, j + 1)[0];
            G(5, 1) = image(i, j + 1)[1];
            G(5, 2) = image(i, j + 1)[2];
            G(5, 3) = 1;
            
            G(6, 0) = image(i + 1, j - 1)[0];
            G(6, 1) = image(i + 1, j - 1)[1];
            G(6, 2) = image(i + 1, j - 1)[2];
            G(6, 3) = 1;
            
            G(7, 0) = image(i + 1, j)[0];
            G(7, 1) = image(i + 1, j)[1];
            G(7, 2) = image(i + 1, j)[2];
            G(7, 3) = 1;
            
            G(8, 0) = image(i + 1, j + 1)[0];
            G(8, 1) = image(i + 1, j + 1)[1];
            G(8, 2) = image(i + 1, j + 1)[2];
            G(8, 3) = 1;
            
            G(9, 0) = epsilon;
            G(10, 1) = epsilon;
            G(11, 2) = epsilon;
            
            X = (G.transpose() * G).inverse() * G.transpose() * A;
            
            coeff(i, j)[0] = X[0];
            coeff(i, j)[1] = X[1];
            coeff(i, j)[2] = X[2];
            coeff(i, j)[3] = X[3];
            
        }
    }
    
    for (int i = 0; i < rows; i++) {
        coeff(i, 0) = coeff(i, 1);
        coeff(i, cols - 1) = coeff(i, cols - 2);
    }
    for (int j = 0; j < cols; j++) {
        coeff(0, j) = coeff(1, j);
        coeff(rows - 1, j) = coeff(rows - 2, j);
    }
    
    
}

void getLinearCoeffUsingImageAndTrimap(Mat4d& coeff, Mat1d& alpha, Mat3d& image, Mat1b& trimap) {
    
    int rows = image.rows;
    int cols = image.cols;
    int channels = image.channels();
    int winRadius = 1;
    int nebSize = (2 * winRadius + 1) * (2 * winRadius + 1);
    double epsilon = 0.0003;
    MatrixXd G(nebSize + channels, channels + 1);
    VectorXd X(channels + 1), A(nebSize + channels);
    
    if (coeff.rows != rows || coeff.cols != cols) {
        coeff = Mat4d(rows, cols);
    }
    memset(coeff.data, 0, coeff.total() * coeff.elemSize());
    
    for (int i = 1; i < rows - 1; i++) {
        for (int j = 1; j < cols - 1; j++) {
            
            int sum = trimap(i - 1, j - 1) + trimap(i + 1, j + 1) + trimap(i - 1, j + 1) + trimap(i + 1, j - 1);
            if (sum == 0 || sum == 1020) { // 1020 == 255 * 4, all 0s or 255s
                continue;
            }
            
            A[0] = alpha(i - 1, j - 1);
            A[1] = alpha(i - 1, j);
            A[2] = alpha(i - 1, j + 1);
            A[3] = alpha(i, j - 1);
            A[4] = alpha(i, j);
            A[5] = alpha(i, j + 1);
            A[6] = alpha(i + 1, j - 1);
            A[7] = alpha(i + 1, j);
            A[8] = alpha(i + 1, j + 1);
            A[9] = A[10] = A[11] = 0;
            
            if (A.sum() < 0.0001) {
                continue;
            }
            
            G.setZero();
            
            G(0, 0) = image(i - 1, j - 1)[0];
            G(0, 1) = image(i - 1, j - 1)[1];
            G(0, 2) = image(i - 1, j - 1)[2];
            G(0, 3) = 1;
            
            G(1, 0) = image(i - 1, j)[0];
            G(1, 1) = image(i - 1, j)[1];
            G(1, 2) = image(i - 1, j)[2];
            G(1, 3) = 1;
            
            G(2, 0) = image(i - 1, j + 1)[0];
            G(2, 1) = image(i - 1, j + 1)[1];
            G(2, 2) = image(i - 1, j + 1)[2];
            G(2, 3) = 1;
            
            G(3, 0) = image(i, j - 1)[0];
            G(3, 1) = image(i, j - 1)[1];
            G(3, 2) = image(i, j - 1)[2];
            G(3, 3) = 1;
            
            G(4, 0) = image(i, j)[0];
            G(4, 1) = image(i, j)[1];
            G(4, 2) = image(i, j)[2];
            G(4, 3) = 1;
            
            G(5, 0) = image(i, j + 1)[0];
            G(5, 1) = image(i, j + 1)[1];
            G(5, 2) = image(i, j + 1)[2];
            G(5, 3) = 1;
            
            G(6, 0) = image(i + 1, j - 1)[0];
            G(6, 1) = image(i + 1, j - 1)[1];
            G(6, 2) = image(i + 1, j - 1)[2];
            G(6, 3) = 1;
            
            G(7, 0) = image(i + 1, j)[0];
            G(7, 1) = image(i + 1, j)[1];
            G(7, 2) = image(i + 1, j)[2];
            G(7, 3) = 1;
            
            G(8, 0) = image(i + 1, j + 1)[0];
            G(8, 1) = image(i + 1, j + 1)[1];
            G(8, 2) = image(i + 1, j + 1)[2];
            G(8, 3) = 1;
            
            G(9, 0) = epsilon;
            G(10, 1) = epsilon;
            G(11, 2) = epsilon;
            
            X = (G.transpose() * G).inverse() * G.transpose() * A;
            
            coeff(i, j)[0] = X[0];
            coeff(i, j)[1] = X[1];
            coeff(i, j)[2] = X[2];
            coeff(i, j)[3] = X[3];
            
        }
    }
    
    for (int i = 0; i < rows; i++) {
        coeff(i, 0) = coeff(i, 1);
        coeff(i, cols - 1) = coeff(i, cols - 2);
    }
    for (int j = 0; j < cols; j++) {
        coeff(0, j) = coeff(1, j);
        coeff(rows - 1, j) = coeff(rows - 2, j);
    }
    
    
}



void upsampleImage(Mat4d& dstImage, Mat4d& srcImage, int dstRows, int dstCols) {
    
    if (dstImage.rows != dstRows || dstImage.cols != dstCols) {
        dstImage = Mat4d(dstRows, dstCols);
    }
    memset(dstImage.data, 0, dstImage.total() * dstImage.elemSize());
    
    Mat4f tmpImage;dstImage.copyTo(tmpImage);
    
    for (int i = 0; i < dstRows; i+=2) {
        for (int j = 0; j < dstCols; j+=2) {
            int i2 = i / 2;
            int j2 = j / 2;
            tmpImage(i, j) = srcImage(i2, j2);
            tmpImage(i, j + 1) = (srcImage(i2, j2) + srcImage(i2, j2 + 1)) / 2;

        }
    }
    
    for (int i = 1; i < dstRows - 1; i ++) {
        for (int j = 0; j < dstCols; j++) {
            dstImage(i, j) = (tmpImage(i - 1, j) + tmpImage(i, j) * 2 + tmpImage(i + 1, j)) / 2;
        }
    }
    for (int j = 0; j < dstCols; j++) {
        dstImage(0, j) = (tmpImage(0, j) * 2 + tmpImage(1, j)) / 2;
        dstImage(dstRows - 1, j) = (tmpImage(dstRows - 1, j) * 2 + tmpImage(dstRows - 2, j)) / 2;
    }
    
}


void upsampleCoeffUsingTrimap(Mat4d& dstImage, Mat4d& srcImage, int dstRows, int dstCols, Mat1b& refTrimap) {
    
    if (dstImage.rows != dstRows || dstImage.cols != dstCols) {
        dstImage = Mat4d(dstRows, dstCols);
    }
    memset(dstImage.data, 0, dstImage.total() * dstImage.elemSize());
    
    Mat4f tmpImage;dstImage.copyTo(tmpImage);
    
    for (int i = 0; i < dstRows; i+=2) {
        for (int j = 0; j < dstCols; j+=2) {
            int i2 = i / 2;
            int j2 = j / 2;
            tmpImage(i, j) = srcImage(i2, j2);
            tmpImage(i, j + 1) = (srcImage(i2, j2) + srcImage(i2, j2 + 1)) / 2;
            
        }
    }
    
    for (int i = 1; i < dstRows - 1; i ++) {
        for (int j = 0; j < dstCols; j++) {
            uint8_t triValue = refTrimap(i,j);
            if (triValue != 0 && triValue != 255) {
                dstImage(i, j) = (tmpImage(i - 1, j) + tmpImage(i, j) * 2 + tmpImage(i + 1, j)) / 2;
            }
        }
    }
    for (int j = 0; j < dstCols; j++) {
        dstImage(0, j) = (tmpImage(0, j) * 2 + tmpImage(1, j)) / 2;
        dstImage(dstRows - 1, j) = (tmpImage(dstRows - 1, j) * 2 + tmpImage(dstRows - 2, j)) / 2;
    }
    
}


void upsampleAlphaUsingImage(Mat1d& dstAlpha,  Mat3d& refImage, Mat1d& srcAlpha, Mat3d& srcImage) {
    
    int rows = refImage.rows;
    int cols = refImage.cols;
    
    if (dstAlpha.rows != rows || dstAlpha.cols != cols) {
        dstAlpha = Mat1d(rows, cols);
    }
    
    
    Mat4d coeff;
    getLinearCoeff(coeff, srcAlpha, srcImage);
    
    Mat4d bcoeff;
    upsampleImage(bcoeff, coeff, rows, cols);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            double alpha = bcoeff(i, j)[3] +
                             bcoeff(i, j)[0] * refImage(i, j)[0] +
                             bcoeff(i, j)[1] * refImage(i, j)[1] +
                             bcoeff(i, j)[2] * refImage(i, j)[2];
            
            if (alpha > 1.0) {
                alpha = 1.0;
            }
            else if (alpha < 0.0) {
                alpha = 0.;
            }
            dstAlpha(i, j) = alpha;
            
        }
    }
    
}


void upsampleAlphaUsingImageAndTrimap(Mat1d& dstAlpha,  Mat3d& refImage, Mat1b& refTrimap, Mat1d& srcAlpha, Mat3d& srcImage, Mat1b& srcTrimap) {
    
    int rows = refImage.rows;
    int cols = refImage.cols;
    
    if (dstAlpha.rows != rows || dstAlpha.cols != cols) {
        dstAlpha = Mat1d(rows, cols);
    }
    
    
    Mat4d coeff;
    //getLinearCoeff(coeff, srcAlpha, srcImage);
    getLinearCoeffUsingImageAndTrimap(coeff, srcAlpha, srcImage, srcTrimap);
    
    Mat4d bcoeff;
    //upsampleImage(bcoeff, coeff, rows, cols);
    upsampleCoeffUsingTrimap(bcoeff, coeff, rows, cols, refTrimap);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            uint8_t triValue = refTrimap(i,j);
            if (triValue == 0) {
                dstAlpha(i, j) = 0;
            }
            else if (triValue == 255) {
                dstAlpha(i, j) = 1;
            }
            else {
                double alpha = bcoeff(i, j)[3] +
                bcoeff(i, j)[0] * refImage(i, j)[0] +
                bcoeff(i, j)[1] * refImage(i, j)[1] +
                bcoeff(i, j)[2] * refImage(i, j)[2];
                
                if (alpha > 1.0) {
                    alpha = 1.0;
                }
                else if (alpha < 0.0) {
                    alpha = 0.;
                }
                dstAlpha(i, j) = alpha;
            }
            
        }
    }
    
}

void PLNSPMattor::solveAlpha(Mat1d &dstAlpha, Mat3d &srcImage, Mat1b &srcTrimap, int level, int winRadius, float lamda, double tolerance, int maxIters) {
    
    
    if (level > 1) {
        Mat3d image;
        Mat1b trimap;
        Mat1d alpha;
        downSampleImage(image, srcImage);
        downSampleTrimap(trimap, srcTrimap);
        solveAlpha(alpha, image, trimap, level - 1, winRadius, lamda);
        //upsampleAlphaUsingImage(dstAlpha, srcImage, alpha, image);
        upsampleAlphaUsingImageAndTrimap(dstAlpha, srcImage, srcTrimap, alpha, image, trimap);
    }
    else {
        LNSPMattor::solveAlpha(dstAlpha, srcImage, srcTrimap, winRadius, lamda, tolerance, maxIters);
    }
    
    
    
}

void PLNSPMattor::process(Mat1b &dstAlpha, Mat4b &dstForegroundWithAlpha, Mat3b &srcImage, Mat1b &srcTrimap, int winRadius, float lamda) {
    
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    
    Mat3d image(rows, cols);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            image(i, j)[0] = srcImage(i, j)[0] / 255.;
            image(i, j)[1] = srcImage(i, j)[1] / 255.;
            image(i, j)[2] = srcImage(i, j)[2] / 255.;
        }
    }
    
    
    clock_t tic = clock();
    Mat1d alpha;
    solveAlpha(alpha, image, srcTrimap, 1, winRadius, lamda);
    printf("process time cost time: %.3f ms\n", 1000. *(clock() - tic) / CLOCKS_PER_SEC);
    
    if (dstAlpha.rows != rows || dstAlpha.cols != cols) {
        dstAlpha = Mat1b(rows, cols);
    }
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            dstAlpha(i, j) = uint8_t(min(255., max(0., alpha(i, j) * 255.)));
        }
    }
    
    FBSolver::computeForeground(dstForegroundWithAlpha, srcImage, dstAlpha);
    
    
}

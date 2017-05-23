//
//  FBSolver.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/3/14.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "FBSolver.hpp"



#include "../Eigen/Eigen"
using namespace Eigen;

typedef Triplet<double> T;


void FBSolver::computeForeground(Mat4b& dstForegroundAlpha, Mat4b& srcImage, Mat1b& srcAlpha) {
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    
    Mat3d image(rows, cols);
    Mat1d alpha(rows, cols);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            image(i, j)[0] = srcImage(i, j)[0] / 255.;
            image(i, j)[1] = srcImage(i, j)[1] / 255.;
            image(i, j)[2] = srcImage(i, j)[2] / 255.;
            alpha(i, j) = srcAlpha(i, j) / 255.;
        }
    }
    computeForeground(dstForegroundAlpha, image, alpha);
}

void FBSolver::computeForeground(Mat4b& dstForegroundAlpha, Mat3b& srcImage, Mat1b& srcAlpha) {
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    
    Mat3d image(rows, cols);
    Mat1d alpha(rows, cols);
    
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            image(i, j)[0] = srcImage(i, j)[0] / 255.;
            image(i, j)[1] = srcImage(i, j)[1] / 255.;
            image(i, j)[2] = srcImage(i, j)[2] / 255.;
            alpha(i, j) = srcAlpha(i, j) / 255.;
        }
    }
    computeForeground(dstForegroundAlpha, image, alpha);
}


void FBSolver::computeForeground(Mat4b &dstForegroundAlpha, Mat3d &srcImage, Mat1d &srcAlpha, double tolerance, int maxIters) {
    
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    int totalNum = rows * cols;
    
    if (dstForegroundAlpha.rows != rows || dstForegroundAlpha.cols != cols) {
        dstForegroundAlpha = Mat4b(rows, cols);
    }
    
    vector<Point> uT;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            double alpha = srcAlpha(i, j);
            if (alpha > 0.001 && alpha < 0.999) {
                uT.push_back(Point(i, j));
            }
            dstForegroundAlpha(i, j)[3] = uint8_t(min(255., max(0., alpha * 255.)));
        }
    }
    
    printf("solveForeground: bulid matrix R...\n");
    vector<T> triplets;
    for (int i = 0; i < totalNum; i++) {
        double alpha = srcAlpha(i / cols, i % cols);
        triplets.push_back(T(i, i, alpha));
        triplets.push_back(T(i, i + totalNum, 1 - alpha));
    }
    SparseMatrix<double> R(totalNum, totalNum * 2);
    R.setFromTriplets(triplets.begin(), triplets.end());
    triplets.clear();
    printf("solveForeground: bulid matrix Ldx...\n");
    double lamda = 0.01;
    for (int i = 0; i < uT.size(); i++) {
        
        if ((uT[i].x + 1) < rows) {
            int k = uT[i].x * cols + uT[i].y;
            triplets.push_back(T(k, k, -lamda));
            triplets.push_back(T(k, k + cols, lamda));
            triplets.push_back(T(k + totalNum, k + totalNum, -lamda));
            triplets.push_back(T(k + totalNum, k + totalNum + cols, lamda));
            
        }
    }
    SparseMatrix<double> Ldx(totalNum * 2, totalNum * 2);
    Ldx.setFromTriplets(triplets.begin(), triplets.end());
    triplets.clear();
    printf("solveForeground: bulid matrix Ldy...\n");
    for (int i = 0; i < uT.size(); i++) {
        if ((uT[i].y + 1) < cols) {
            int k = uT[i].x * cols + uT[i].y;
            triplets.push_back(T(k, k, -lamda));
            triplets.push_back(T(k, k + 1, lamda));
            triplets.push_back(T(k + totalNum, k + totalNum, -lamda));
            triplets.push_back(T(k + totalNum, k + totalNum + 1, lamda));
        }
        
    }
    SparseMatrix<double> Ldy(totalNum * 2, totalNum * 2);
    Ldy.setFromTriplets(triplets.begin(), triplets.end());
    triplets.clear();
    printf("solveForeground: bulid matrix Adx, Ady...\n");
    VectorXd Adx(totalNum * 2), Ady(totalNum * 2);
    Adx.setZero();
    Ady.setZero();
    for (int m = 0; m < uT.size(); m++) {
        int i = uT[m].x;
        int j = uT[m].y;
        int k = i * cols + j;
        if ((i+1) < rows) {
            double dx = (srcAlpha(i + 1, j) - srcAlpha(i, j)) * lamda;
            Adx[k] = dx;
            Adx[k + totalNum] = -dx;
        }
        if ((j+1) < cols) {
            double dy = (srcAlpha(i, j + 1) - srcAlpha(i, j)) * lamda;
            Ady[k] = dy;
            Ady[k + totalNum] = -dy;
        }
        
    }
    
    
    SparseMatrix<double> Rtrans = R.transpose();
    SparseMatrix<double> lhs = Rtrans * R + SparseMatrix<double>(Ldx.transpose()) * Ldx + SparseMatrix<double>(Ldy.transpose()) * Ldy;
    VectorXd LAdx = SparseMatrix<double>(Ldx.transpose()) * Adx + SparseMatrix<double>(Ldy.transpose()) * Ady;
    
    for (int c = 0; c < 3; c++) {

        clock_t tic = clock();
        
        VectorXd chan(totalNum);
        for (int i = 0, idx = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                chan[idx++] = srcImage(i,j)[c];
            }
        }
        
        VectorXd rhs = Rtrans * chan + LAdx;
        VectorXd f(totalNum * 2);
        ConjugateGradient<SparseMatrix<double>, Lower|Upper> cg;
        cg.setTolerance(tolerance);
        cg.setMaxIterations(maxIters);
        cg.compute(lhs);
        f = cg.solve(rhs);
        
        printf("solveForeground: sovle F [%d] cost time: %.f ms, iters = %d, error = %.10f\n", c, 1000.f * (clock() - tic) / CLOCKS_PER_SEC, (int)cg.iterations(), cg.error());
        
        
        for (int i = 0, index = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                dstForegroundAlpha(i, j)[c] = uint8_t(min(255., max(0., f[index++] * dstForegroundAlpha(i, j)[3])));
            }
        }
                
    }
    
    
    
}


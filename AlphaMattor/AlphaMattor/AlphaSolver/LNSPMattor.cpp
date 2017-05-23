//
//  LNSPMattor.cpp
//  AlphaMattor
//
//  Created by longyan on 2017/2/21.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#include "LNSPMattor.hpp"

#include "FBSolver.hpp"

#include "../Eigen/Eigen"
using namespace Eigen;

typedef Triplet<double> T; 


float featureDistanceL1(float featureA[5], float featureB[5]) {
    float sum = (abs(featureA[0] - featureB[0]) +
                 abs(featureA[1] - featureB[1]) +
                 abs(featureA[2] - featureB[2]) +
                 abs(featureA[3] - featureB[3]) / 100. +
                 abs(featureA[4] - featureB[4]) / 100.) / 5.f;
    
    return max(1 - sum, 0.f);
}



void solveForegroundWithAlpha(Mat4b& dstForegroundAlpha, Mat1b& dstAlpha, Mat3d& srcImage, VectorXd& x, vector<Point>& uT, double lamda = 0.01) {
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    int totalNum = rows * cols;
    
    if (dstAlpha.rows == 0 || dstAlpha.cols == 0) {
        dstAlpha = Mat1b(rows, cols);
    }
    if (dstForegroundAlpha.rows == 0 || dstForegroundAlpha.cols == 0) {
        dstForegroundAlpha = Mat4b(rows, cols);
    }
    
    for (int i = 0; i < totalNum; i++) {
        uint8_t alpha = uint8_t(min(255., max(0., x[i] * 255.)));
        dstAlpha(i / cols, i % cols) = alpha;
        dstForegroundAlpha(i / cols, i % cols)[3] = alpha;
    }
    
    printf("solveForeground: bulid matrix R...\n");
    vector<T> triplets;
    for (int i = 0; i < totalNum; i++) {
        triplets.push_back(T(i, i, x[i]));
        triplets.push_back(T(i, i + totalNum, 1 - x[i]));
    }
    SparseMatrix<double> R(totalNum, totalNum * 2);
    R.setFromTriplets(triplets.begin(), triplets.end());
    triplets.clear();
    printf("solveForeground: bulid matrix Ldx...\n");
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
            double dx = (x[k + cols] - x[k]) * lamda;
            Adx[k] = dx;
            Adx[k + totalNum] = -dx;
        }
        if ((j+1) < cols) {
            double dy = (x[k + 1] - x[k]) * lamda;
            Ady[k] = dy;
            Ady[k + totalNum] = -dy;
        }
        
    }
    
    
    for (int c = 0; c < 3; c++) {
        
        
        clock_t tic = clock();
        
        VectorXd chan(totalNum);
        for (int i = 0, idx = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                chan[idx++] = srcImage(i,j)[c];
            }
        }
        SparseMatrix<double> lhs = SparseMatrix<double>(R.transpose()) * R +
        SparseMatrix<double>(Ldx.transpose()) * Ldx +
        SparseMatrix<double>(Ldy.transpose()) * Ldy;
        VectorXd rhs = SparseMatrix<double>(R.transpose()) * chan +
        SparseMatrix<double>(Ldx.transpose()) * Adx +
        SparseMatrix<double>(Ldy.transpose()) * Ady;
        VectorXd f(totalNum * 2);
        ConjugateGradient<SparseMatrix<double>, Lower|Upper> cg;
        cg.setTolerance(1.e-7);
        cg.setMaxIterations(500);
        cg.compute(lhs);
        f = cg.solve(rhs);
        
        
        
        printf("solveForeground: sovle F [%d] cost time: %.f ms, iters = %d, error = %.10f\n", c, 1000.f * (clock() - tic) / CLOCKS_PER_SEC, (int)cg.iterations(), cg.error());
        
        
        for (int i = 0; i < totalNum; i++) {
            dstForegroundAlpha(i / cols, i % cols)[c] = uint8_t(min(255., max(0., f[i] * x[i] * 255)));
        }
        
    }
    
    
    
}


void buildDataSmoothTriplets(vector<T>& dataTriplets, double *D, Mat3f& image, Mat1b& srcTrimap, double gamma = 0.1) {
    int rows = image.rows;
    int cols = image.cols;
    int totalNum = rows * cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            int t = srcTrimap(i, j);
            if (t == 0 || t == 255) {
                double gammaAlpha = (t == 0 ? 0 : gamma);
                dataTriplets.push_back(T(i * cols + j, totalNum, gammaAlpha));
                dataTriplets.push_back(T(i * cols + j, totalNum + 1, gamma - gammaAlpha));
            }
            else {
                
                
                
                
            }
        }
    }
}

void buildLocalMattingTriplets(vector<T>& localTriplets, double *D, Mat3d& image, vector<Point>& uT, int winRadius = 1, double epsilon = 1.e-7) {
    
    int rows = image.rows;
    int cols = image.cols;
    vector<int> indices;
    indices.resize((2 * winRadius + 1) * (2 * winRadius + 1));
    
    Matrix3d varI;
    double meanI[3], meanI2[6];
    for (int m = 0; m < uT.size(); m++) {
        
        int x = uT[m].x;
        int y = uT[m].y;
        int x_min = max(0, x - winRadius);
        int x_max = min(rows - 1, x + winRadius);
        int y_min = max(0, y - winRadius);
        int y_max = min(cols - 1, y + winRadius);
        int num_neigh = (x_max - x_min + 1) * (y_max - y_min + 1);
        
        memset(meanI, 0, 3 * sizeof(double));
        memset(meanI2, 0, 6 * sizeof(double));
        
        MatrixXd winI(num_neigh,3);
        
        for (int i = x_min, idx = 0; i <= x_max; i++) {
            for (int j = y_min; j <= y_max; j++) {
                double r = image(i, j)[0];
                double g = image(i, j)[1];
                double b = image(i, j)[2];
                
                meanI[0] += r; meanI[1] += g; meanI[2] += b;
                meanI2[0] += r * r; meanI2[1] += r * g; meanI2[2] += r * b;
                meanI2[3] += g * g; meanI2[4] += g * b; meanI2[5] += b * b;
                winI(idx, 0) = r; winI(idx, 1) = g; winI(idx, 2) = b;
                indices[idx] = i * cols + j;
                idx++;
            }
        }
        meanI[0] /= num_neigh; meanI[1] /= num_neigh; meanI[2] /= num_neigh;
        meanI2[0] /= num_neigh; meanI2[1] /= num_neigh; meanI2[2] /= num_neigh;
        meanI2[3] /= num_neigh; meanI2[4] /= num_neigh; meanI2[5] /= num_neigh;
        
        varI(0, 0) = meanI2[0] - meanI[0] * meanI[0] + epsilon / num_neigh;
        varI(0, 1) = meanI2[1] - meanI[0] * meanI[1];
        varI(0, 2) = meanI2[2] - meanI[0] * meanI[2];
        varI(1, 0) = varI(0, 1);
        varI(1, 1) = meanI2[3] - meanI[1] * meanI[1] + epsilon / num_neigh;
        varI(1, 2) = meanI2[4] - meanI[1] * meanI[2];
        varI(2, 0) = varI(0, 2);
        varI(2, 1) = varI(1, 2);
        varI(2, 2) = meanI2[5] - meanI[2] * meanI[2] * epsilon /num_neigh;
        
        for (int i = 0; i < num_neigh; i++) {
            winI(i, 0) -= meanI[0];
            winI(i, 1) -= meanI[1];
            winI(i, 2) -= meanI[2];
        }
        
        MatrixXd varI_inv = varI.inverse();
        MatrixXd winI_t = winI.transpose();
        MatrixXd lapValue = winI * varI_inv * winI_t;
        
        for (int i = 0; i < num_neigh; i++) {
            for (int j = i; j < num_neigh; j++) {
                double val = (1. + lapValue(i, j)) / num_neigh;
                localTriplets.push_back(T(indices[i], indices[j], -val));
                localTriplets.push_back(T(indices[j], indices[i], -val));
                D[indices[i]] += val;
                D[indices[j]] += val;
                
            }
        }
        
    }
    
}

void buildKNNTriplets(vector<T>& nonlocalTriplets, double *D, Mat1f& featureMat, int totalNum, const int K) {
    flann::KDTreeIndexParams indexParams;
    flann::Index kdIndex(featureMat, indexParams, cvflann::FLANN_DIST_L2);
    vector<int> idx;
    vector<float> dists;
    for (int i = 0; i < totalNum; i++) {
        kdIndex.knnSearch(featureMat.row(i), idx, dists, K);
        for (int k = 1; k < K; k++) {
            int kn = idx[k];
            double dist = featureDistanceL1((float *)featureMat.row(i).data, (float *)featureMat.row(kn).data);
            if (dist != 0) {
                nonlocalTriplets.push_back(T(i, kn, -dist));
                nonlocalTriplets.push_back(T(kn, i, -dist));
                D[i] += dist;
                D[kn] += dist;
            }
            
        }
    }
}

void buildNonlocalMattingTriplets(vector<T>& nonlocalTriplets, Mat3d& image, double *D, int K = 10, int K2 = 0) {
    
    int rows = image.rows;
    int cols = image.cols;
    int totalNum = rows * cols;
    float dist = sqrt(rows * rows + cols * cols);
    
    Mat1f featureMat(totalNum, 5);
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            int index = i * cols + j;
            featureMat(index, 0) = image(i, j)[0];
            featureMat(index, 1) = image(i, j)[1];
            featureMat(index, 2) = image(i, j)[2];
            featureMat(index, 3) = i / dist;
            featureMat(index, 4) = j / dist;
        }
    }
    
    buildKNNTriplets(nonlocalTriplets, D, featureMat, totalNum, K);
    

    if (K2 > 0) {
        for (int i = 0; i < totalNum; i++) {
            featureMat(i, 3) /= 100.;
            featureMat(i, 4) /= 100.;
        }
        
        buildKNNTriplets(nonlocalTriplets, D, featureMat, totalNum, K2);
        
    }
    
}


void LNSPMattor::process(Mat1b &dstAlpha, Mat4b &dstForegroundWithAlpha, Mat3b &srcImage, Mat1b &srcTrimap, int winRadius, float lamda) {
    
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
    
    Mat1d alpha;
    solveAlpha(alpha, image, srcTrimap);
    
    if (dstAlpha.rows != rows || dstAlpha.cols != cols) {
        dstAlpha = Mat1b(rows, cols);
    }
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            dstAlpha(i, j) = uint8_t(max(0., min(255., alpha(i, j) * 255)));
        }
    }
    
    FBSolver::computeForeground(dstForegroundWithAlpha, image, alpha, 1.e-7, 500);
    
    
}

void LNSPMattor::solveAlpha(Mat1d &dstAlpha, Mat3d &srcImage, Mat1b &srcTrimap, int winRadius, float lamda, double tolerance, int maxIters) {
    
    int rows = srcImage.rows;
    int cols = srcImage.cols;
    int totalNum = srcImage.rows * srcImage.cols;
    
    const int K = 10, K2 = 2;
    
    vector<Point> uT;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (srcTrimap(i, j) != 0 && srcTrimap(i, j) != 255) {
                uT.push_back(Point(i, j));
            }
        }
    }
    
    vector<T> triplets;
    double *D = (double *)malloc(totalNum * sizeof(double));
    memset(D, 0, totalNum * sizeof(double));
    
    
    buildNonlocalMattingTriplets(triplets, srcImage, D, K, K2);
    buildLocalMattingTriplets(triplets, D, srcImage, uT);
    
    SparseMatrix<double> L(totalNum, totalNum);
    L.setFromTriplets(triplets.begin(), triplets.end());
    triplets.clear();
    
    
    VectorXd b(totalNum), x(totalNum);
    for (int i = 0; i < totalNum; i++) {
        int t = srcTrimap(i / cols, i % cols);
        triplets.push_back(T(i, i, D[i] + ((t == 0 || t == 255) ? lamda : 0.)));
        b[i] = (t == 255 ? lamda : 0);
    }
    
    SparseMatrix<double> Diag(totalNum, totalNum);
    Diag.setFromTriplets(triplets.begin(), triplets.end());
    
    L += Diag;
    
    
    printf("CG Solving  ...");
    clock_t tic = clock();
    ConjugateGradient<SparseMatrix<double>, Lower|Upper> cg;
    cg.setTolerance(tolerance);
    cg.setMaxIterations(maxIters);
    cg.compute(L);
    x = cg.solve(b);
    printf("CG solver cost time: %f ms, iters: %d, error: %.10f \n", 1000. * (clock() - tic) / CLOCKS_PER_SEC, (int)cg.iterations(), cg.error());
    
    if (dstAlpha.rows != rows || dstAlpha.cols != cols) {
        dstAlpha = Mat1d(rows, cols);
    }
    for (int i = 0; i < totalNum; i++) {
        dstAlpha(i / cols, i % cols) = min(1.0, max(0.,x[i]));
    }
    
}

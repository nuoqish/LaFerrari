//
//  SharedSamplingAlphaMatting.cpp
//  AlphaMatting
//

#include "SharedSamplingAlphaMatting.hpp"
#include "guidedfilter.h"
#include "slic.h"

using namespace cv;
using namespace std;

bool debug = false;

void erodeFB(cv::Mat1b &_trimap, int r)
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

inline double _calcAlpha(double c_b[3], double f_b[3]) {
    double alpha = (c_b[0] * f_b[0] + c_b[1] * f_b[1] + c_b[2] * f_b[2]) / (f_b[0] * f_b[0] + f_b[1] * f_b[1] + f_b[2] * f_b[2]);
    return min(1.0, max(0.0, alpha));
}
inline double _calcAlpha(int c_b[3], int f_b[3]) {
    double alpha = (c_b[0] * f_b[0] + c_b[1] * f_b[1] + c_b[2] * f_b[2]) / double(f_b[0] * f_b[0] + f_b[1] * f_b[1] + f_b[2] * f_b[2]);
    return min(1.0, max(0.0, alpha));
}

inline double calcAlpha(double c[3], double f[3], double b[3]) {
    double c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    return _calcAlpha(c_b, f_b);
}

inline double calcAlpha(uint8_t c[3], double f[3], double b[3]) {
    double c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    return _calcAlpha(c_b, f_b);
}

double calcAlpha2(uint8_t c[3], uint8_t f[3], uint8_t b[3]) {
    int c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    double alpha = (c_b[0] * f_b[0] + c_b[1] * f_b[1] + c_b[2] * f_b[2]) / double(f_b[0] * f_b[0] + f_b[1] * f_b[1] + f_b[2] * f_b[2]);
    return alpha;
}

inline double calcAlpha(uint8_t c[3], uint8_t f[3], uint8_t b[3]) {
    int c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    return _calcAlpha(c_b, f_b);
}


inline double mP(double c[3], double f[3], double b[3]) {
    double c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    double alpha = _calcAlpha(c_b, f_b);
    
    double delta0 = c_b[0] - f_b[0] * alpha;
    double delta1 = c_b[1] - f_b[1] * alpha;
    double delta2 = c_b[2] - f_b[2] * alpha;
    double result = sqrt(delta0 * delta0 + delta1 * delta1 + delta2 * delta2);
    return result / 255.0;
}

inline double mP(uint8_t c[3], double f[3], double b[3]) {
    double cf[3];
    cf[0] = c[0];cf[1] = c[1];cf[2] = c[2];
    return mP(cf, f, b);
}



inline double mP(uint8_t c[3], uint8_t f[3], uint8_t b[3]) {
    int c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];
    c_b[1] = c[1] - b[1];
    c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];
    f_b[1] = f[1] - b[1];
    f_b[2] = f[2] - b[2];
    double alpha = _calcAlpha(c_b, f_b);
    
    double delta0 = c_b[0] - f_b[0] * alpha;
    double delta1 = c_b[1] - f_b[1] * alpha;
    double delta2 = c_b[2] - f_b[2] * alpha;
    double result = sqrt(delta0 * delta0 + delta1 * delta1 + delta2 * delta2);
    return result / 255.0;
}

double nP(const Mat3b& image, int i, int j, uint8_t f[3], uint8_t b[3]) {
    int width = image.cols;
    int height = image.rows;
    uint8_t *imageData = image.data;
    size_t imageStride = image.step1();
    int i1 = max(0, i - 1);
    int i2 = min(height - 1, i + 1);
    int j1 = max(0, j - 1);
    int j2 = min(width - 1, j + 1);
    uint8_t c[3];
    double result = 0;
    for (int k = i1; k <= i2; k++) {
        for (int l = j1; l <= j2; l++) {
            
            //c[0] = image(k,l)[0];c[1] = image(k,l)[1];c[2] = image(k,l)[2];
            memcpy(c, imageData + k * imageStride + l * 3, 3);
            double mp = mP(c, f, b);
            result += mp * mp;
        }
    }
    
    return result;
}

double nP(uint8_t *rgbData, size_t stride, Point cp, Point left_top, Point right_bottom, uint8_t f[3], uint8_t b[3]) {
    
    uint8_t c[3];
    double result = 0;
    for (int k = left_top.x; k <= right_bottom.x; k++) {
        for (int l = left_top.y; l <= right_bottom.y; l++) {
            
            //c[0] = image(k,l)[0];c[1] = image(k,l)[1];c[2] = image(k,l)[2];
            memcpy(c, rgbData + k * stride + l * 3, 3);
            double mp = mP(c, f, b);
            result += mp * mp;
        }
    }
    
    return result;
    
    
}

double eP(const Mat3b& image, int i1, int j1, int i2, int j2) { // eq. 4 Image space statistics
    
    int width = image.cols;
    int height = image.rows;
    uint8_t *imageData = image.data;
    size_t imageStride = image.step1();
    
    double ci = i2 - i1;
    double cj = j2 - j1;
    double z = sqrt(ci * ci + cj * cj) + 1.e-10;
    double ei = ci / z;
    double ej = cj / z;
    double stepinc = min(1 / (abs(ei) + 1.e-10), 1 / (abs(ej) + 1.e-10));
    double result = 0;
    int ti = i1;
    int tj = j1;
    size_t offset;
    offset = i1 * imageStride + j1 * 3;
    int bpre = imageData[offset + 0];
    int gpre = imageData[offset + 1];
    int rpre = imageData[offset + 2];
    for (double t = 1; ; t += stepinc) {
        int i = int(i1 + ei * t + 0.5);
        int j = int(j1 + ej * t + 0.5);
        if (i < 0 || i >= height || j < 0 || j >= width) {
            break;
        }
        
        double delta = 1;
        if (ti > i && tj == j) {
            delta = ej;
        }
        else if (ti == i && tj > j) {
            delta = ei;
        }
        
        offset = i * imageStride + j * 3;
        int b = imageData[offset + 0];//image(i,j)[0];
        int g = imageData[offset + 1];//image(i,j)[1];
        int r = imageData[offset + 2];//image(i,j)[2];
        result += ((b - bpre) * (b - bpre) + (g - gpre) * (g - gpre) + (r - rpre) * (r - rpre)) * delta;
        
        bpre = b;
        gpre = g;
        rpre = r;
        ti = i;
        tj = j;
    }
    
    return result;
}


double pfP(const Mat3b& image, Point p, Point *F, Point *B, int countF, int countB) {
    double fmin = 1.e10;
    for (int i = 0; i < countF; i++) {
        double fp = eP(image, p.x, p.y, F[i].x, F[i].y);
        if (fp < fmin) {
            fmin = fp;
        }
    }
    
    double bmin = 1.e10;
    for (int i = 0; i < countB; i++) {
        double bp = eP(image, p.x, p.y, B[i].x, B[i].y);
        if (bp < bmin) {
            bmin = bp;
        }
    }
    
    return bmin / (fmin + bmin + 1.e-10);
}

double aP(uint8_t *rgbData, size_t stride, Point p, double pf, uint8_t f[3], uint8_t b[3]) {
    uint8_t c[3];
    memcpy(c, rgbData + p.x * stride + p.y * 3, 3);
    double alpha = calcAlpha(c, f, b);
    return pf + (1. - 2 * pf) * alpha;
}

double gP(const Mat3b& image, Point p, Point fp, Point bp, double dpf, double pf) { // eq. 7
    
    uint8_t f[3], b[3];
    memcpy(f, image.data + fp.x * image.step1() + fp.y * 3, 3);
    memcpy(b, image.data + bp.x * image.step1() + bp.y * 3, 3);
    
    
    //double np = pow(nP(image, p.x, p.y, f, b),3);
    double np = pow(nP(image.data, image.step1(), p, Point(max(0, p.x - 1), max(0, p.y - 1)), Point(min(image.rows - 1, p.x + 1), min(image.cols - 1, p.y + 1)), f, b), 3);
    double ap = pow(aP(image.data, image.step1(), p, pf, f, b), 2);
    
    double tf = dpf;//dP(p, fp);//sqrt((p.x - fp.x) * (p.x - fp.x) + (p.y - fp.y) * (p.y - fp.y));
    double dpb = (p.x - bp.x) * (p.x - bp.x) + (p.y - bp.y) * (p.y - bp.y);
    double tb = dpb * dpb;//sqrt((p.x - bp.x) * (p.x - bp.x) + (p.y - bp.y) * (p.y - bp.y));
    
    return np * ap * tf * tb;
}

inline int distanceColor2(uint8_t c1[3], uint8_t c2[3]) {
    int delta0 = c1[0] - c2[0];
    int delta1 = c1[1] - c2[1];
    int delta2 = c1[2] - c2[2];
    int result = delta0 * delta0 + delta1 * delta1 + delta2 * delta2;
    return result;
}

double distanceColor2(double c1[3], double c2[3]) {
    double delta0 = c1[0] - c2[0];
    double delta1 = c1[1] - c2[1];
    double delta2 = c1[2] - c2[2];
    double result = delta0 * delta0 + delta1 * delta1 + delta2 * delta2;
    return result;
}

double distanceColor2(uint8_t c1[3], double c2[3]) {
    double delta0 = c1[0] - c2[0];
    double delta1 = c1[1] - c2[1];
    double delta2 = c1[2] - c2[2];
    double result = delta0 * delta0 + delta1 * delta1 + delta2 * delta2;
    return result;
}

double sigma2(const Mat3b& image, Point p) {
    int width = image.cols;
    int height = image.rows;
    int i1 = max(0, p.x - 2);
    int i2 = min(height - 1, p.x + 2);
    int j1 = max(0, p.y - 2);
    int j2 = min(width - 1, p.y + 2);
    
    double result = 0;
    int num = (i2 - i1 + 1) * (j2 - j1 + 1);
    
    uint8_t pc[3], qc[3];
    //pc[0] = image(p.x, p.y)[0];pc[1] = image(p.x, p.y)[1];pc[2] = image(p.x, p.y)[2];
    memcpy(pc, image.data + p.x * image.step1() + p.y * 3, 3);
    for (int k = i1; k <= i2; k++) {
        for (int l = j1; l <= j2; l++) {
            
            //qc[0] = image(k,l)[0];qc[1] = image(k,l)[1];qc[2] = image(k,l)[2];
            memcpy(qc, image.data + k * image.step1() + l * 3, 3);
            result += distanceColor2(pc, qc);
        }
    }
    
    return result / (num + 1e-10);
}

bool comparePixel(const Mat3b& image, int x1, int y1, int x2, int y2, const int kI, const double kC2) {
    double pd = sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    if (pd > kI) {
        return false;
    }
    
    const Vec3b& p = image(x1,y1);
    const Vec3b& q = image(x2,y2);
    int dB = p[0] - q[0];
    int dG = p[1] - q[1];
    int dR = p[2] - q[2];
    double cd = dB * dB + dG * dG + dR * dR;
    
    return cd <= kC2;
}

Point findPixel(const Mat3b& image, const Mat1b& trimap, int i, int j, int k, int kI, double kC2) {
    
    int k1 = max(0, i - k);
    int k2 = min(i + k, trimap.rows - 1);
    int l1 = max(0, j - k);
    int l2 = min(j + k, trimap.cols - 1);
    
    uint8_t value;
    for (int l = k1; l <= k2; l++) {
        
        value = trimap(l,l1);
        if (value == 0 || value == 255) {
            if (comparePixel(image, i, j, l, l1, kI, kC2)) {
                return Point(l,l1);
            }
        }
        
        value = trimap(l,l2);
        if (value == 0 || value == 255) {
            if (comparePixel(image, i, j, l, l2, kI, kC2)) {
                return Point(l,l2);
            }
        }
    }
    
    for (int l = l1; l <= l2; l++) {
        
        value = trimap(k1,l);
        if (value == 0 || value == 255) {
            if (comparePixel(image, i, j, k1, l, kI, kC2)) {
                return Point(k1,l);
            }
        }
        
        value = trimap(k2,l);
        if (value == 0 || value == 255) {
            if (comparePixel(image, i, j, k2, l, kI, kC2)) {
                return Point(k2,l);
            }
        }
    }

    return Point(i,j);
}



struct Tuple
{
    uint8_t fc[3];
    uint8_t bc[3];
    double   sigmaf;
    double   sigmab;
    double alpha;
    int flag;
    Point fp;
    double confidence;
    
};

void _findForegroundAndBackgroundCandidates(Point *F, Point *B, int &countF, int &countB, const Mat1b& srcTrimap, Point p, int kG) {
    
    bool flagF, flagB;
    double incAngle = 360. / kG;
    double initAngle = (p.x % 3 * 3 + p.y % 9) * incAngle / 9;
    double angle, ei, ej, step;
    int ti, tj;
    int width = srcTrimap.cols;
    int height = srcTrimap.rows;
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();
    countF = countB = 0;
    for (int k = 0; k < kG; k++) {
        
        flagF = false;
        flagB = false;
        angle = (initAngle + k * incAngle) / 180.f * 3.1415926f;
        
        ei = sin(angle);
        ej = cos(angle);
        step = min(1.0 / (abs(ei) + 1e-10), 1.0 / (abs(ej) + 1e-10));
        
        for (double t = 1; ; t += step) {
            ti = int(p.x + ei * t + 0.5);
            tj = int(p.y + ej * t + 0.5);
            if (ti < 0 || ti >= height || tj < 0 || tj >= width) {
                break;
            }
            
            uint8_t gray = srcTrimapData[ti * srcTrimapStride + tj];//srcTrimap(ti, tj);
            if (!flagB && gray == 0) {
                flagB = true;
                B[countB].x = ti;
                B[countB].y = tj;
                countB++;
            }
            else if (!flagF && gray == 255) {
                flagF = true;
                F[countF].x = ti;
                F[countF].y = tj;
                countF++;
            }
            else if (flagF && flagB) {
                break;
            }
            
        }
        
    }
    
    
}


double _ncc(const Mat3b& image, Point p, Point q) {
    
    int w = 1;
    int weight[] = {1,2,1,2,4,2,1,2,1};
    int weight_sum = 16;
    double result = 0;
    int count = 0;
    for (int i = -w; i <= w; i++) {
        for (int j = -w; j <= w; j++) {
            int px = p.x + i;
            int py = p.y + j;
            int qx = q.x + i;
            int qy = q.y + j;
            if (px >= 0 && px < image.rows && py >= 0 && py < image.cols &&
                qx >= 0 && qx < image.rows && qy >= 0 && qy < image.cols) {
                result += distanceColor2(image.data + px * image.step1() + py * 3, image.data + qx * image.step1() + qy * 3) * weight[(w + i) * 3 + (w + j)];
                count += weight_sum;
            }
        }
    }
    
    return result / (count + 1e-20);
}

double _distanceColor(const Mat3b& image, Point p, uint8_t qc[3]) {
    
    int w = 2;
   
    double result = 0;
    int count = 0;
    for (int i = -w; i <= w; i++) {
        for (int j = -w; j <= w; j++) {
            int px = p.x + i;
            int py = p.y + j;
            if (px >= 0 && px < image.rows && py >= 0 && py < image.cols) {
                result += distanceColor2(image.data + px * image.step1() + py * 3, qc);
                count++;
            }
        }
    }
    
    return result / (count + 1e-20);
}

double _gP(const Mat3b& image, Point p, Point fp, uint8_t bc[3]) { // eq. 7
    
    uint8_t f[3], I[3];
    memcpy(f, image.data + fp.x * image.step1() + fp.y * 3, 3);
    memcpy(I, image.data + p.x * image.step1() + p.y * 3, 3);
    //double cf = _ncc(image, p, fp);
    double cf = distanceColor2(I, f);
    return cf;
}

double _calcAlphaBlock(const Mat3b image, Point cp, Point fp, uint8_t bc[3]) {
    
    double I_B = _distanceColor(image, cp, bc);
    double F_B = _distanceColor(image, fp, bc);
    
    double result = I_B / (F_B + 1.e-20);
    
    return min(1.0, max(0., result));
}


bool _sampleBestBackgroundColor(uint8_t bestBc[3], const Mat3b& srcImage, const Mat1b& srcTrimap, Point cp, const int kG = 4) {
    
    double incAngle = 360. / kG;
    double initAngle = (cp.x % 3 * 3 + cp.y % 9) * incAngle / 9;
    double angle, ei, ej, step;
    int width = srcTrimap.cols;
    int height = srcTrimap.rows;
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();
    uint8_t *srcImageData = srcImage.data;
    size_t srcImageStride = srcImage.step1();
    
    bool flag = false;
    Point *B = (Point *)malloc(kG * sizeof(Point));
    int cntB = 0;
    int avgBc[3] = {0, 0, 0};
    for (int k = 0; k < kG; k++) {
        angle = (initAngle + k * incAngle) / 180.f * 3.1415926f;
        ei = sin(angle);ej = cos(angle);
        step = min(1.0 / (abs(ei) + 1e-10), 1.0 / (abs(ej) + 1e-10));
        
        for (double t = 1; ; t += step) {
            int ti = int(cp.x + ei * t + 0.5);
            int tj = int(cp.y + ej * t + 0.5);
            if (ti < 0 || ti >= height || tj < 0 || tj >= width) {
                break;
            }
            uint8_t gray = srcTrimapData[ti * srcTrimapStride + tj];//srcTrimap(ti, tj);
            if (gray == 0) {
                B[cntB].x = ti;
                B[cntB].y = tj;
                avgBc[0] += srcImageData[ti * srcImageStride + tj * 3 + 0];
                avgBc[1] += srcImageData[ti * srcImageStride + tj * 3 + 1];
                avgBc[2] += srcImageData[ti * srcImageStride + tj * 3 + 2];
                cntB++;
                flag = true;
                break;
            }
        }
    }
    
    memset(bestBc, 0, 3);
    if (cntB > 0) {
        bestBc[0] = uint8_t(avgBc[0] / cntB);
        bestBc[1] = uint8_t(avgBc[1] / cntB);
        bestBc[2] = uint8_t(avgBc[2] / cntB);
    }
    
    return flag;
}

double _sampleBestForegroundColor(uint8_t bestFc[3], uint8_t bestBc[3], const Mat3b& srcImage, const Mat1b& srcTrimap, SLIC& slic, Point cp, const int kG = 4) {
    
    double incAngle = 360. / kG;
    double initAngle = (cp.x % 3 * 3 + cp.y % 9) * incAngle / 9;
    double angle, ei, ej, step;
    int width = srcTrimap.cols;
    int height = srcTrimap.rows;
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();
    uint8_t *srcImageData = srcImage.data;
    size_t srcImageStride = srcImage.step1();
    bool flag = false;
    Point bestFp;
    int* spLabels = slic.GetLabel();
    
    double minCost = DBL_MAX;
    for (int k = 0; k < kG; k++) {
        angle = (initAngle + k * incAngle) / 180.f * 3.1415926f;
        ei = sin(angle);ej = cos(angle);
        step = min(1.0 / (abs(ei) + 1e-10), 1.0 / (abs(ej) + 1e-10));
        int spIndex = -1;
        for (double t = 1; ; t += step) {
            int ti = int(cp.x + ei * t + 0.5);
            int tj = int(cp.y + ej * t + 0.5);
            if (ti < 0 || ti >= height || tj < 0 || tj >= width) {
                break;
            }
            
            if (spIndex != -1 && spIndex != spLabels[ti * width + tj]) {
                break;
            }
            
            uint8_t gray = srcTrimapData[ti * srcTrimapStride + tj];//srcTrimap(ti, tj);
            if (gray == 255) {
                if (spIndex == -1) {
                    spIndex = spLabels[ti * width + tj];
                }
                
                //double cost = _ncc(srcImage, cp, Point(ti, tj));//_gP(srcImage, cp, Point(ti, tj), bestBc);
                double cost = _gP(srcImage, cp, Point(ti, tj), bestBc);
                // double cost = distanceColor2(srcImageData + cp.x * srcImageStride + cp.y * 3, srcImageData + ti * srcImageStride + tj * 3);
                if (cost < minCost) {
                    flag = true;
                    minCost = cost;
                    bestFp.x = ti;
                    bestFp.y = tj;
                }
                
            }
            
            
        }
        
    }
    
    memcpy(bestFc, srcImageData + bestFp.x * srcImageStride + bestFp.y * 3, 3);
    
    return minCost;
}


Point _sampleBestForegroundCandidate(uint8_t bestBc[3], const Mat3b& srcImage, const Mat1b& srcTrimap, SLIC& slic, Point cp, const int kG = 4) {
    
    double incAngle = 360. / kG;
    double initAngle = (cp.x % 3 * 3 + cp.y % 9) * incAngle / 9;
    double angle, ei, ej, step;
    int width = srcTrimap.cols;
    int height = srcTrimap.rows;
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();

    Point bestFp = cp;
    int* spLabels = slic.GetLabel();
    
    double minCost = DBL_MAX;
    for (int k = 0; k < kG; k++) {
        angle = (initAngle + k * incAngle) / 180.f * 3.1415926f;
        ei = sin(angle);ej = cos(angle);
        step = min(1.0 / (abs(ei) + 1e-10), 1.0 / (abs(ej) + 1e-10));
        int spIndex = -1;
        for (double t = 1; ; t += step) {
            int ti = int(cp.x + ei * t + 0.5);
            int tj = int(cp.y + ej * t + 0.5);
            if (ti < 0 || ti >= height || tj < 0 || tj >= width) {
                break;
            }
            
            if (spIndex != -1 && spIndex != spLabels[ti * width + tj]) {
                break;
            }
            
            
            uint8_t gray = srcTrimapData[ti * srcTrimapStride + tj];//srcTrimap(ti, tj);
            if (gray == 255) {
                if (spIndex == -1) {
                    spIndex = spLabels[ti * width + tj];
                }
                
                
                //double cost = _ncc(srcImage, cp, Point(ti, tj));//_gP(srcImage, cp, Point(ti, tj), bestBc);
                double cost = _gP(srcImage, cp, Point(ti, tj), bestBc);
                 //double cost = distanceColor2(srcImageData + cp.x * srcImageStride + cp.y * 3, srcImageData + ti * srcImageStride + tj * 3);
                if (cost < minCost) {
                    minCost = cost;
                    bestFp.x = ti;
                    bestFp.y = tj;
                    
                }
                
            }
            
            
        }
        
    }
    
    return bestFp;
    
}



void _expansionOfKnownRegions(Mat1b& dstTrimap, vector<Point>& uT, const Mat1b& srcTrimap, const Mat3b& srcImage, const int kT = 0, const int kI = 10, const double kC = 4.0)
{
    int width = srcTrimap.cols;
    int height = srcTrimap.rows;
    double kC2 = kC * kC;
    
    Mat1b trimap(srcTrimap);
    erodeFB(trimap, kT);
    
    trimap.copyTo(dstTrimap);
    
    uT.clear();
    
    
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
 
            if (trimap(i,j) != 0 && trimap(i,j) != 255) { // 当前是非确定像素
                bool flag = false;
                for (int k = 0; k <= kI; k++) { // 半径kI范围内寻找与p(i,j)足够相似的确定点
                    Point q = findPixel(srcImage, trimap, i, j, k, kI, kC2);
                    if (q.x != i || q.y != j) { // 找到足够相似确定点
                        dstTrimap(i,j) = trimap(q.x,q.y);
                        flag = true;
                        break;
                    }
                }
                if (!flag) { // 没找到足够相似确定点
                    uT.push_back(Point(i,j));
                }
            }
        }
    }
    
    
}


void _sampleAndGatherFB(vector<struct Tuple>& tuples, Mat1i& unknownIndex,
                        vector<Point>& uT,
                        Mat3b& srcImage, Mat1b& srcTrimap,
                        const int kG = 4) {
    

    
    
    tuples.clear();
    unknownIndex = Mat1i(srcTrimap.rows, srcTrimap.cols);
    SLIC slic;
    slic.GenerateSuperpixels(srcImage, srcImage.rows * srcImage.cols / 900);
    
    for (int m = 0, index = 0; m < uT.size(); m++) {
        
        int i = uT[m].x;
        int j = uT[m].y;
        
        double sigmaI = sigma2(srcImage, uT[m]);
        
        struct Tuple st;
        st.flag = -1;
        
        uint8_t fc[3], bc[3];
        
        bool flagB = _sampleBestBackgroundColor(bc, srcImage, srcTrimap, uT[m], kG);
        Point bestFp = _sampleBestForegroundCandidate(bc, srcImage, srcTrimap, slic, uT[m], kG);
        
        
        if (flagB && !(bestFp.x == i && bestFp.y == j)) {
            st.flag = 1;
            st.fp = bestFp;
            memcpy(fc, srcImage.data + bestFp.x * srcImage.step1() + bestFp.y * 3, 3);// fc, bc, I
            st.alpha = calcAlpha(srcImage.data + i * srcImage.step1() + j * 3, fc, bc);
            //st.alpha = _calcAlphaBlock(srcImage, uT[m], bestFp, bc);
            memcpy(st.fc, fc, 3);
            memcpy(st.bc, bc, 3);
            double sigmaF = sigma2(srcImage, bestFp);
            
            
        }
        else {
            printf("sampleFB error: (%d, %d)", i, j);
        }
        
        tuples.push_back(st);
        unknownIndex(i,j) = index++;
        
        
    }
    
}


struct Ftuple
{
    double fc[3];
    double bc[3];
    double   alphar;
    double   confidence;
    double fbdist;
    uint8_t fc0[3];
};


void _refineSample(vector<struct Ftuple>& ftuples,
                   const Mat3b& srcImage, const Mat1b& srcTrimap,
                   vector<Point> &uT, vector<struct Tuple>& tuples, Mat1i& unknownIndex,
                   const int radius = 5)
{
    
    Mat3b dstForeground, dstForegroundRefined;
    Mat1b alpha, alphaRefined;
    srcImage.copyTo(dstForeground);
    srcImage.copyTo(dstForegroundRefined);
    srcTrimap.copyTo(alpha);
    srcTrimap.copyTo(alphaRefined);
    
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();
    uint8_t *dstForegroundData = dstForeground.data;
    size_t dstForegroundStride = dstForeground.step1();
    uint8_t *dstForegroundRefinedData = dstForegroundRefined.data;
    uint8_t *srcImageData = srcImage.data;
    size_t srcImageStride = srcImage.step1();
    
    for (int i = 0; i < srcTrimap.rows; i++) {
        for (int j = 0; j < srcTrimap.cols; j++) {
            
            if (srcTrimapData[i * srcTrimapStride + j] == 0) {
                memset(dstForegroundRefinedData + i * dstForegroundStride + j * 3, 0, 3);
                memset(dstForegroundData + i * dstForegroundStride + j * 3, 0, 3);
            }
            else if (srcTrimapData[i * srcTrimapStride + j] == 255) {
                
                memcpy(dstForegroundData + i * dstForegroundStride + j * 3, srcImageData + i * srcImageStride + j * 3, 3);
                memcpy(dstForegroundRefinedData + i * dstForegroundStride + j * 3, srcImageData + i * srcImageStride + j * 3, 3);
            }
            
        }
    }
    
    ftuples.resize(tuples.size());
    int width = srcImage.cols;
    int height = srcImage.rows;
   
    double minvalue[5];
    int minIndices[5], num;
    uint8_t pc[3];
    for (vector<Point>::iterator iter = uT.begin(); iter != uT.end(); iter++) {
        
        int xi = iter->x;
        int yi = iter->y;
        
        int i1 = max(0, xi - radius);
        int i2 = min(height - 1, xi + radius);
        int j1 = max(0, yi - radius);
        int j2 = min(width - 1, yi + radius);
        
        //pc[0] = srcImage(xi,yi)[0];pc[1] = srcImage(xi,yi)[1];pc[2] = srcImage(xi,yi)[2];
        memcpy(pc, srcImageData + xi * srcImageStride + yi * 3, 3);
        
        num = 0;
        minvalue[0] = minvalue[1] = minvalue[2] = minvalue[3] = minvalue[4] = 1e10;
        
        
        for (int k = i1; k <= i2; k++) {
            for (int l = j1; l <= j2; l++) {
                
                uint8_t value = srcTrimap(k,l);
                if (value == 0 || value == 255) {
                    continue;
                }
                
                Tuple st = tuples[unknownIndex(k,l)];
                if (st.flag == -1) {
                    continue;
                }
                
                double m = distanceColor2(pc, srcImageData + k * srcImageStride + l * 3);
                
                if (m > minvalue[4]) {
                    continue;
                }
                else if (m < minvalue[0]) {
                    minvalue[4] = minvalue[3];
                    minvalue[3] = minvalue[2];
                    minvalue[2] = minvalue[1];
                    minvalue[1] = minvalue[0];
                    minvalue[0] = m;
                    minIndices[4] = minIndices[3];
                    minIndices[3] = minIndices[2];
                    minIndices[2] = minIndices[1];
                    minIndices[1] = minIndices[0];
                    minIndices[0] = k * width + l;
                    num++;
                }
                else if (m < minvalue[1]) {
                    minvalue[4] = minvalue[3];
                    minvalue[3] = minvalue[2];
                    minvalue[2] = minvalue[1];
                    minvalue[1] = m;
                    minIndices[4] = minIndices[3];
                    minIndices[3] = minIndices[2];
                    minIndices[2] = minIndices[1];
                    minIndices[1] = k * width + l;
                    num++;
                }
                else if (m < minvalue[2]) {
                    minvalue[4] = minvalue[3];
                    minvalue[3] = minvalue[2];
                    minvalue[2] = m;
                    minIndices[4] = minIndices[3];
                    minIndices[3] = minIndices[2];
                    minIndices[2] = k * width + l;
                    num++;
                }
                else if (m < minvalue[3]) {
                    minvalue[4] = minvalue[3];
                    minvalue[3] = m;
                    minIndices[4] = minIndices[3];
                    minIndices[3] = k * width + l;
                    num++;
                }
                else {
                    minvalue[4] = m;
                    minIndices[4] = k * width + l;
                    num++;
                }
                
            }
        }
        
        
        if (num < 5) {
            printf("refineSample: (%d,%d) num = %d\t", xi, yi, num);
        }
        
        num = min(num, 5);
        
        double fc[3], bc[3], sf(0), sb(0);
        fc[0] = fc[1] = fc[2] = bc[0] = bc[1] = bc[2] = 0;
        
        
        for (int k = 0; k < num; k++) {
            
            Tuple tuple  = tuples[unknownIndex(minIndices[k] / width, minIndices[k] % width)];
            fc[0] += tuple.fc[0];
            fc[1] += tuple.fc[1];
            fc[2] += tuple.fc[2];
            bc[0] += tuple.bc[0];
            bc[1] += tuple.bc[1];
            bc[2] += tuple.bc[2];
            sf += tuple.sigmaf;
            sb += tuple.sigmab;
            
            
            
        }
        
        
        double sum = (num == 0 ? 1e-10 : num);
        
        fc[0] /= sum;
        fc[1] /= sum;
        fc[2] /= sum;
        bc[0] /= sum;
        bc[1] /= sum;
        bc[2] /= sum;
        sf /= sum;
        sb /= sum;
        
        double df = distanceColor2(pc, fc);
        double db = distanceColor2(pc, bc);
        double tf[3],tb[3];
        tf[0] = fc[0];tf[1] = fc[1];tf[2] = fc[2];
        tb[0] = bc[0];tb[1] = bc[1];tb[2] = bc[2];
        
        //        if (df <= sf) {
        //            fc[0] = pc[0];fc[1] = pc[1];fc[2] = pc[2];
        //        }
        //        if (db <= sb) {
        //            bc[0] = pc[0];bc[1] = pc[1];bc[2] = pc[2];
        //        }
        
        int index = unknownIndex(xi, yi);
        if (fc[0] == bc[0] && fc[1] == bc[1] && fc[2] == bc[2]) {
            ftuples[index].confidence = 1.e-8;
        }
        else {
            ftuples[index].confidence = exp(-10 * mP(pc, tf, tb));
        }
        
        ftuples[index].fc[0] = fc[0];
        ftuples[index].fc[1] = fc[1];
        ftuples[index].fc[2] = fc[2];
        ftuples[index].bc[0] = bc[0];
        ftuples[index].bc[1] = bc[1];
        ftuples[index].bc[2] = bc[2];
        ftuples[index].alphar = calcAlpha(pc, fc, bc);
        ftuples[index].fbdist = sqrt(distanceColor2(fc, bc));
        
        ftuples[index].fc0[0] = tuples[index].fc[0];
        ftuples[index].fc0[1] = tuples[index].fc[1];
        ftuples[index].fc0[2] = tuples[index].fc[2];
        
        
        memcpy(dstForeground.data + xi * dstForeground.step1() + yi * 3, tuples[index].fc, 3);
        
        dstForegroundRefined(xi, yi)[0] = (uint8_t)fc[0];
        dstForegroundRefined(xi, yi)[1] = (uint8_t)fc[1];
        dstForegroundRefined(xi, yi)[2] = (uint8_t)fc[2];
        
        alpha(xi, yi) = (uint8_t)(tuples[index].alpha * 255);
        alphaRefined(xi, yi) = (uint8_t)(ftuples[index].alphar * 255);
        
        
    }
    
}

void _localSmooth(Mat1b& dstAlpha, Mat3b& dstForeground, Mat4b& dstForegroundAlpha, const Mat3b& srcImage, const Mat1b& srcTrimap, vector<Point>& uT, vector<struct Ftuple>& ftuples, Mat1i& unknownIndex, double m = 100.0)
{
    srcTrimap.copyTo(dstAlpha);
    uint8_t *dstAlphaData = dstAlpha.data;
    size_t dstAlphaStride = dstAlpha.step1();
    
    int width = srcImage.cols;
    int height = srcImage.rows;
    uint8_t *srcImageData = srcImage.data;
    size_t srcImageStride = srcImage.step1();
    
    dstForegroundAlpha = Mat4b(height, width);
    uint8_t *dstForegroundAlphaData = dstForegroundAlpha.data;
    size_t dstForegroundAlphaStride = dstForegroundAlpha.step1();
    
    dstForeground = Mat3b(height, width);
    uint8_t *dstForegroundData = dstForeground.data;
    size_t dstForegroundStride = dstForeground.step1();
    
    
    uint8_t *srcTrimapData = srcTrimap.data;
    size_t srcTrimapStride = srcTrimap.step1();
    
    size_t offset;
    
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            
            if (srcTrimapData[i * srcTrimapStride + j] == 0) {
                memset(dstForegroundAlphaData + i * dstForegroundAlphaStride + j * 4, 0, 4);
                memset(dstForegroundData + i * dstForegroundStride + j * 3, 0, 3);
            }
            else if (srcTrimapData[i * srcTrimapStride + j] == 255) {
                offset = i * dstForegroundAlphaStride + j * 4;
                memcpy(dstForegroundAlphaData + offset, srcImageData + i * srcImageStride + j * 3, 3);
                dstForegroundAlphaData[offset + 3] = 255;
                memcpy(dstForegroundData + i * dstForegroundStride + j * 3, srcImageData + i * srcImageStride + j * 3, 3);
                
            }
            
        }
    }
    
    double thresh = 9.;
    double sig2 = m / (thresh * 3.1415926);
    double r = 3 * sqrt(sig2);
    
    for (vector<Point>::iterator iter = uT.begin(); iter != uT.end(); iter++) {
        int xi = iter->x;
        int yi = iter->y;
        
        int i1 = max(0, int(xi - r));
        int i2 = min(height - 1, int(xi + r));
        int j1 = max(0, int(yi - r));
        int j2 = min(width - 1, int (yi + r));
        
        Ftuple ptuple = ftuples[unknownIndex(xi,yi)];
        
        double wcfsumup[3], wcbsumup[3], wcfsumdown, wcbsumdown, wfbsumup, wfbsumdown, wasumup, wasumdown;
        wcfsumup[0] = wcfsumup[1] = wcfsumup[2] = 0;
        wcbsumup[0] = wcbsumup[1] = wcbsumup[2] = 0;
        wcfsumdown = wcbsumdown = wfbsumdown = wfbsumup = wasumdown = wasumup = 0;
        
        for (int k = i1; k <= i2; k++) {
            for (int l = j1; l <= j2; l++) {
                
                double d2_sig2 = ((xi - k) * (xi - k) + (yi - l) * (yi - l)) / sig2;
                if (d2_sig2 > thresh) {
                    continue;
                }
                double exp_d2_sig2 = exp(-d2_sig2);
                // double exp_c2_sig2 = exp(-distanceColor2(srcImageData + k * srcImageStride + l * 3, srcImageData + xi * srcImageStride + yi * 3)/ sig2);
                
                if (srcTrimapData[k * srcTrimapStride + l] == 0) {
                    double wc = exp_d2_sig2 * ptuple.alphar;
                    wcbsumdown += wc;
                    //wcbsumup[0] += wc * srcImage(k, l)[0];
                    //wcbsumup[1] += wc * srcImage(k, l)[1];
                    //wcbsumup[2] += wc * srcImage(k, l)[2];
                    offset = k * srcImageStride + l * 3;
                    wcbsumup[0] += wc * srcImageData[offset + 0];
                    wcbsumup[1] += wc * srcImageData[offset + 1];
                    wcbsumup[2] += wc * srcImageData[offset + 2];
                    wasumdown += exp_d2_sig2 + 1;
                    
                }
                else if (srcTrimapData[k * srcTrimapStride + l] == 255) {
                    double wc = exp_d2_sig2 * abs(1.0 - ptuple.alphar);
                    wcfsumdown += wc;
                    //wcfsumup[0] += wc * srcImage(k, l)[0];
                    //wcfsumup[1] += wc * srcImage(k, l)[1];
                    //wcfsumup[2] += wc * srcImage(k, l)[2];
                    offset = k * srcImageStride + l * 3;
                    wcfsumup[0] += wc * srcImageData[offset + 0];
                    wcfsumup[1] += wc * srcImageData[offset + 1];
                    wcfsumup[2] += wc * srcImageData[offset + 2];
                    
                    double wa = exp_d2_sig2 + 1;
                    wasumup += wa;
                    wasumdown += wa;
                }
                else {
                    
                    Ftuple qtuple = ftuples[unknownIndex(k,l)];
                    
                    double wc, wc_a;
                    if (d2_sig2 == 0) {
                        
                        wc = qtuple.confidence;
                    }
                    else {
                        wc = exp_d2_sig2 * qtuple.confidence * abs(qtuple.alphar - ptuple.alphar);
                        //wc = exp_d2_sig2 * qtuple.confidence * exp_c2_sig2;
                    }
                    wc_a = wc * qtuple.alphar;
                    wcfsumdown += wc_a;//wc * qtuple.alphar;
                    wcfsumup[0] += wc_a * qtuple.fc[0];//wc * qtuple.alphar * qtuple.fc[0];
                    wcfsumup[1] += wc_a * qtuple.fc[1];//wc * qtuple.alphar * qtuple.fc[1];
                    wcfsumup[2] += wc_a * qtuple.fc[2];//wc * qtuple.alphar * qtuple.fc[2];
                    wc_a = wc - wc_a;
                    wcbsumdown += wc_a;//wc * (1 - qtuple.alphar);
                    wcbsumup[0] += wc_a * qtuple.bc[0];//wc * (1 - qtuple.alphar) * qtuple.bc[0];
                    wcbsumup[1] += wc_a * qtuple.bc[1];//wc * (1 - qtuple.alphar) * qtuple.bc[1];
                    wcbsumup[2] += wc_a * qtuple.bc[2];//wc * (1 - qtuple.alphar) * qtuple.bc[2];
                    
                    double wfb = qtuple.confidence * qtuple.alphar * (1 - qtuple.alphar); // eq. 16
                    wfbsumup += wfb * qtuple.fbdist; // eq. 17
                    wfbsumdown += wfb; // eq.17
                    
                    double wa = qtuple.confidence * exp_d2_sig2; // eq. 19
                    wasumup += wa * qtuple.alphar; // eq. 20
                    wasumdown += wa; // eq. 20
                }
                
            }
        }
        
        wcfsumdown += 1e-200;
        wcbsumdown += 1e-200;
        wfbsumdown += 1e-200;
        wasumdown  += 1e-200;
        
        double cp[3], fp[3], bp[3];
        //cp[0] = srcImage(xi,yi)[0];
        //cp[1] = srcImage(xi,yi)[1];
        //cp[2] = srcImage(xi,yi)[2];
        offset = xi * srcImageStride + yi * 3;
        cp[0] = srcImageData[offset + 0];
        cp[1] = srcImageData[offset + 1];
        cp[2] = srcImageData[offset + 2];
        
        fp[0] = wcfsumup[0] / wcfsumdown;// fp[0] = min(255., max(0., wcfsumup[0] / (wcfsumdown + 1e-200)));
        fp[1] = wcfsumup[1] / wcfsumdown;// fp[1] = min(255., max(0., wcfsumup[1] / (wcfsumdown + 1e-200)));
        fp[2] = wcfsumup[2] / wcfsumdown;// fp[2] = min(255., max(0., wcfsumup[2] / (wcfsumdown + 1e-200)));
        bp[0] = wcbsumup[0] / wcbsumdown;// bp[0] = min(255., max(0., wcbsumup[0] / (wcbsumdown + 1e-200)));
        bp[1] = wcbsumup[1] / wcbsumdown;// bp[1] = min(255., max(0., wcbsumup[1] / (wcbsumdown + 1e-200)));
        bp[2] = wcbsumup[2] / wcbsumdown;// bp[2] = min(255., max(0., wcbsumup[2] / (wcbsumdown + 1e-200)));
        
        uint8_t a;
        if ((fp[0] == 0 && fp[1] == 0 && fp[2] == 0)) {
            a = 0;
        }
        else if ((bp[0] == 0 && bp[1] == 0 && bp[2] == 0)) {
            a = 255;
        }
        else {
            double dfb = wfbsumup / wfbsumdown;
            double conp = min(1., sqrt(distanceColor2(fp, bp)) / dfb) * exp(-10 * mP(cp, fp, bp));
            double alp = wasumup / wasumdown;
            double alpha_t = conp * calcAlpha(cp, fp, bp) + (1 - conp) * alp; // eq. 21
            a = (uint8_t)(alpha_t * 255);
        }
        
        
        dstAlphaData[xi * dstAlphaStride + yi] = a;
        offset = xi * dstForegroundAlphaStride + yi * 4;
        
        dstForegroundAlphaData[offset + 0] = (uint8_t)ptuple.fc[0];
        dstForegroundAlphaData[offset + 1] = (uint8_t)ptuple.fc[1];
        dstForegroundAlphaData[offset + 2] = (uint8_t)ptuple.fc[2];
        dstForegroundAlphaData[offset + 3] = (uint8_t)(ptuple.alphar * 255);
        
        dstForegroundData[xi * dstForegroundStride + yi * 3 + 0] = (uint8_t)fp[0];
        dstForegroundData[xi * dstForegroundStride + yi * 3 + 1] = (uint8_t)fp[1];
        dstForegroundData[xi * dstForegroundStride + yi * 3 + 2] = (uint8_t)fp[2];
    }
    
    //imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/16212-foreground-smooth.png", dstForeground);
    //imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/16212-foreground-alpha-smooth.png", dstForegroundAlpha);
    
}


SharedSamplingAlphaMatting::SharedSamplingAlphaMatting() {
    
}

SharedSamplingAlphaMatting::~SharedSamplingAlphaMatting() {
    
}

void SharedSamplingAlphaMatting::solveAlphaAndForeground(Mat1b& dstAlpha, Mat3b& dstForeground, Mat4b& dstForegroundAlpha,
                                                         Mat3b& srcImage, Mat1b& srcTrimap,
                                                         unsigned int kT,
                                                         int kI, double kC, double kG)
{
    
    printf("开始处理...\n");
    
    
    clock_t tic0 = clock();
    
    Mat1b trimap;
    vector<Point> uT;

    Mat1i unknownIndex;

    vector<struct Tuple> tuples;
    vector<struct Ftuple> ftuples;
    
    clock_t tic = clock();
    _expansionOfKnownRegions(trimap, uT, srcTrimap, srcImage, kT, kI, kC);
    clock_t toc = clock();
    imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/16212-trimap-expand-ss.png", trimap);
#if DEBUG_PRINT_LOG
    printf("expansionOfKnownRegions cost: %f ms\n", double(toc - tic) * 1000./ CLOCKS_PER_SEC);
#endif
    tic = clock();
    _sampleAndGatherFB(tuples, unknownIndex, uT, srcImage, trimap, kG);
    toc = clock();
#if DEBUG_PRINT_LOG
    printf("sampleAndGatherFB cost: %f ms\n", double(toc - tic) * 1000. / CLOCKS_PER_SEC);
#endif

    tic = clock();
    _refineSample(ftuples, srcImage, trimap, uT, tuples, unknownIndex);
    toc = clock();
#if DEBUG_PRINT_LOG
    printf("refineSample cost: %f ms\n", double(toc - tic) * 1000. / CLOCKS_PER_SEC);
#endif

    tic = clock();
    _localSmooth(dstAlpha, dstForeground, dstForegroundAlpha, srcImage, trimap, uT, ftuples, unknownIndex);
    toc = clock();
#if DEBUG_PRINT_LOG
    printf("localSmooth cost: %f ms\n", double(toc - tic) * 1000. / CLOCKS_PER_SEC);
#endif

    toc = clock();
    printf("处理完成，耗时：%.3f ms\n", double(toc - tic0) * 1000. / CLOCKS_PER_SEC);
    
    
//    tic = clock();
//    dstForeground = guidedFilter(srcImage, dstForeground, 10, 1e-5);
//    toc = clock();
//    printf("guideFilter cost: %f ms\n", double(toc - tic) * 1000. / CLOCKS_PER_SEC);
    
    
}



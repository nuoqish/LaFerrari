#include "globalmatting.h"

template <typename T>
static inline T sqr(T a)
{
    return a * a;
}

static std::vector<cv::Point> findBoundaryPixels(const cv::Mat_<uchar> &trimap, int a, int b)
{
    std::vector<cv::Point> result;

    for (int x = 1; x < trimap.cols - 1; ++x)
        for (int y = 1; y < trimap.rows - 1; ++y)
        {
            if (trimap(y, x) == a)
            {
                if (trimap(y - 1, x) == b ||
                    trimap(y + 1, x) == b ||
                    trimap(y, x - 1) == b ||
                    trimap(y, x + 1) == b)
                {
                    result.push_back(cv::Point(x, y));
                }
            }
        }

    return result;
}

// Eq. 2
static float calculateAlpha(const cv::Vec3b &F, const cv::Vec3b &B, const cv::Vec3b &I)
{
    float result = 0;
    float div = 1e-6f;
    for (int c = 0; c < 3; ++c)
    {
        float f = F[c];
        float b = B[c];
        float i = I[c];

        result += (i - b) * (f - b);
        div += (f - b) * (f - b);
    }

    return std::min(std::max(result / div, 0.f), 1.f);
}

// Eq. 3
static float colorCost(const cv::Vec3b &F, const cv::Vec3b &B, const cv::Vec3b &I, float alpha)
{
    float result = 0;
    for (int c = 0; c < 3; ++c)
    {
        float f = F[c];
        float b = B[c];
        float i = I[c];

        result += sqr(i - (alpha * f + (1 - alpha) * b));
    }

    return sqrt(result);
}

float _calcAlpha2(cv::Vec3b c, cv::Vec3b f, cv::Vec3b b) {
    
    float c_b[3], f_b[3];
    c_b[0] = c[0] - b[0];c_b[1] = c[1] - b[1];c_b[2] = c[2] - b[2];
    f_b[0] = f[0] - b[0];f_b[1] = f[1] - b[1];f_b[2] = f[2] - b[2];
    float alpha = (c_b[0] * f_b[0] + c_b[1] * f_b[1] + c_b[2] * f_b[2]) / (f_b[0] * f_b[0] + f_b[1] * f_b[1] + f_b[2] * f_b[2]);
    return alpha;
}

float _calcDeltaAlpha2(cv::Mat3b& srcImage, cv::Point cp, cv::Point fp, cv::Point bp, const int kR = 1) {
    
    cv::Vec3b bc = srcImage(bp.x, bp.y);
    float alpha00 = _calcAlpha2(srcImage(cp.x - 1, cp.y - 1), srcImage(fp.x - 1, fp.y - 1), bc);
    float alpha01 = _calcAlpha2(srcImage(cp.x - 1, cp.y), srcImage(fp.x - 1, fp.y), bc);
    float alpha02 = _calcAlpha2(srcImage(cp.x - 1, cp.y + 1), srcImage(fp.x - 1, fp.y + 1), bc);
    float alpha10 = _calcAlpha2(srcImage(cp.x, cp.y - 1), srcImage(fp.x, fp.y - 1), bc);
    //float alpha11 = _calcAlpha(srcImage(cp.x, cp.y), srcImage(fp.x, fp.y), srcImage(bp.x, bp.y));
    float alpha12 = _calcAlpha2(srcImage(cp.x, cp.y + 1), srcImage(fp.x, fp.y + 1), bc);
    float alpha20 = _calcAlpha2(srcImage(cp.x + 1, cp.y - 1), srcImage(fp.x + 1, fp.y - 1), bc);
    float alpha21 = _calcAlpha2(srcImage(cp.x + 1, cp.y), srcImage(fp.x + 1, fp.y), bc);
    float alpha22 = _calcAlpha2(srcImage(cp.x + 1, cp.y + 1), srcImage(fp.x + 1, fp.y + 1), bc);
    
    //float alpha_current = alpha11;
    float alpha_gx = alpha02 + 2 * alpha12 + alpha22 - alpha00 - 2 * alpha10 - alpha20;
    float alpha_gy = alpha20 + 2 * alpha21 + alpha22 - alpha00 - 2 * alpha01 - alpha02;
    
    float deltaAlpha = sqrt(alpha_gx * alpha_gx + alpha_gy * alpha_gy);
    return deltaAlpha;
    
}

cv::Mat3f _calcDeltaImage2(cv::Mat3b& srcImage) {
    cv::Mat3f deltaImage = cv::Mat3f(srcImage.rows, srcImage.cols);
    for (int y = 1; y < srcImage.rows - 1; y++) {
        for (int x = 1; x < srcImage.cols - 1; x++) {
            
            cv::Vec3b I00 = srcImage(y - 1, x - 1);
            cv::Vec3b I01 = srcImage(y - 1, x);
            cv::Vec3b I02 = srcImage(y - 1, x + 1);
            cv::Vec3b I10 = srcImage(y, x - 1);
            cv::Vec3b I11 = srcImage(y, x);
            cv::Vec3b I12 = srcImage(y, x + 1);
            cv::Vec3b I20 = srcImage(y + 1, x - 1);
            cv::Vec3b I21 = srcImage(y + 1, x);
            cv::Vec3b I22 = srcImage(y + 1, x + 1);
            float gx_r = I02[0] + 2 * I12[0] + I22[0] - I00[0] - 2 * I10[0] - I20[0];
            float gx_g = I02[1] + 2 * I12[1] + I22[1] - I00[1] - 2 * I10[1] - I20[1];
            float gx_b = I02[2] + 2 * I12[2] + I22[2] - I00[2] - 2 * I10[2] - I20[2];
            float gy_r = I20[0] + 2 * I21[0] + I22[0] - I00[0] - 2 * I01[0] - I02[0];
            float gy_g = I20[1] + 2 * I21[1] + I22[1] - I00[1] - 2 * I01[1] - I02[1];
            float gy_b = I20[2] + 2 * I21[2] + I22[2] - I00[2] - 2 * I01[2] - I02[2];
            deltaImage(y,x)[0] = sqrt(gx_r * gx_r + gy_r * gy_r);
            deltaImage(y,x)[1] = sqrt(gx_g * gx_g + gy_g * gy_g);
            deltaImage(y,x)[2] = sqrt(gx_b * gx_b + gy_b * gy_b);
        }
    }
    
    imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/Testset/0-deltaImage.png", deltaImage);
    
    return deltaImage;
}

static float colorCost2(cv::Mat3f& srcDeltaImage, cv::Mat3b& srcImage, cv::Point cp, cv::Point fp, cv::Point bp) {
    
    
    cv::Vec3b fc = srcImage(fp.x, fp.y);
    cv::Vec3b bc = srcImage(bp.x, bp.y);
    float alpha = _calcAlpha2(srcImage(cp.x, cp.y), srcImage(fp.x, fp.y), srcImage(bp.x, bp.y));
    float deltaAlpha = _calcDeltaAlpha2(srcImage, cp, fp, bp);
    
    float cost_r = srcDeltaImage(cp.x, cp.y)[0] - deltaAlpha * (fc[0] - bc[0]); // deltaI - deltaAlpha * (F - B) - alpha * deltaF
    float cost_g = srcDeltaImage(cp.x, cp.y)[1] - deltaAlpha * (fc[1] - bc[1]);
    float cost_b = srcDeltaImage(cp.x, cp.y)[2] - deltaAlpha * (fc[2] - bc[2]);
    float cost = sqrt(cost_r * cost_r + cost_g * cost_g + cost_b * cost_b);
    
    return cost;
}


// Eq. 4
static float distCost(const cv::Point &p0, const cv::Point &p1, float minDist)
{
    int dist = sqr(p0.x - p1.x) + sqr(p0.y - p1.y);
    return sqrt((float)dist) / minDist;
}

static float colorDist(const cv::Vec3b &I0, const cv::Vec3b &I1)
{
    int result = 0;

    for (int c = 0; c < 3; ++c)
        result += sqr((int)I0[c] - (int)I1[c]);

    return sqrt((float)result);
}

static float nearestDistance(const std::vector<cv::Point> &boundary, const cv::Point &p)
{
    int minDist2 = INT_MAX;
    for (std::size_t i = 0; i < boundary.size(); ++i)
    {
        int dist2 = sqr(boundary[i].x - p.x)  + sqr(boundary[i].y - p.y);
        minDist2 = std::min(minDist2, dist2);
    }

    return sqrt((float)minDist2);
}


// for sorting the boundary pixels according to intensity
struct IntensityComp
{
    IntensityComp(const cv::Mat_<cv::Vec3b> &image) : image(image)
    {

    }

    bool operator()(const cv::Point &p0, const cv::Point &p1) const
    {
        const cv::Vec3b &c0 = image(p0.y, p0.x);
        const cv::Vec3b &c1 = image(p1.y, p1.x);

        return ((int)c0[0] + (int)c0[1] + (int)c0[2]) < ((int)c1[0] + (int)c1[1] + (int)c1[2]);
    }

    const cv::Mat_<cv::Vec3b> &image;
};

static void expansionOfKnownRegions(const cv::Mat_<cv::Vec3b> &image,
                                    cv::Mat_<uchar> &trimap,
                                    int r, float c)
{
    int w = image.cols;
    int h = image.rows;

    for (int x = 0; x < w; ++x)
        for (int y = 0; y < h; ++y)
        {
            if (trimap(y, x) != 128)
                continue;

            const cv::Vec3b &I = image(y, x);

            for (int j = y-r; j <= y+r; ++j)
                for (int i = x-r; i <= x+r; ++i)
                {
                    if (i < 0 || i >= w || j < 0 || j >= h)
                        continue;

                    if (trimap(j, i) != 0 && trimap(j, i) != 255)
                        continue;

                    const cv::Vec3b &I2 = image(j, i);

                    float pd = sqrt((float)(sqr(x - i) + sqr(y - j)));
                    float cd = colorDist(I, I2);

                    if (pd <= r && cd <= c)
                    {
                        if (trimap(j, i) == 0)
                            trimap(y, x) = 1;
                        else if (trimap(j, i) == 255)
                            trimap(y, x) = 254;
                    }
                }
        }

    for (int x = 0; x < trimap.cols; ++x)
        for (int y = 0; y < trimap.rows; ++y)
        {
            if (trimap(y, x) == 1)
                trimap(y, x) = 0;
            else if (trimap(y, x) == 254)
                trimap(y, x) = 255;

        }
}

// erode foreground and background regions to increase the size of unknown region
static void erodeFB(cv::Mat_<uchar> &trimap, int r)
{
    int w = trimap.cols;
    int h = trimap.rows;

    cv::Mat_<uchar> foreground(trimap.size(), (uchar)0);
    cv::Mat_<uchar> background(trimap.size(), (uchar)0);

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


struct Sample
{
    int fi, bj;
    float df, db;
    float cost, alpha;
};

static void calculateAlphaPatchMatch(const cv::Mat_<cv::Vec3b> &image,
        const cv::Mat_<uchar> &trimap,
        const std::vector<cv::Point> &foregroundBoundary,
        const std::vector<cv::Point> &backgroundBoundary,
        std::vector<std::vector<Sample> > &samples)
{
    int w = image.cols;
    int h = image.rows;

    samples.resize(h, std::vector<Sample>(w));

    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
        {
            if (trimap(y, x) == 128)
            {
                cv::Point p(x, y);

                samples[y][x].fi = rand() % foregroundBoundary.size();
                samples[y][x].bj = rand() % backgroundBoundary.size();
                samples[y][x].df = nearestDistance(foregroundBoundary, p);
                samples[y][x].db = nearestDistance(backgroundBoundary, p);
                samples[y][x].cost = FLT_MAX;
            }
        }

    std::vector<cv::Point> coords(w * h);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            coords[x + y * w] = cv::Point(x, y);

    cv::Mat3f srcDeltaImage = _calcDeltaImage2((cv::Mat3b&)image);
    
    for (int iter = 0; iter < 10; ++iter)
    {
        // propagation
        std::random_shuffle(coords.begin(), coords.end());

        for (std::size_t i = 0; i < coords.size(); ++i)
        {
            const cv::Point &p = coords[i];

            int x = p.x;
            int y = p.y;

            if (trimap(y, x) != 128)
                continue;

            const cv::Vec3b &I = image(y, x);

            Sample &s = samples[y][x];

            for (int y2 = y - 1; y2 <= y + 1; ++y2)
                for (int x2 = x - 1; x2 <= x + 1; ++x2)
                {
                    if (x2 < 0 || x2 >= w || y2 < 0 || y2 >= h)
                        continue;

                    if (trimap(y2, x2) != 128)
                        continue;

                    Sample &s2 = samples[y2][x2];

                    const cv::Point &fp = foregroundBoundary[s2.fi];
                    const cv::Point &bp = backgroundBoundary[s2.bj];

                    const cv::Vec3b F = image(fp.y, fp.x);
                    const cv::Vec3b B = image(bp.y, bp.x);

                    float alpha = calculateAlpha(F, B, I);

                    
                    float cost1 = colorCost(F, B, I, alpha);
                    float cost2 = colorCost2(srcDeltaImage, (cv::Mat3b&)image, p, fp, bp);
                    
                    float cost = cost1 + distCost(p, fp, s.df) + distCost(p, bp, s.db);
                    
                    //printf("cost1 = %f, cost2 = %f\n", cost1, cost2);

                    if (cost < s.cost)
                    {
                        s.fi = s2.fi;
                        s.bj = s2.bj;
                        s.cost = cost;
                        s.alpha = alpha;
                    }
                }
        }

        // random walk
        int w2 = (int)std::max(foregroundBoundary.size(), backgroundBoundary.size());

        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x)
            {
                if (trimap(y, x) != 128)
                    continue;

                cv::Point p(x, y);

                const cv::Vec3b &I = image(y, x);

                Sample &s = samples[y][x];

                for (int k = 0; ; k++)
                {
                    float r = w2 * pow(0.5f, k);

                    if (r < 1)
                        break;

                    int di = r * (rand() / (RAND_MAX + 1.f));
                    int dj = r * (rand() / (RAND_MAX + 1.f));

                    int fi = s.fi + di;
                    int bj = s.bj + dj;

                    if (fi < 0 || fi >= foregroundBoundary.size() || bj < 0 || bj >= backgroundBoundary.size())
                        continue;

                    const cv::Point &fp = foregroundBoundary[fi];
                    const cv::Point &bp = backgroundBoundary[bj];

                    const cv::Vec3b F = image(fp.y, fp.x);
                    const cv::Vec3b B = image(bp.y, bp.x);

                    float alpha = calculateAlpha(F, B, I);

                    float cost1 = colorCost(F, B, I, alpha);
                    float cost2 = colorCost2(srcDeltaImage, (cv::Mat3b&)image, p, fp, bp);
                    
                    float cost = cost1 + distCost(p, fp, s.df) + distCost(p, bp, s.db);
                    
                    if (cost < s.cost)
                    {
                        s.fi = fi;
                        s.bj = bj;
                        s.cost = cost;
                        s.alpha = alpha;
                    }
                }
            }
    }
}

static void expansionOfKnownRegionsHelper(const cv::Mat &_image,
                                          cv::Mat &_trimap,
                                          int r, float c)
{
    const cv::Mat_<cv::Vec3b> &image = (const cv::Mat_<cv::Vec3b> &)_image;
    cv::Mat_<uchar> &trimap = (cv::Mat_<uchar>&)_trimap;

    int w = image.cols;
    int h = image.rows;

    for (int x = 0; x < w; ++x)
        for (int y = 0; y < h; ++y)
        {
            if (trimap(y, x) != 128)
                continue;

            const cv::Vec3b &I = image(y, x);

            for (int j = y-r; j <= y+r; ++j)
                for (int i = x-r; i <= x+r; ++i)
                {
                    if (i < 0 || i >= w || j < 0 || j >= h)
                        continue;

                    if (trimap(j, i) != 0 && trimap(j, i) != 255)
                        continue;

                    const cv::Vec3b &I2 = image(j, i);

                    float pd = sqrt((float)(sqr(x - i) + sqr(y - j)));
                    float cd = colorDist(I, I2);

                    if (pd <= r && cd <= c)
                    {
                        if (trimap(j, i) == 0)
                            trimap(y, x) = 1;
                        else if (trimap(j, i) == 255)
                            trimap(y, x) = 254;
                    }
                }
        }

    for (int x = 0; x < trimap.cols; ++x)
        for (int y = 0; y < trimap.rows; ++y)
        {
            if (trimap(y, x) == 1)
                trimap(y, x) = 0;
            else if (trimap(y, x) == 254)
                trimap(y, x) = 255;

        }
}

// erode foreground and background regions to increase the size of unknown region
static void erodeFB(cv::Mat &_trimap, int r)
{
    cv::Mat_<uchar> &trimap = (cv::Mat_<uchar>&)_trimap;

    int w = trimap.cols;
    int h = trimap.rows;

    cv::Mat_<uchar> foreground(trimap.size(), (uchar)0);
    cv::Mat_<uchar> background(trimap.size(), (uchar)0);

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



void expansionOfKnownRegions(cv::InputArray _img, cv::InputOutputArray _trimap, int niter)
{
    cv::Mat img = _img.getMat();
    cv::Mat &trimap = _trimap.getMatRef();

    if (img.empty())
        CV_Error(CV_StsBadArg, "image is empty");
    if (img.type() != CV_8UC3)
        CV_Error(CV_StsBadArg, "image mush have CV_8UC3 type");

    if (trimap.empty())
        CV_Error(CV_StsBadArg, "trimap is empty");
    if (trimap.type() != CV_8UC1)
        CV_Error(CV_StsBadArg, "trimap mush have CV_8UC1 type");

    if (img.size() != trimap.size())
        CV_Error(CV_StsBadArg, "image and trimap mush have same size");

    erodeFB(trimap, 20);
    
    for (int i = 0; i < niter; ++i)
        expansionOfKnownRegionsHelper(img, trimap, i + 1, niter - i);
    erodeFB(trimap, 2);
    cv::imwrite("/Users/longyan/Desktop/WorkSpace/ImageSpace/AlphaMatting/TestSet/16212-trimap-erode-gm.png", trimap);
}


static void globalMattingHelper(cv::Mat _image, cv::Mat _trimap, cv::Mat &_foreground, cv::Mat &_alpha, cv::Mat &_conf)
{
    const cv::Mat_<cv::Vec3b> &image = (const cv::Mat_<cv::Vec3b>&)_image;
    const cv::Mat_<uchar> &trimap = (const cv::Mat_<uchar>&)_trimap;

    std::vector<cv::Point> foregroundBoundary = findBoundaryPixels(trimap, 255, 128);
    std::vector<cv::Point> backgroundBoundary = findBoundaryPixels(trimap, 0, 128);

    int n = (int)(foregroundBoundary.size() + backgroundBoundary.size());
    for (int i = 0; i < n; ++i)
    {
        int x = rand() % trimap.cols;
        int y = rand() % trimap.rows;

        if (trimap(y, x) == 0)
            backgroundBoundary.push_back(cv::Point(x, y));
        else if (trimap(y, x) == 255)
            foregroundBoundary.push_back(cv::Point(x, y));
    }

    std::sort(foregroundBoundary.begin(), foregroundBoundary.end(), IntensityComp(image));
    std::sort(backgroundBoundary.begin(), backgroundBoundary.end(), IntensityComp(image));

    std::vector<std::vector<Sample> > samples;
    calculateAlphaPatchMatch(image, trimap, foregroundBoundary, backgroundBoundary, samples);

    _foreground.create(image.size(), CV_8UC3);
    _alpha.create(image.size(), CV_8UC1);
    _conf.create(image.size(), CV_8UC1);

    cv::Mat_<cv::Vec3b> &foreground = (cv::Mat_<cv::Vec3b>&)_foreground;
    cv::Mat_<uchar> &alpha = (cv::Mat_<uchar>&)_alpha;
    cv::Mat_<uchar> &conf = (cv::Mat_<uchar>&)_conf;

    for (int y = 0; y < alpha.rows; ++y)
        for (int x = 0; x < alpha.cols; ++x)
        {
            switch (trimap(y, x))
            {
                case 0:
                    alpha(y, x) = 0;
                    conf(y, x) = 255;
                    foreground(y, x) = 0;
                    break;
                case 128:
                {
                    alpha(y, x) = 255 * samples[y][x].alpha;
                    conf(y, x) = 255 * exp(-samples[y][x].cost / 6);
                    cv::Point p = foregroundBoundary[samples[y][x].fi];
                    foreground(y, x) = image(p.y, p.x);
                    break;
                }
                case 255:
                    alpha(y, x) = 255;
                    conf(y, x) = 255;
                    foreground(y, x) = image(y, x);
                    break;
            }
        }
}

void globalMatting(cv::InputArray _image, cv::InputArray _trimap, cv::OutputArray _foreground, cv::OutputArray _alpha, cv::OutputArray _conf)
{
    cv::Mat image = _image.getMat();
    cv::Mat trimap = _trimap.getMat();

    if (image.empty())
        CV_Error(CV_StsBadArg, "image is empty");
    if (image.type() != CV_8UC3)
        CV_Error(CV_StsBadArg, "image mush have CV_8UC3 type");

    if (trimap.empty())
        CV_Error(CV_StsBadArg, "trimap is empty");
    if (trimap.type() != CV_8UC1)
        CV_Error(CV_StsBadArg, "trimap mush have CV_8UC1 type");

    if (image.size() != trimap.size())
        CV_Error(CV_StsBadArg, "image and trimap mush have same size");

    cv::Mat &foreground = _foreground.getMatRef();
    cv::Mat &alpha = _alpha.getMatRef();
    cv::Mat tempConf;

    globalMattingHelper(image, trimap, foreground, alpha, tempConf);

    if(_conf.needed())
        tempConf.copyTo(_conf);
}


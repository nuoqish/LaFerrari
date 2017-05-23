//
//  ViewController.m
//  MoguMattor
//
//  Created by longyan on 2016/12/30.
//  Copyright © 2016年 shenyanhao. All rights reserved.
//

#import "ViewController.h"

#import "NSImage+Utils.h"
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#include "AlphaSolver.hpp"
#include "FBSolver.hpp"
#include "SSMattor.hpp"

#import "KTImageView.h"
#import "KTBrushView.h"
#import "KTCropView.h"
#import "KTListView.h"

#import "KTBackgroundPickerView.h"
#import "KTMattingPickerView.h"


#define MAX_IMAGE_NUM 10
#define USE_AUTO_SEGMENT 0
#define USE_SSMATTOR 0


cv::Rect_<int> extractForegroundRect(Mat& image) {
    
    cv::Rect_<int> rect;
    
    Mat gray;
    cvtColor(image, gray, COLOR_BGR2GRAY);
    Mat1b result;
    double thresh = 0;
    threshold(gray, result, thresh, 255, THRESH_BINARY_INV + THRESH_OTSU);
    
    int top = image.rows - 1;
    int bottom = 0;
    int left = image.cols - 1;
    int right = 0;
    
    for (int i = 0; i < image.rows; i++) {
        for (int j = 0; j < image.cols; j++) {
            if (result(i,j) == 255) {
                if (i < top) {
                    top = i;
                }
                if (i > bottom) {
                    bottom = i;
                }
                if (j < left) {
                    left = j;
                }
                if (j > right) {
                    right = j;
                }
            }
        }
    }
    
    return Rect_<int>(left, top, right - left, bottom - top);
}


@interface ViewController () <KTCropViewDelegate, KTListViewDelegate , KTBackgroundPickerViewDelegate, KTMattingPickerViewDelegate>

@property (nonatomic, assign) SelectMode selectMode;
@property (nonatomic, assign) DisplayMode editViewDisplayMode;
@property (nonatomic, assign) DisplayMode previewViewDisplayMode;

@property (nonatomic, strong) NSImage *sourceImage;
@property (nonatomic, assign) CGFloat scaleRatio;
@property (nonatomic, assign) CGFloat editingImageViewZoomingScale;
@property (nonatomic, strong) NSMutableArray *brushPoints;
@property (nonatomic, strong) NSMutableArray<NSURL *> *fileUrls;
@property (nonatomic, assign) BOOL showFileListView;

@property (nonatomic, strong) KTImageView *editingView;
@property (nonatomic, strong) NSImageView *maskImageView;
@property (nonatomic, strong) KTImageView *previewingView;
@property (nonatomic, strong) KTBrushView *brushView;
@property (nonatomic, strong) KTCropView *cropView;
@property (nonatomic, strong) KTListView *fileListView;

@property (nonatomic, strong) KTBackgroundPickerView *colorPicker;
@property (nonatomic, strong) KTMattingPickerView *mattingPicker;
@property (nonatomic, strong) NSBox *verticalSeparator;
@property (nonatomic, strong) NSProgressIndicator *progressIndictor;

@end

static const CGFloat kTabbarHeight = 30;
static const CGFloat kMiddleWidth = 2;
static const CGFloat kFileListWidth = 70;


@implementation ViewController {
    
    Mat4b currentSrcImage; // 当前处理图像
    Mat4b currentBckImage;
    
    Mat1b dstMaskMono;
    Mat4b dstMaskColor; // 输出mask，彩色
    Mat4b dstForegroundAlpha;
    
    Mat1b dstMaskMonoLast;
    Mat4b dstMaskColorLast;
    Mat4b dstForegroundAlphaLast;
    
    Rect_<int> cropRect;
    Mat fgdModel;
    Mat bgdModel;
    Mat1b grabcutResult;
    
    map<string, int> fileIndexMap;
    
    Vec4b previewBackgroundColor;
    Vec4b maskForeColor;
    Vec4b maskBackColor;
    Vec4b maskUnknownColor;
    
    
}

- (void)dealloc {
    
}



- (void)viewWillAppear {
    [super viewWillAppear];
    if ([NSColorPanel sharedColorPanelExists]) {
        [[NSColorPanel sharedColorPanel] close];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSubViews];
    [self commonInit];
    self.fileUrls = @[].mutableCopy;
    self.editingImageViewZoomingScale = 1.0;
    self.selectMode = self.mattingPicker.mattingMode;
    self.brushPoints = [[NSMutableArray alloc] init];
    self.brushView.pointsArray = self.brushPoints;
    self.brushView.lineWith = self.mattingPicker.sliderValue;
    self.sourceImage = [NSImage imageNamed:@"VOL3_单品_鞋子_11.jpeg"];
    
    
}


- (void)commonInit {
    maskForeColor = Vec4b(0,255,0,255);
    maskBackColor = Vec4b(255,0,0,255);
    maskUnknownColor = Vec4b(128,128,128,128);
    previewBackgroundColor = Vec4b(255, 30, 120, 255);
    
}

- (void)initSubViews {
    [self.view addSubview:self.editingView];
    [self.view addSubview:self.previewingView];
    [self.view addSubview:self.verticalSeparator];
    [self.view addSubview:self.mattingPicker];
    [self.editingView addCustomView:self.maskImageView];
    [self.editingView addCustomView:self.brushView];
    [self.editingView addCustomView:self.cropView];

}



- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutSubviews];
}

- (void)layoutSubviews {
    if (currentSrcImage.rows == 0) {
        return;
    }
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat fileListViewWidth = (self.showFileListView ? kFileListWidth : 0);
    
    // 根据图片比例计算视图显示比例，通过editView的magnification属性进行editingImageView图片大小缩放，而editingImageView的frame尺寸不变
    CGFloat editViewMaxWidth = (viewWidth - fileListViewWidth) / 2 - kMiddleWidth;
    CGFloat editViewMaxHeight = viewHeight - kTabbarHeight;
    CGFloat editViewRatio = editViewMaxWidth / editViewMaxHeight;
    CGFloat imageRatio = (CGFloat)currentSrcImage.cols / currentSrcImage.rows;
    CGFloat resizeImageWidth, resizeImageHeight;
    if (imageRatio > editViewRatio) {
        resizeImageWidth = editViewMaxWidth;
        resizeImageHeight = resizeImageWidth / imageRatio;
    }
    else {
        resizeImageHeight = editViewMaxHeight;
        resizeImageWidth = resizeImageHeight * imageRatio;
    }
    CGFloat editViewWidth = resizeImageWidth * self.editingImageViewZoomingScale;
    CGFloat editViewHeight = resizeImageHeight * self.editingImageViewZoomingScale;
    if (editViewWidth > editViewMaxWidth) {
        editViewWidth = editViewMaxWidth;
    }
    if (editViewHeight > editViewMaxHeight) {
        editViewHeight = editViewMaxHeight;
    }
    
    self.scaleRatio = currentSrcImage.cols / resizeImageWidth;
    self.verticalSeparator.frame = NSMakeRect(fileListViewWidth + (viewWidth - fileListViewWidth) / 2, 0, 1, viewHeight - kTabbarHeight);
    self.progressIndictor.frame = NSMakeRect(viewWidth / 2, viewHeight / 2, 50, 50);
    if (self.showFileListView) {
        self.fileListView.frame = NSMakeRect(0, 0, kFileListWidth, editViewMaxHeight);
    }
    self.mattingPicker.frame = NSMakeRect(0, viewHeight - kTabbarHeight, viewWidth, kTabbarHeight);
    self.editingView.frame = NSMakeRect(fileListViewWidth + (editViewMaxWidth - editViewWidth) / 2, (editViewMaxHeight - editViewHeight) / 2, editViewWidth, editViewHeight);
    self.editingView.magnification = self.editingImageViewZoomingScale;
    self.editingView.maxFrameSize = CGSizeMake(editViewMaxWidth, editViewMaxHeight);
    self.maskImageView.frame = self.editingView.imageFrame;
    self.brushView.frame = self.editingView.imageFrame;
    self.cropView.frame = self.editingView.imageFrame;
    self.previewingView.frame = NSMakeRect(fileListViewWidth + editViewMaxWidth + kMiddleWidth * 2 + (editViewMaxWidth - editViewWidth) / 2, (editViewMaxHeight - editViewHeight) / 2, editViewWidth, editViewHeight);
    self.previewingView.magnification = self.editingImageViewZoomingScale;
    self.previewingView.maxFrameSize = CGSizeMake(editViewMaxWidth, editViewMaxHeight);
    
}



- (KTImageView *)editingView {
    if (!_editingView) {
        _editingView = [[KTImageView alloc] init];
    }
    return _editingView;
}

- (KTImageView *)previewingView {
    if (!_previewingView) {
        _previewingView = [[KTImageView alloc] init];
    }
    return _previewingView;
}

- (NSImageView *)maskImageView {
    if (!_maskImageView) {
        _maskImageView = [[NSImageView alloc] init];
        _maskImageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        _maskImageView.alphaValue = 0.5;
    }
    return _maskImageView;
}

- (KTBrushView *)brushView {
    if (!_brushView) {
        _brushView = [[KTBrushView alloc] init];
    }
    return _brushView;
}

- (KTCropView *)cropView {
    if (!_cropView) {
        _cropView = [[KTCropView alloc] init];
        _cropView.delegate = self;
    }
    return _cropView;
}

- (KTListView *)fileListView {
    if (!_fileListView) {
        _fileListView = [[KTListView alloc] init];
        _fileListView.delegate = self;
        [self.view addSubview:_fileListView];
    }
    return _fileListView;
}


- (NSBox *)verticalSeparator {
    if (!_verticalSeparator) {
        _verticalSeparator = [[NSBox alloc] initWithFrame:NSMakeRect(self.view.bounds.size.width / 2, 0, 2, self.view.bounds.size.height - kTabbarHeight)];
        _verticalSeparator.boxType = NSBoxSeparator;
    }
    return _verticalSeparator;
}


- (KTBackgroundPickerView *)colorPicker {
    if (!_colorPicker) {
        _colorPicker = [[KTBackgroundPickerView alloc] init];
        _colorPicker.delegate = self;
        [self.previewingView addSubview:_colorPicker];
    }
    return _colorPicker;
}

- (KTMattingPickerView *)mattingPicker {
    if (!_mattingPicker) {
        _mattingPicker = [KTMattingPickerView new];
        _mattingPicker.delegate = self;
    }
    return _mattingPicker;
}


- (NSProgressIndicator *)progressIndictor {
    if (!_progressIndictor) {
        _progressIndictor = [[NSProgressIndicator alloc] init];
        _progressIndictor.style = NSProgressIndicatorSpinningStyle;
        _progressIndictor.displayedWhenStopped = NO;
        [self.view addSubview:_progressIndictor];
    }
    return _progressIndictor;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)setSourceImage:(NSImage *)sourceImage {
    
    _sourceImage = sourceImage;
    
    dstMaskColor = Mat4b(0,0);
    dstMaskMono = Mat1b(0,0);
    dstMaskMonoLast = Mat1b(0,0);
    dstMaskColorLast = Mat4b(0,0);
    dstForegroundAlpha = Mat4b(0,0);
    dstForegroundAlphaLast = Mat4b(0,0);
    grabcutResult = Mat1b(0, 0);
    
    self.mattingPicker.mattingMode = SelectModeForegroundTarget;
    self.mattingPicker.previewMode = DisplayModeForeground;
    self.editingView.image = sourceImage;
    self.previewingView.image = sourceImage;
    self.maskImageView.image = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        currentSrcImage = [sourceImage CVMat2];
        
        cropRect = extractForegroundRect(currentSrcImage);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.editingImageViewZoomingScale = 1.0;
            self.cropView.cropRect = CGRectMake((CGFloat)cropRect.x / currentSrcImage.cols,
                                                1. - (CGFloat)(cropRect.y + cropRect.height) / currentSrcImage.rows,
                                                (CGFloat)cropRect.width / currentSrcImage.cols,
                                                (CGFloat)cropRect.height / currentSrcImage.rows);
            [self confirmButtonTappedForCropView:self.cropView];
            self.cropView.hidden = NO;
            [self.cropView showCloseButton:YES];
            self.colorPicker.hidden = YES;
            
            [self.view setNeedsLayout:YES];
            [self layoutSubviews];
            
        });
        
    });
    

    
}

- (void)setSelectMode:(SelectMode)selectMode {
    _selectMode = selectMode;
    
}

- (void)updateSubViews {
    if (self.editViewDisplayMode == DisplayModeEditImage) {
        if (dstMaskColor.rows > 0) {
            NSImage *image = [NSImage imageWithCVMat:dstMaskColor];
            self.maskImageView.image = image;
            self.maskImageView.hidden = NO;
        }
        self.maskImageView.alphaValue = 0.5;
        if (self.selectMode == SelectModeForegroundTarget ||
            self.selectMode == SelectModeBackgroundTarget ||
            self.selectMode == SelectModeUnknownAreaTarget) {
            self.cropView.hidden = NO;
            [self.cropView showCloseButton:(grabcutResult.rows == currentSrcImage.rows && grabcutResult.cols == currentSrcImage.cols)];
        }
        else if (self.selectMode == SelectModeForegroundFineTuning ||
                 self.selectMode == SelectModeBackgroundFineTuning ||
                 self.selectMode == SelectModeUnknownAreaFineTuning) {
            self.cropView.hidden = YES;
        }
    }
    else if (self.editViewDisplayMode == DisplayModeSourceImage) {
        self.maskImageView.hidden = YES;
        self.cropView.hidden = YES;
    }
    
    if (self.previewViewDisplayMode == DisplayModeSegmentImage) {
        if (dstMaskMono.rows > 0) {
            self.previewingView.image = [NSImage imageWithCVMat:dstMaskMono];
        }
        self.colorPicker.hidden = YES;
    }
    else if (self.previewViewDisplayMode == DisplayModeForeground) {
        if (dstMaskMono.rows > 0) {
            
            NSImage *image = [NSImage imageWithCVMat:dstForegroundAlpha];
            self.previewingView.image = image;
            self.colorPicker.hidden = NO;
            
        }
    }
}

#pragma mark - Actions

- (void)openImageUrl:(NSURL *)imageUrl {
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageUrl];
    if (image) {
        self.sourceImage = image;
        //[self.fileUrls addObject:fileUrl];
        [self.view.window setTitleWithRepresentedFilename:[imageUrl path]];
        [self.view setNeedsLayout:YES];
    }
}

- (void)openImageUrls:(NSArray<NSURL *> *)imageUrls {
    [self.fileUrls addObjectsFromArray:imageUrls];
    
    self.fileListView.fileUrls = self.fileUrls;
    [self.fileListView reloadData];
    self.showFileListView = YES;
    [self.view setNeedsLayout:YES];
    [self layoutSubviews];
}

- (void)saveImageUrl:(NSURL *)imageUrl {
    NSString *filePath = [imageUrl path];
    if (self.previewViewDisplayMode == DisplayModeSegmentImage) {
        NSImage *image = [NSImage imageWithCVMat:dstMaskMono];
        [image saveToFile:filePath];
    }
    else {
        NSImage *image = [NSImage imageWithCVMat:dstForegroundAlpha];
        [image saveToFile:filePath];
        
    }
}

- (void)undo {
    if (dstMaskMonoLast.rows > 0 && dstMaskColorLast.rows > 0 && dstForegroundAlphaLast.rows > 0) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dstMaskColorLast.copyTo(dstMaskColor);
            dstMaskMonoLast.copyTo(dstMaskMono);
            dstForegroundAlphaLast.copyTo(dstForegroundAlpha);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSubViews];
            });
        });
    }
}


#pragma mark - mouse event handling

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    
    if (!self.cropView.hidden) {
        return;
    }
    
    NSPoint locationInWindow = event.locationInWindow;
    NSPoint position = [self.view convertPoint:locationInWindow toView:self.brushView];
    [self.brushView reset];
    [self.brushPoints removeAllObjects];
    [self.brushPoints addObject:[NSValue valueWithPoint:position]];
    [self.brushView setNeedsDisplay:YES];
    
}

- (void)mouseDragged:(NSEvent *)event {
    [super mouseDragged:event];
    
    if (!self.cropView.hidden) {
        return;
    }
    
    NSPoint locationInWindow = event.locationInWindow;
    NSPoint position = [self.view convertPoint:locationInWindow toView:self.brushView];
    [self.brushPoints addObject:[NSValue valueWithPoint:position]];
    [self.brushView setNeedsDisplay:YES];
    
}

- (void)mouseUp:(NSEvent *)event {
    [super mouseUp:event];
    
    if (!self.cropView.hidden) {
        return;
    }
    
    NSPoint locationInWindow = event.locationInWindow;
    if (![self.editingView mouse:locationInWindow inRect:self.editingView.frame]) {
        [self.brushPoints removeAllObjects];
        [self.brushView setNeedsDisplay:YES];
        return;
    }
    
    NSPoint position = [self.view convertPoint:locationInWindow toView:self.brushView];
    [self.brushPoints addObject:[NSValue valueWithPoint:position]];
    [self.brushView setNeedsDisplay:YES];
    
    if (self.selectMode == SelectModeForegroundTarget || self.selectMode == SelectModeBackgroundTarget) {
        
        if (currentSrcImage.rows == 0 || grabcutResult.rows == 0) {
            [self.brushPoints removeAllObjects];
            [self.brushView setNeedsDisplay:YES];
            return;
        }
        
        dstMaskMono.copyTo(dstMaskMonoLast);
        dstMaskColor.copyTo(dstMaskColorLast);
        dstForegroundAlpha.copyTo(dstForegroundAlphaLast);
        
        NSImage *drawImage = [self.brushView generateMaskWithScale:self.scaleRatio];
        Mat1b drawMat = [drawImage CVGrayscaleMat];
        
        if (self.selectMode == SelectModeForegroundTarget) {
            for (int y = 0; y < drawMat.rows; y++) {
                for (int x = 0; x < drawMat.cols; x++) {
                    uint8 value = drawMat(y,x);
                    if (value >= 127) {
                        grabcutResult(y,x) = GC_PR_FGD;
                    }
                }
            }
        }
        else if (self.selectMode == SelectModeBackgroundTarget) {
            for (int y = 0; y < drawMat.rows; y++) {
                for (int x = 0; x < drawMat.cols; x++) {
                    uint8 value = drawMat(y,x);
                    if (value >= 127) {
                        grabcutResult(y,x) = GC_BGD;
                    }
                }
            }
        }
        
        [self.progressIndictor startAnimation:nil];
        self.view.acceptsTouchEvents = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            Mat image;
            cvtColor(currentSrcImage, image, CV_RGBA2RGB);
            clock_t tic = clock();
            grabCut(image, grabcutResult, cropRect, bgdModel, fgdModel, 2, GC_EVAL);
            NSLog(@"grab cut cost time: %.3f", 1000. * (clock() - tic) / NSEC_PER_SEC);
            compare(grabcutResult, GC_PR_FGD, dstMaskMono, CMP_EQ);
            
            if (self.selectMode == SelectModeForegroundTarget) {
                for (int i = 0; i < drawMat.rows; i++) {
                    for (int j = 0; j < drawMat.cols; j++) {
                        if (drawMat(i,j) >= 127) {
                            dstMaskMono(i,j) = 255;
                        }
                    }
                }
            }
            else if (self.selectMode == SelectModeBackgroundTarget) {
                for (int i = 0; i < drawMat.rows; i++) {
                    for (int j = 0; j < drawMat.cols; j++) {
                        if (drawMat(i,j) >= 127) {
                            dstMaskMono(i,j) = 0;
                        }
                    }
                }
            }
            
            tic = clock();
#if USE_SSMATTOR
            SSMattor::solveAlphaAndForeground(dstMaskMono, dstForegroundAlpha, image, dstMaskMono, 5);
#else
            currentSrcImage.copyTo(dstForegroundAlpha, dstMaskMono);
#endif
            NSLog(@"ssmattor cost time: %.3f", 1000. * (clock() - tic) / NSEC_PER_SEC);
            if (dstMaskColor.rows != dstMaskMono.rows || dstMaskColor.cols != dstMaskMono.cols) {
                dstMaskColor = Mat4b(dstMaskMono.rows, dstMaskMono.cols);
            }
            for (int i = 0; i < dstMaskMono.rows; i++) {
                for (int j = 0; j < dstMaskMono.cols; j++) {
                    
                    if (dstMaskMono(i,j) >= 250) {
                        dstMaskColor(i,j) = maskForeColor;
                        dstMaskMono(i,j) = 255;
                        dstForegroundAlpha(i,j) = currentSrcImage(i,j);
                    }
                    else if (dstMaskMono(i, j) <= 5) {
                        dstMaskColor(i,j) = maskBackColor;
                        dstMaskMono(i,j) = 0;
                        dstForegroundAlpha(i,j)[3] = 0;
                    }
                    else {
                        dstMaskColor(i,j) = maskUnknownColor;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressIndictor stopAnimation:nil];
                self.cropView.hidden = YES;
                [self updateSubViews];
                self.view.acceptsTouchEvents = YES;
                [self.brushPoints removeAllObjects];
                [self.brushView setNeedsDisplay:YES];
                
            });
            
            
        });
        
    }
    else if (self.selectMode == SelectModeForegroundFineTuning ||
             self.selectMode == SelectModeBackgroundFineTuning ||
             self.selectMode == SelectModeUnknownAreaFineTuning){
        
        if (currentSrcImage.rows == 0) {
            return;
        }
        
        
        [self.progressIndictor startAnimation:nil];
        NSImage *drawImage = [self.brushView generateMaskWithScale:self.scaleRatio];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            Mat1b drawMat = [drawImage CVGrayscaleMat];
            
            if (dstMaskColor.rows != currentSrcImage.rows || dstMaskColor.cols != currentSrcImage.cols) {
                
                dstMaskColor = Mat4b(currentSrcImage.rows, currentSrcImage.cols);
                dstMaskMono = Mat1b(currentSrcImage.rows, currentSrcImage.cols);
                currentSrcImage.copyTo(dstForegroundAlpha);
                for (int y = 0; y < drawMat.rows; y++) {
                    for (int x = 0; x < drawMat.cols; x++) {
                        uint8 value = drawMat(y,x);
                        if (value >= 127) {
                            dstMaskColor(y,x) = maskForeColor;
                            dstMaskMono(y,x) = 255;
                            dstForegroundAlpha(y,x) = currentSrcImage(y,x);
                        }
                        else {
                            dstMaskColor(y,x) = maskBackColor;
                            dstMaskMono(y,x) = 0;
                            dstForegroundAlpha(y,x)[3] = 0;
                        }
                    }
                }
            }
            else {
                dstMaskMono.copyTo(dstMaskMonoLast);
                dstMaskColor.copyTo(dstMaskColorLast);
                dstForegroundAlpha.copyTo(dstForegroundAlphaLast);
                if (self.selectMode == SelectModeForegroundFineTuning) {
                    for (int y = 0; y < drawMat.rows; y++) {
                        for (int x = 0; x < drawMat.cols; x++) {
                            uint8 value = drawMat(y,x);
                            if (value >= 127) {
                                dstMaskColor(y,x) = maskForeColor;
                                dstMaskMono(y,x) = 255;
                                dstForegroundAlpha(y,x) = currentSrcImage(y,x);
                                
                            }
                        }
                    }
                }
                else if (self.selectMode == SelectModeBackgroundFineTuning) {
                    for (int y = 0; y < drawMat.rows; y++) {
                        for (int x = 0; x < drawMat.cols; x++) {
                          
                            uint8 value = drawMat(y,x);
                            if (value >= 127) {
                                dstMaskColor(y,x) = maskBackColor;
                                dstMaskMono(y,x) = 0;
                                dstForegroundAlpha(y,x)[3] = 0;
                            }
                        }
                    }
                }
                else if (self.selectMode == SelectModeUnknownAreaFineTuning) {
                    int left = currentSrcImage.cols - 1;
                    int right = 0;
                    int top = currentSrcImage.rows - 1;
                    int bottom = 0;
                    for (int y = 0; y < drawMat.rows; y++) {
                        for (int x = 0; x < drawMat.cols; x++) {
                            uint8 value = drawMat(y,x);
                            if (value >= 127) {
                                dstMaskColor(y,x) = maskUnknownColor;
                                dstMaskMono(y,x) = 128;
                                if (left > x) {
                                    left = x;
                                }
                                if (right < x) {
                                    right = x;
                                }
                                if (top > y) {
                                    top = y;
                                }
                                if (bottom < y) {
                                    bottom = y;
                                }
                            }
                        }
                    }

                    int expandRadius = 2;
                    for(expandRadius = 2; expandRadius < 10; expandRadius++) {
                        bool flag0 = false, flag255 = false;
                        uint8_t value;
                        
                        if ((top - expandRadius) >= 0 && (left - expandRadius) >= 0) {
                            value = dstMaskMono(top - expandRadius, left - expandRadius);
                            if(value == 0) {
                                flag0 = true;
                            }
                            else if (value == 255) {
                                flag255 = true;
                            }
                        }
                        
                        if ((bottom + expandRadius) < currentSrcImage.rows && (right + expandRadius) < currentSrcImage.cols) {
                            value = dstMaskMono(bottom + expandRadius, right + expandRadius);
                            if(value == 0) {
                                flag0 = true;
                            }
                            else if (value == 255) {
                                flag255 = true;
                            }
                        }
                        
                        if (flag0 && flag255) {
                            break;
                        }
                        
                        if ((top - expandRadius) >= 0 && (right + expandRadius) < currentSrcImage.cols) {
                            value = dstMaskMono(top - expandRadius, right + expandRadius);
                            if(value == 0) {
                                flag0 = true;
                            }
                            else if (value == 255) {
                                flag255 = true;
                            }
                        }
                        
                        if (flag0 && flag255) {
                            break;
                        }
                        
                        if ((bottom + expandRadius) < currentSrcImage.rows && (left - expandRadius) >= 0) {
                            value = dstMaskMono(bottom + expandRadius, left - expandRadius);
                            if(value == 0) {
                                flag0 = true;
                            }
                            else if (value == 255) {
                                flag255 = true;
                            }
                        }
                        
                        if (flag0 && flag255) {
                            break;
                        }
                        
                        
                    }
                    
                    NSLog(@"expandRadius == %d, left = %d, top = %d, right = %d, bottom = %d", expandRadius, left, top, right, bottom);
                    
                    top = max(0,top - expandRadius);
                    left = max(0, left - expandRadius);
                    bottom = min(currentSrcImage.rows - 1, bottom + expandRadius);
                    right = min(currentSrcImage.cols - 1, right + expandRadius);
                    
                    
                    int rows = bottom - top;
                    int cols = right - left;
                    Mat3b image(rows, cols);
                    for (int i = 0; i < rows; i++) {
                        for (int j = 0; j < cols; j++) {
                            image(i, j)[0] = currentSrcImage(top + i, left + j)[2];
                            image(i, j)[1] = currentSrcImage(top + i, left + j)[1];
                            image(i, j)[2] = currentSrcImage(top + i, left + j)[0];
                        }
                    }
                    
                    
                    
                    Rect_<int> rect(left, top, cols, rows);NSLog(@"rect==(%d,%d,%d,%d)", rect.x, rect.y, rect.width, rect.height);
                    Mat1b trimap = dstMaskMono(rect);
                    Mat1b alpha = dstMaskMono(rect);
                    Mat4b foreground = dstForegroundAlpha(rect);
                    AlphaSolver::computeAlpha(alpha, image, trimap, 0, 1);
                    FBSolver::computeForeground(foreground, image, alpha);
                    cvtColor(foreground, foreground, cv::COLOR_RGBA2BGRA);
                    
                }
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.progressIndictor stopAnimation:nil];
                [self updateSubViews];
                
                self.view.acceptsTouchEvents = YES;
                [self.brushPoints removeAllObjects];
                [self.brushView setNeedsDisplay:YES];
            });
            
            
        });
        
        
        
        
    }
    
    
    
    
}



- (void)magnifyWithEvent:(NSEvent *)event {
    
    if (self.editingImageViewZoomingScale == 0.0) {
        self.editingImageViewZoomingScale = 1.0;
    }
    self.editingImageViewZoomingScale *= 1 + [event magnification];
    if (self.editingImageViewZoomingScale > self.editingView.maxMagnification) {
        self.editingImageViewZoomingScale = self.editingView.maxMagnification;
    }
    if (self.editingImageViewZoomingScale < self.editingView.minMagnification) {
        self.editingImageViewZoomingScale = self.editingView.minMagnification;
    }
    
    [self.view setNeedsLayout:YES];
    [self layoutSubviews];
}



#pragma mark - KTCropViewDelegate

- (void)confirmButtonTappedForCropView:(KTCropView *)cropView {
    
    cropRect = Rect_<int>(int(cropView.cropRect.origin.x * currentSrcImage.cols),
                          int((1. - cropView.cropRect.origin.y - cropView.cropRect.size.height) * currentSrcImage.rows),
                          int(cropView.cropRect.size.width * currentSrcImage.cols),
                          int(cropView.cropRect.size.height * currentSrcImage.rows));
    self.cropView.hidden = YES;
    [self.progressIndictor startAnimation:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Mat image;
        cvtColor(currentSrcImage, image, cv::COLOR_RGBA2RGB);
        clock_t tic = clock();
        grabCut(image, grabcutResult, cropRect, bgdModel, fgdModel, 2, GC_INIT_WITH_RECT);
        NSLog(@"grab cut cost time: %.3f", 1000. * (clock() - tic) / NSEC_PER_SEC);
        compare(grabcutResult, GC_PR_FGD, dstMaskMono, CMP_EQ);
        clock_t tic2 = clock();
#if USE_SSMATTOR
        SSMattor::solveAlphaAndForeground(dstMaskMono, dstForegroundAlpha, image, dstMaskMono, 5);
#else
        memset(dstForegroundAlpha.data, 0, dstForegroundAlpha.total() * dstForegroundAlpha.elemSize());
        currentSrcImage.copyTo(dstForegroundAlpha, dstMaskMono);
#endif
        NSLog(@"ssmattor cost time: %.3f", 1000. * (clock() - tic2) / NSEC_PER_SEC);
        
        
        if (dstMaskColor.rows != dstMaskMono.rows || dstMaskColor.cols != dstMaskMono.cols) {
            dstMaskColor = Mat4b(dstMaskMono.rows, dstMaskMono.cols);
        }
        for (int i = 0; i < dstMaskMono.rows; i++) {
            for (int j = 0; j < dstMaskMono.cols; j++) {
                if (dstMaskMono(i,j) == 255) {
                    dstMaskColor(i,j) = maskForeColor;
                }
                else if (dstMaskMono(i,j) == 0){
                    dstMaskColor(i,j) = maskBackColor;
                }
                else {
                    dstMaskColor(i,j) = maskUnknownColor;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndictor stopAnimation:nil];
            
            [self updateSubViews];
        });
        
        
    });
    
}

- (void)closeButtonTappedForCropView:(KTCropView *)cropView {
    self.cropView.hidden = YES;
}

#pragma mark - KTBackgroundPickerViewDelegate

- (void)backgroundPickerView:(KTBackgroundPickerView *)backgroundPickerView didSelectBackgroundColor:(NSColor *)backColor {
    self.previewingView.bkColor = backColor;
    [self updateSubViews];
    
}

- (void)backgroundPickerView:(KTBackgroundPickerView *)backgroundPickerView didSelectBackgroundImage:(NSImage *)backImage {
    
    self.previewingView.image = backImage;
    
}

#pragma mark - KTMattingPickerViewDelegate

- (void)mattingPickerView:(KTMattingPickerView *)pickerView didSelectMattingMode:(SelectMode)mattingMode {
    
    self.selectMode = mattingMode;
    
    [self updateSubViews];
    
}

- (void)mattingPickerView:(KTMattingPickerView *)pickerView didSelectPreviewMode:(DisplayMode)previewMode {
    
    if (previewMode == DisplayModeEditImage) {
        self.editViewDisplayMode = DisplayModeEditImage;
    }
    else if (previewMode == DisplayModeSourceImage) {
        self.editViewDisplayMode = DisplayModeSourceImage;
    }
    else if (previewMode == DisplayModeSegmentImage) {
        self.previewViewDisplayMode = DisplayModeSegmentImage;
    }
    else if (previewMode == DisplayModeForeground) {
        self.previewViewDisplayMode = DisplayModeForeground;
    }
    
    [self updateSubViews];
}

- (void)mattingPickerView:(KTMattingPickerView *)pickerView didChangeSlideValue:(CGFloat)sliderValue {
    self.brushView.lineWith = sliderValue;
}

#pragma mark - KTListViewDelegate methods

- (void)listView:(KTListView *)listView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    
    
    
    
    
}


@end

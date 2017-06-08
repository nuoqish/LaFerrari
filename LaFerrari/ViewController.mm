//
//  ViewController.m
//  MoguMattor
//
//  Created by longyan on 2016/12/30.
//  Copyright © 2016年 shenyanhao. All rights reserved.
//

#import "ViewController.h"

#import <opencv2/core.hpp>
using namespace cv;

#import "NSImage+Utils.h"
#import "KTMatteProcessor.h"

#import "KTImageView.h"
#import "KTBrushView.h"
#import "KTCropView.h"
#import "KTListView.h"
#import "KTBackgroundPickerView.h"
#import "KTMattingPickerView.h"
#import "KTProgressIndicator.h"

@interface ViewController () <KTCropViewDelegate, KTListViewDelegate , KTBackgroundPickerViewDelegate, KTMattingPickerViewDelegate>

@property (nonatomic, assign) SelectMode selectMode;
@property (nonatomic, assign) DisplayMode editViewDisplayMode;
@property (nonatomic, assign) DisplayMode previewViewDisplayMode;

@property (nonatomic, strong) NSImage *sourceImage;
@property (nonatomic, assign) CGFloat scaleRatio;
@property (nonatomic, assign) CGFloat editingImageViewZoomingScale;
@property (nonatomic, assign) CGSize oldViewFrameSize;
@property (nonatomic, strong) NSMutableArray *brushPoints;
@property (nonatomic, strong) NSMutableArray<NSURL *> *fileUrls;
@property (nonatomic, assign) BOOL showFileListView;
@property (nonatomic, strong) NSMutableDictionary *processInfoMap;
@property (nonatomic, strong) KTMatteProcessor *matteProcessor;

@property (nonatomic, strong) KTImageView *editingView;
@property (nonatomic, strong) NSImageView *maskImageView;
@property (nonatomic, strong) KTImageView *previewingView;
@property (nonatomic, strong) KTBrushView *brushView;
@property (nonatomic, strong) KTCropView *cropView;
@property (nonatomic, strong) KTListView *fileListView;
@property (nonatomic, strong) KTBackgroundPickerView *colorPicker;
@property (nonatomic, strong) KTMattingPickerView *mattingPicker;
@property (nonatomic, strong) NSBox *verticalSeparator;
@property (nonatomic, strong) KTProgressIndicator *progressIndictor;

@end

static const CGFloat kTabbarHeight = 30;
static const CGFloat kMiddleWidth = 2;
static const CGFloat kFileListWidth = 140;
static const CGFloat kBottomIndicatorHeight = 20;


@implementation ViewController

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
    [self setupTimerIfNeeded];
    
    self.sourceImage = [NSImage imageNamed:@"laferrari.jpg"];
    [self.view.window setTitleWithRepresentedFilename:@"LaFerrari"];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutSubviews];
}

- (void)commonInit {
    self.matteProcessor = [KTMatteProcessor new];
    self.processInfoMap = @{}.mutableCopy;
    self.fileUrls = @[].mutableCopy;
    self.oldViewFrameSize = CGSizeZero;
    self.editingImageViewZoomingScale = 1.0;
    self.brushPoints = [[NSMutableArray alloc] init];
    self.brushView.pointsArray = self.brushPoints;
    self.brushView.lineWith = self.mattingPicker.sliderValue;

    
}

- (void)setupTimerIfNeeded {
    // I know this is stupid, but I donot known how to auto layout subviews when people dragging the window
    NSProcessInfo *pInfo = [NSProcessInfo processInfo];
    NSOperatingSystemVersion version = [pInfo operatingSystemVersion];
    if (version.majorVersion <= 10 && version.minorVersion <= 11) {
        [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(layoutSubViewsIfNeeded) userInfo:nil repeats:YES];
    }
}


- (void)initSubViews {
    [self.view addSubview:self.editingView];
    [self.view addSubview:self.previewingView];
    [self.view addSubview:self.mattingPicker];
    
    [self.editingView addCustomView:self.maskImageView];
    [self.editingView addCustomView:self.brushView];
    [self.editingView addCustomView:self.cropView];

}


- (void)layoutSubViewsIfNeeded {
    if (!CGSizeEqualToSize(self.oldViewFrameSize, self.view.frame.size)) {
        self.oldViewFrameSize = self.view.frame.size;
        [self layoutSubviews];
    }
}

- (void)layoutSubviews {
    
    if (self.sourceImage.size.width == 0) {
        return;
    }
    CGSize imageSizeInPixels = [self.sourceImage sizeInPixels];
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat viewHeight = self.view.frame.size.height;
    CGFloat fileListViewWidth = (self.showFileListView ? kFileListWidth : 0);
    
    // 根据图片比例计算视图显示比例，通过editView的magnification属性进行editingImageView图片大小缩放，而editingImageView的frame尺寸不变
    CGFloat editViewMaxWidth = ceil((viewWidth - fileListViewWidth) / 2 - kMiddleWidth);
    CGFloat editViewMaxHeight = viewHeight - kTabbarHeight - kBottomIndicatorHeight;
    CGFloat editViewRatio = editViewMaxWidth / editViewMaxHeight;
    CGFloat imageRatio = imageSizeInPixels.width /imageSizeInPixels.height;
    CGFloat resizeImageWidth, resizeImageHeight;
    if (imageRatio > editViewRatio) {
        resizeImageWidth = editViewMaxWidth;
        resizeImageHeight = ceil(resizeImageWidth / imageRatio);
    }
    else {
        resizeImageHeight = editViewMaxHeight;
        resizeImageWidth = ceil(resizeImageHeight * imageRatio);
    }
    CGFloat editViewWidth = ceil(resizeImageWidth * self.editingImageViewZoomingScale);
    CGFloat editViewHeight = ceil(resizeImageHeight * self.editingImageViewZoomingScale);
    if (editViewWidth > editViewMaxWidth) {
        editViewWidth = editViewMaxWidth;
    }
    if (editViewHeight > editViewMaxHeight) {
        editViewHeight = editViewMaxHeight;
    }
    
    self.scaleRatio = imageSizeInPixels.width / resizeImageWidth;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.verticalSeparator.frame = NSMakeRect(fileListViewWidth + (viewWidth - fileListViewWidth) / 2, 0, 1, viewHeight - kTabbarHeight);
        self.progressIndictor.frame = NSMakeRect(fileListViewWidth, 0, viewWidth - fileListViewWidth, kBottomIndicatorHeight);
        
        if (self.showFileListView) {
            self.fileListView.hidden = NO;
            self.fileListView.frame = NSMakeRect(0, 0, kFileListWidth, viewHeight - kTabbarHeight - 1);
        }
        else {
            self.fileListView.hidden = YES;
        }
        self.mattingPicker.frame = NSMakeRect(0, viewHeight - kTabbarHeight, viewWidth, kTabbarHeight);
        
        self.editingView.frame = NSMakeRect(fileListViewWidth + (editViewMaxWidth - editViewWidth) / 2, kBottomIndicatorHeight + (editViewMaxHeight - editViewHeight) / 2, editViewWidth, editViewHeight);
        self.editingView.magnification = self.editingImageViewZoomingScale;
        self.editingView.maxFrameSize = CGSizeMake(editViewMaxWidth, editViewMaxHeight);
        self.maskImageView.frame = self.editingView.imageFrame;
        self.brushView.frame = self.editingView.imageFrame;
        self.cropView.frame = self.editingView.imageFrame;
        
        self.previewingView.frame = NSMakeRect(fileListViewWidth + editViewMaxWidth + kMiddleWidth * 2 + (editViewMaxWidth - editViewWidth) / 2, kBottomIndicatorHeight + (editViewMaxHeight - editViewHeight) / 2, editViewWidth, editViewHeight);
        self.previewingView.magnification = self.editingImageViewZoomingScale;
        self.previewingView.maxFrameSize = CGSizeMake(editViewMaxWidth, editViewMaxHeight);

    });
    
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
        [_cropView showCloseButton:YES];
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
        _verticalSeparator = [[NSBox alloc] init];
        _verticalSeparator.boxType = NSBoxSeparator;
        [self.view addSubview:_verticalSeparator];
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


- (KTProgressIndicator *)progressIndictor {
    if (!_progressIndictor) {
        _progressIndictor = [[KTProgressIndicator alloc] init];
        
        
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
    self.editingImageViewZoomingScale = 1.0;
    [self layoutSubviews];
    
    self.mattingPicker.mattingMode = SelectModeForegroundTarget;
    self.mattingPicker.previewMode = DisplayModeForeground;
    
    self.editingView.image = sourceImage;
    self.previewingView.image = sourceImage;
    self.maskImageView.image = nil;
    self.maskImageView.hidden = YES;
    self.cropView.hidden = YES;
    
    [self.progressIndictor startAnimation:nil withHintText:@"请稍侯，正在进行抠图处理"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.matteProcessor reset];
        [self.matteProcessor processImage:_sourceImage andMode:MatteModeInitRect andRadius:5];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndictor stopAnimation:nil];
            self.cropView.cropRect = self.matteProcessor.cropRect;
            self.cropView.hidden = NO;
            [self updateSubViews];
        });
        
    });

}

- (void)updateSubViews {
    if (self.editViewDisplayMode == DisplayModeEditImage) {
        self.editingView.image = self.sourceImage;
        NSImage *alpha = self.matteProcessor.alphaImage;
        if (alpha) {
            Vec4b maskForeColor = Vec4b(0,255,0,255);
            Vec4b maskBackColor = Vec4b(255,0,0,255);
            Vec4b maskUnknownColor = Vec4b(128,128,128,128);
            Mat1b mask = [alpha CVGrayscaleMat];
            Mat4b maskColor(mask.rows, mask.cols);
            for (int i = 0; i < mask.rows; i++) {
                for (int j = 0; j < mask.cols; j++) {
                    uint8_t value = mask(i, j);
                    if (value == 255) {
                        maskColor(i,j) = maskForeColor;
                    }
                    else if (value == 0) {
                        maskColor(i,j) = maskBackColor;
                    }
                    else {
                        maskColor(i,j) = maskUnknownColor;
                    }
                }
            }
            self.maskImageView.image = [NSImage imageWithCVMat:maskColor];
            self.maskImageView.hidden = NO;
        }
        self.maskImageView.alphaValue = 0.5;
    }
    else if (self.editViewDisplayMode == DisplayModeSourceImage) {
        self.maskImageView.hidden = YES;
        self.cropView.hidden = YES;
    }
    
    if (self.previewViewDisplayMode == DisplayModeSegmentImage) {
        self.previewingView.image = self.matteProcessor.alphaImage;
        self.colorPicker.hidden = YES;
    }
    else if (self.previewViewDisplayMode == DisplayModeForeground) {
        self.previewingView.image = self.matteProcessor.foregroundImage;
        self.colorPicker.hidden = NO;
    }
}

#pragma mark - Actions

- (void)openImageUrl:(NSURL *)imageUrl {
    
    [self.view.window setTitleWithRepresentedFilename:[imageUrl path]];
    self.showFileListView = NO;
    self.sourceImage = [[NSImage alloc] initWithContentsOfURL:imageUrl];
    
    //[self openImageUrls:@[imageUrl]];
}

- (void)openImageUrls:(NSArray<NSURL *> *)imageUrls {
    [self.fileUrls removeAllObjects];
    [self.fileUrls addObjectsFromArray:imageUrls];
    self.fileListView.fileUrls = self.fileUrls;
    [self.fileListView reloadData];
    self.showFileListView = self.fileUrls.count > 1;
    [self layoutSubviews];

    [self.progressIndictor startAnimation:nil withHintText:@"请稍侯，正在进行抠图处理"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [self.fileUrls enumerateObjectsUsingBlock:^(NSURL * _Nonnull imageUrl, NSUInteger idx, BOOL * _Nonnull stop) {
            
            KTMatteProcessor *matteProcessor = [[KTMatteProcessor alloc] init];
            [matteProcessor processImageWithUrl:imageUrl andMode:MatteModeInitRect andRadius:5];
            [self.processInfoMap setObject:matteProcessor forKey:[imageUrl path]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window setTitleWithRepresentedFilename:[imageUrl path]];
                NSString *text = [NSString stringWithFormat:@"正在进行抠图处理(%zu/%zu): %@", idx + 1, self.fileUrls.count, [imageUrl lastPathComponent]];
                [self.progressIndictor setHintText:text];
                
                NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageUrl];
                _sourceImage = image;
                self.editingImageViewZoomingScale = 1.0;
                [self layoutSubviews];
                self.editingView.image = image;
                self.previewingView.image = matteProcessor.foregroundImage;
                self.maskImageView.hidden = YES;
                self.cropView.cropRect = matteProcessor.cropRect;
                
            });
            
        }];
        self.matteProcessor = [self.processInfoMap objectForKey:self.fileUrls[self.fileUrls.count - 1]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndictor stopAnimation:nil];
        });
    });
    
    
}

- (void)saveImageUrl:(NSURL *)imageUrl {
    NSString *filePath = [imageUrl path];
    if (![filePath hasSuffix:@"png"]) {
        filePath = [filePath stringByAppendingPathExtension:@"png"];
    }
    if (self.previewViewDisplayMode == DisplayModeSegmentImage) {
        [self.matteProcessor.alphaImage saveToFile:filePath];
    }
    else {
        [self.matteProcessor.foregroundImage saveToFile:filePath];
    }
}

- (void)undo {
    [self.matteProcessor undo];
    [self updateSubViews];
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
    
    if (self.selectMode == SelectModeForegroundTarget || self.selectMode == SelectModeBackgroundTarget || self.selectMode == SelectModeUnknownAreaTarget) {
        
        if (!self.matteProcessor.completed || self.selectMode == SelectModeUnknownAreaTarget) {
            [self.brushPoints removeAllObjects];
            [self.brushView setNeedsDisplay:YES];
            return;
        }
        
        NSImage *drawImage = [self.brushView generateMaskWithScale:self.scaleRatio];
        
        if (self.selectMode == SelectModeForegroundTarget) {
            [self.matteProcessor updateMaskWithImage:drawImage andPixelMode:PixelModeForeground];
            
        }
        else if (self.selectMode == SelectModeBackgroundTarget) {
            [self.matteProcessor updateMaskWithImage:drawImage andPixelMode:PixelModeBackground];
        }
        
        [self.progressIndictor startAnimation:nil withHintText:@"请稍侯，正在进行抠图处理"];
        self.view.acceptsTouchEvents = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self.matteProcessor processImage:self.sourceImage andMode:MatteModeEVal andRadius:5];
            
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
        
        [self.progressIndictor startAnimation:nil withHintText:@"请稍侯，正在进行抠图处理"];
        NSImage *drawImage = [self.brushView generateMaskWithScale:self.scaleRatio];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (self.selectMode == SelectModeForegroundFineTuning) {
                [self.matteProcessor updateMaskWithImage:drawImage andPixelMode:PixelModeForeground];
                [self.matteProcessor updateForegroundAndAlphaWithImage:drawImage andPixelMode:PixelModeForeground];
            }
            else if (self.selectMode == SelectModeBackgroundFineTuning) {
                [self.matteProcessor updateMaskWithImage:drawImage andPixelMode:PixelModeBackground];
                [self.matteProcessor updateForegroundAndAlphaWithImage:drawImage andPixelMode:PixelModeBackground];
            }
            else if (self.selectMode == SelectModeUnknownAreaFineTuning){
                [self.matteProcessor updateForegroundAndAlphaWithImage:drawImage andPixelMode:PixelModeUnknown];
                [self.matteProcessor processImage:self.sourceImage andMode:MatteModeCF andRadius:5];
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
    
    [self layoutSubviews];
}

#pragma mark - KTCropViewDelegate

- (void)confirmButtonTappedForCropView:(KTCropView *)cropView {
    
    self.cropView.hidden = YES;
    
    
    if (CGRectEqualToRect(cropView.cropRect, self.matteProcessor.cropRect)) {
        return;
    }
    
    CGRect croprect = self.matteProcessor.cropRect;
    NSLog(@"cropView:(%f,%f,%f,%f),matteProcessor:(%f,%f,%f,%f)", cropView.cropRect.origin.x, cropView.cropRect.origin.y, cropView.cropRect.size.width,cropView.cropRect.size.height,croprect.origin.x, croprect.origin.y, croprect.size.width,croprect.size.height);
    
    self.matteProcessor.cropRect = cropView.cropRect;
    
    [self.progressIndictor startAnimation:nil withHintText:@"请稍侯，正在进行抠图处理"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        [self.matteProcessor processImage:self.sourceImage andMode:MatteModeInitRect andRadius:5];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndictor stopAnimation:nil];
            self.editViewDisplayMode = DisplayModeEditImage;
            [self updateSubViews];
            self.cropView.hidden = YES;
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
    self.cropView.hidden = (mattingMode != SelectModeForegroundTarget);
    
}

- (void)mattingPickerView:(KTMattingPickerView *)pickerView didSelectPreviewMode:(DisplayMode)previewMode {
    
    if (previewMode == DisplayModeEditImage) {
        self.editViewDisplayMode = DisplayModeEditImage;
        self.cropView.hidden = (self.selectMode != SelectModeForegroundTarget);
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
    
    NSArray<NSIndexPath *> *indices = [indexPaths allObjects];
    NSIndexPath *index = indices[0];
    NSURL *imageUrl = self.fileUrls[index.item];
    [self.view.window setTitleWithRepresentedFilename:[imageUrl path]];
    
    KTMatteProcessor *processor = [self.processInfoMap objectForKey:[imageUrl path]];
    if (!processor) {
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageUrl];
        self.sourceImage = image;
    }
    else {
        self.matteProcessor = processor;
        self.editingImageViewZoomingScale = 1.;
        self.cropView.cropRect = processor.cropRect;
        _sourceImage = [[NSImage alloc] initWithContentsOfURL:imageUrl];
        [self layoutSubviews];
        [self updateSubViews];
    }
    
    
    
    
}


@end

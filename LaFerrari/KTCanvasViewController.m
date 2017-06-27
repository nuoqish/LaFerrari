//
//  KTCanvasViewController.m
//  LaFerrari
//
//  Created by stanshen on 17/6/15.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTCanvasViewController.h"

#import "KTSelectionView.h"
#import "KTLayer.h"
#import "KTPath.h"
#import "KTGradient.h"
#import "KTColor.h"
#import "KTInspectableProperties.h"
#import "KTPropertyManager.h"
#import "KTBezierNode.h"
#import "KTCurveFit.h"

@interface KTCanvasViewController ()

@property (nonatomic, strong) KTSelectionView *selectionView;

@property (nonatomic, strong) KTLayer *drawlayer;
@property (nonatomic, strong) KTPropertyManager *propertyManager;
@property (nonatomic, strong) KTPath *tmpPath;
@property (nonatomic, strong) NSMutableArray *points;

@end

@implementation KTCanvasViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self setupDefaults];
    
    _selectionView = [[KTSelectionView alloc] initWithFrame:self.view.bounds];
    self.view = _selectionView;
    
    _points = @[].mutableCopy;
    _drawlayer = [[KTLayer alloc] init];
    _propertyManager = [[KTPropertyManager alloc] init];
    _tmpPath = [[KTPath alloc] initWithRoundedRect:CGRectMake(100, 10, 200, 400) cornerRadius:50];
    
    _tmpPath.fill = [_propertyManager activeFillStyle];
    _tmpPath.strokeStyle = [_propertyManager activeStrokeStyle];
    _tmpPath.opacity = [[_propertyManager defaultValueForProperty:KTOpacityProperty] floatValue];
    _tmpPath.shadow = [_propertyManager activeShadow];
    
    //[_drawlayer addObject:_tmpPath];
    
    _selectionView.activeLayer = _drawlayer;
    
    
}


- (void)mouseDown:(NSEvent *)theEvent {
    NSLog(@"KTCanvasViewController mouseDonw");

    [_points removeAllObjects];
    
    [_points addObject:[NSValue valueWithPoint:theEvent.locationInWindow]];
    
    
    [_selectionView drawView];
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSLog(@"KTCanvasViewController mouseDragged:(%f,%f)",theEvent.locationInWindow.x,theEvent.locationInWindow.y);
    
    
    [_points addObject:[NSValue valueWithPoint:theEvent.locationInWindow]];

    
    [_selectionView drawView];
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"KTCanvasViewController mousedUp");
    
    [_points addObject:[NSValue valueWithPoint:theEvent.locationInWindow]];
    
    float maxError = 10;
    
    
    KTPath *path = [KTCurveFit smoothPathForPoints:_points error:maxError attemptToClose:YES];
    path.fill = [_propertyManager activeFillStyle];
    path.strokeStyle = [_propertyManager activeStrokeStyle];
    path.opacity = [[_propertyManager defaultValueForProperty:KTOpacityProperty] floatValue];
    path.shadow = [_propertyManager activeShadow];
    
    
    
    [_drawlayer addObject:path];
    
    [_selectionView drawView];
}

- (void)setupDefaults {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Defaults.plist"];
    [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:defaultPath]];
    
    // Install valid defaults for various colors/gradients if necessary. These can't be encoded in the Defaults.plist.
    if (![defaults objectForKey:KTStrokeColorProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[KTColor blackColor]];
        [defaults setObject:value forKey:KTStrokeColorProperty];
    }
    
    if (![defaults objectForKey:KTFillProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[KTColor whiteColor]];
        [defaults setObject:value forKey:KTFillProperty];
    }
    
    if (![defaults objectForKey:KTFillColorProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[KTColor whiteColor]];
        [defaults setObject:value forKey:KTFillColorProperty];
    }
    
    if (![defaults objectForKey:KTFillGradientProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[KTGradient defaultGradient]];
        [defaults setObject:value forKey:KTFillGradientProperty];
    }
    
    if (![defaults objectForKey:KTStrokeDashPatternProperty]) {
        NSArray *dashes = @[];
        [defaults setObject:dashes forKey:KTStrokeDashPatternProperty];
    }
    
    if (![defaults objectForKey:KTShadowColorProperty]) {
        NSData *value = [NSKeyedArchiver archivedDataWithRootObject:[KTColor colorWithRed:0 green:0 blue:0 alpha:0.333f]];
        [defaults setObject:value forKey:KTShadowColorProperty];
    }
    
}


@end

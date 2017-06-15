//
//  KTLayer.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "KTDrawing.h"

@class KTElement;
@class KTXMLElement;


// notifications
extern NSString *KTLayerVisibilityChanged;
extern NSString *KTLayerLockedStatusChanged;
extern NSString *KTLayerOpacityChanged;
extern NSString *KTLayerContentsChangedNotification;
extern NSString *KTLayerThumbnailChangedNotification;
extern NSString *KTLayerNameChanged;

@interface KTLayer : NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) NSMutableArray *elements;
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, weak) KTDrawing *drawing;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) float opacity;
@property (nonatomic, readonly) BOOL editable;
@property (nonatomic, readonly) CGRect styleBounds;
#if TARGET_OS_IPHONE
@property (nonatomic, readonly, weak) UIImage *thumbnail;
#else
@property (nonatomic, readonly, weak) NSImage *thumbnail;
#endif
@property (nonatomic, readonly) BOOL isSuppressingNotification;

+ (KTLayer *)layer;

- (id)initWithElements:(NSMutableArray *)elements;
- (void)awakeFromEncoding;

- (void)renderInContext:(CGContextRef)ctx clipRect:(CGRect)clip metaData:(KTRenderingMetaData)metaData;

- (void)addObject:(id)obj;
- (void)addObjects:(NSArray *)objects;
- (void)removeObject:(id)obj;
- (void)insertObject:(KTElement *)element above:(KTElement *)above;

- (void)addElementsToArray:(NSMutableArray *)elements;

- (void)sendBackward:(NSSet *)elements;
- (void)sendToBack:(NSArray *)sortedElements;
- (void)bringForward:(NSSet *)sortedElements;
- (void)bringToFront:(NSArray *)sortedElements;

- (void)invalidateThumbnail;

// draw the layer contents scaled to fit within bounds
#if TARGET_OS_IPHONE
- (UIImage *)previewInRect:(CGRect)bounds;
#else
- (NSImage *)previewInRect:(CGRect)bounds;
#endif
- (void)toggleLocked;
- (void)toggleVisibility;

- (KTXMLElement *)SVGElement;


@end





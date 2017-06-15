//
//  KTElement.h
//  LaFerrari
//
//  Created by stanshen on 17/6/8.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KTDrawing.h"

extern NSString *KTElementChanged;
extern NSString *KTPropertyChangedNotification;
extern NSString *KTPropertiesChangedNotification;

extern NSString *KTPropertyKey;
extern NSString *KTPropertiesKey;
extern NSString *KTTransformKey;
extern NSString *KTFillKey;
extern NSString *KTFillTransformKey;
extern NSString *KTStrokeKey;

extern NSString *KTTextKey;
extern NSString *KTFontNameKey;
extern NSString *KTFontSizeKey;

typedef enum {
    KTAlignLeft,
    KTAlignCenter,
    KTAlignRight,
    KTAlignTop,
    KTAlignMiddle,
    KTAlignBottom
} KTAlignment;

typedef enum {
    KTColorAdjustStroke = 1 << 0,
    KTColorAdjustFill = 1 << 1,
    KTColorAdjustShadow = 1 << 2
} KTColorAdjustmentScope;

@class KTGroup;
@class KTLayer;
@class KTPickResult;
@class KTPropertyManager;
@class KTShadow;
@class KTXMLElement;
@class KTColor;

@interface KTElement : NSObject <NSCoding, NSCopying> 

@property (nonatomic, weak) KTLayer *layer;
@property (nonatomic, weak) KTGroup *group;// point to parent group, if any
@property (nonatomic, assign) float opacity;
@property (nonatomic, assign) CGBlendMode blendMode;
@property (nonatomic, strong) KTShadow *shadow;
@property (nonatomic, strong) KTShadow *initialShadow;
@property (nonatomic, readonly, weak) NSUndoManager *undoManager;
@property (nonatomic, readonly, weak) KTDrawing *drawing;
@property (nonatomic, readonly, weak) NSSet *inspectableProperties;

- (void)awakeFromEncoding;

- (CGRect)bounds;
- (CGRect)styleBounds;
- (KTShadow *)shadowForStyleBounds;
- (CGRect)expandStyleBounds:(CGRect)rect;

- (CGRect)subselectionBounds;
- (void)clearSubselection;

- (BOOL)containsPoint:(CGPoint)point;
- (BOOL) intersectsRect:(CGRect)rect;

- (void)renderInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData;

- (void)cacheDirtyBounds;
- (void)postDirtyBoundsChange;
- (void)tossCachedColorAdjustmentData;
- (void)restoreCachedColorAdjustmentData;
- (void)registerUndoWithCachedColorAdjustmentData;

// OpenGL-based selection rendering
- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect;
- (void) drawOpenGLAnchorAtPoint:(CGPoint)pt transform:(CGAffineTransform)transform selected:(BOOL)selected;
- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;
- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;
- (void) drawOpenGLAnchorsWithViewTransform:(CGAffineTransform)transform;
- (void) drawGradientControlsWithViewTransform:(CGAffineTransform)transform;
- (void) drawTextPathControlsWithViewTransform:(CGAffineTransform)viewTransform viewScale:(float)viewScale;

- (NSSet *) transform:(CGAffineTransform)transform;
- (void)adjustColor:(KTColor * (^)(KTColor *color))adjust scope:(KTColorAdjustmentScope)scope;

- (NSSet *) alignToRect:(CGRect)rect alignment:(KTAlignment)align;


- (KTPickResult *) hitResultForPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags;
- (KTPickResult *) snappedPoint:(CGPoint)pt viewScale:(float)viewScale snapFlags:(int)flags;


- (void) addBlendablesToArray:(NSMutableArray *)array;
- (void) addElementsToArray:(NSMutableArray *)array;

- (KTXMLElement *)SVGElement;
- (void) addSVGOpacityAndShadowAttributes:(KTXMLElement *)element;

- (BOOL) canMaskElements;
- (BOOL) hasEditableText;
- (BOOL) canPlaceText;
- (BOOL) isErasable;
- (BOOL) canAdjustColor;

// inspection
- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(KTPropertyManager *)propertyManager;
- (id) valueForProperty:(NSString *)property;
- (NSSet *) inspectableProperties;
- (BOOL) canInspectProperty:(NSString *)property;
- (void) propertyChanged:(NSString *)property;
- (void) propertiesChanged:(NSSet *)property;
- (id) pathPainterAtPoint:(CGPoint)pt;
- (BOOL) hasFill;

- (BOOL) needsToSaveGState:(float)scale;
- (BOOL) needsTransparencyLayer:(float)scale;

- (void) beginTransparencyLayer:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData;
- (void) endTransparencyLayer:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData;

@end

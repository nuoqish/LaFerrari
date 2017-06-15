//
//  KTLayer.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTLayer.h"

#import "KTElement.h"
#import "KTXMLElement.h"

#import "KTUtilities.h"
#import "KTSVGHelper.h"

NSString *KTLayerVisibilityChanged = @"KTLayerVisibilityChanged";
NSString *KTLayerLockedStatusChanged = @"KTLayerLockedStatusChanged";
NSString *KTLayerOpacityChanged = @"KTlayerOpacityChanged";
NSString *KTLayerContentsChangedNotification = @"KTLayerContentsChangedNotification";
NSString *KTLayerThumbnailChangedNotification = @"KTLayerThumbnailChangedNotification";
NSString *KTLayerNameChanged = @"KTLayerNameChanged";

NSString *KTLayerElementsKey = @"KTElementsKey";
NSString *KTLayerVisibleKey = @"KTVisibleKey";
NSString *KTLayerLockedKey = @"KTLockedKey";
NSString *KTLayerNameKey = @"KTNameKey";
NSString *KTLayerHightlightColorKey = @"KTHightlightColorKey";
NSString *KTLayerOpacityKey = @"KTOpacityKey";

static CGFloat kDefaultThumbnailSize = 50;
static CGFloat kDefaultPreviewInset = 0;

@interface KTLayer ()

@property (nonatomic, strong) NSMutableArray *elements;

@end

@implementation KTLayer

@synthesize thumbnail = _thumbnail;

+ (KTLayer *)layer {
    return [[KTLayer alloc] init];
}

- (instancetype)init {
    NSMutableArray *elements = @[].mutableCopy;
    return [self initWithElements:elements];
}

- (id)copyWithZone:(NSZone *)zone {
    KTLayer *layer = [[KTLayer alloc] init];
    layer.opacity = self.opacity;
    layer.locked = self.locked;
    layer.visible = self.visible;
    layer.name = self.name.copy;
    layer.highlightColor = self.highlightColor;
    layer.elements = [[NSMutableArray alloc] initWithArray:_elements];
    [layer.elements makeObjectsPerformSelector:@selector(setLayer:) withObject:layer];
    
    return layer;
}


- (id)initWithElements:(NSMutableArray *)elements {
    self = [super init];
    if (self) {
        _elements = elements;
        [_elements makeObjectsPerformSelector:@selector(setLayer:) withObject:self];
        self.highlightColor = [NSColor colorWithHue:(random() % 10000) / 10000.f saturation:0.7f brightness:0.75 alpha:1.0];
        self.visible = YES;
        self.opacity = 1.0f;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_elements forKey:KTLayerElementsKey];
    [aCoder encodeConditionalObject:_drawing forKey:KTDrawingKey];
    [aCoder encodeBool:_visible forKey:KTLayerVisibleKey];
    [aCoder encodeBool:_locked forKey:KTLayerLockedKey];
    [aCoder encodeObject:_name forKey:KTLayerNameKey];
    
#if TARGET_OS_IPHONE
    [aCoder encodeObject:_highlightColor forKey:KTHightlightColorKey];
#endif
    
    if (_opacity != 1.0f) {
        [aCoder encodeFloat:_opacity forKey:KTLayerOpacityKey];
    }
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    _elements = [aDecoder decodeObjectForKey:KTLayerElementsKey];
    _drawing = [aDecoder decodeObjectForKey:KTDrawingKey];
    _visible = [aDecoder decodeBoolForKey:KTLayerVisibleKey];
    _locked = [aDecoder decodeBoolForKey:KTLayerLockedKey];
    self.name = [aDecoder decodeObjectForKey:KTLayerNameKey];
#if TARGET_OS_IPHONE
    self.highlightColor = [aDecoder decodeObjectForKey:KTHightlightColorKey];
#endif
    
    if ([aDecoder containsValueForKey:KTLayerOpacityKey]) {
        self.opacity = [aDecoder decodeFloatForKey:KTLayerOpacityKey];
    }
    else {
        self.opacity = 1.0f;
    }
    
    if (!self.highlightColor) {
        self.highlightColor = [NSColor colorWithHue:(random() % 10000) / 10000.f saturation:0.7f brightness:0.75 alpha:1.0];
    }
    
    return self;
}

- (void)awakeFromEncoding {
    [_elements makeObjectsPerformSelector:@selector(awakeFromEncoding) withObject:nil];
}

- (BOOL)isSuppressingNotification {
    if (!_drawing || _drawing.isSuppressingNotifications) {
        return YES;
    }
    return NO;
}

- (void)renderInContext:(CGContextRef)ctx clipRect:(CGRect)clip metaData:(KTRenderingMetaData)metaData {
    
    BOOL useTransparentcyLayer = (!KTRenderingMetaDataOutlineOnly(metaData) && _opacity != 1.0f) ? YES : NO;
    
    if (useTransparentcyLayer) {
        CGContextSaveGState(ctx);
        CGContextSetAlpha(ctx, _opacity);
        CGContextBeginTransparencyLayer(ctx, NULL);
    }
    
    for (KTElement *element in _elements) {
        if (CGRectIntersectsRect([element styleBounds], clip)) {
            [element renderInContext:ctx metaData:metaData];
        }
    }
    
    if (useTransparentcyLayer) {
        CGContextEndTransparencyLayer(ctx);
        CGContextRestoreGState(ctx);
    }
}

- (void)setOpacity:(float)opacity {
    if (_opacity == opacity) {
        return;
    }
    
    [[self.drawing.undoManager prepareWithInvocationTarget:self] setOpacity:_opacity];
    _opacity = KTClamp(0.0f, 1.0f, opacity);
    
    if (!self.isSuppressingNotification) {
        NSDictionary *usefInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:self.styleBounds]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerOpacityChanged object:self.drawing userInfo:usefInfo];
    }
}

- (KTXMLElement *)SVGElement {
    
    if (_elements.count == 0) {
        return nil;
    }
    
    KTXMLElement *layer = [KTXMLElement elementWithName:@"g"];
    
    NSString *uniqueName = [[KTSVGHelper sharedSVGHelper] uniqueIDWithPrefix:[@"Layer$" stringByAppendingString:_name]];
    [layer setAttribute:@"id" value:[uniqueName substringFromIndex:6]];
    [layer setAttribute:@"kato:layerName" value:_name];
    
    if (self.hidden) {
        [layer setAttribute:@"visibility" value:@"hidden"];
    }
    if (self.opacity != 1.0f) {
        [layer setAttribute:@"opacity" floatValue:_opacity];
    }
    
    for (KTElement *element in _elements) {
        [layer addChild:[element SVGElement]];
    }
    
    
    return layer;
}

- (void)addElementsToArray:(NSMutableArray *)elements {
    [_elements makeObjectsPerformSelector:@selector(addElementsToArray:) withObject:elements];
}

- (void)addObject:(KTElement *)obj {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] removeObject:obj];
    
    [_elements addObject:obj];
    obj.layer = self;
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:obj.styleBounds]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerContentsChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (void)addObjects:(NSArray *)objects {
    for (KTElement *element in objects) {
        [self addObject:element];
    }
}

- (void)removeObject:(KTElement *)obj {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] insertObject:obj atIndex:[_elements indexOfObject:obj]];
    
    [_elements removeObject:obj];
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:obj.styleBounds]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerContentsChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (void)insertObject:(KTElement *)element atIndex:(NSUInteger)index {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] removeObject:element];
    
    element.layer = self;
    [_elements insertObject:element atIndex:index];
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:element.styleBounds]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerContentsChangedNotification object:self.drawing userInfo:userInfo];
    }
    
}


- (void)insertObject:(KTElement *)element above:(KTElement *)above {
    [self insertObject:element atIndex:[_elements indexOfObject:above]];
}

- (void)exchangeObjectAtIndex:(NSUInteger)srcIndex withObjectAtIndex:(NSUInteger)dstIndex {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] exchangeObjectAtIndex:srcIndex withObjectAtIndex:dstIndex];
    
    [_elements exchangeObjectAtIndex:srcIndex withObjectAtIndex:dstIndex];
    
    KTElement *srcElement = _elements[srcIndex];
    KTElement *dstElement = _elements[dstIndex];
    
    CGRect dirtyRect = CGRectIntersection(srcElement.styleBounds, dstElement.styleBounds);
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:dirtyRect]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerContentsChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (void)sendBackward:(NSSet *)elements {
    NSInteger top = _elements.count;
    for (int i = 1; i < top; i++) {
        KTElement *curr = (KTElement *)_elements[i];
        KTElement *below = (KTElement *)_elements[i - 1];
        
        if ([elements containsObject:curr] && ![elements containsObject:below]) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:(i - 1)];
        }
    }
}

- (void)sendToBack:(NSArray *)sortedElements {
    for (KTElement *element in [sortedElements reverseObjectEnumerator]) {
        [self removeObject:element];
        [self insertObject:element atIndex:0];
    }
}

- (void)bringForward:(NSSet *)sortedElements {
    NSInteger top = _elements.count - 1;
    for (NSInteger i = top - 1; i >= 0; i--) {
        KTElement *curr = (KTElement *)_elements[i];
        KTElement *above = (KTElement *)_elements[i + 1];
        if ([sortedElements containsObject:curr] && ![sortedElements containsObject:above]) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:(i + 1)];
        }
    }
}

- (void)bringToFront:(NSArray *)sortedElements {
    NSInteger top = _elements.count - 1;
    
    for (KTElement *element in sortedElements) {
        [self removeObject:element];
        [self insertObject:element atIndex:top];
    }
}

- (CGRect)styleBounds {
    CGRect styleBounds = CGRectNull;
    for (KTElement *element in _elements) {
        styleBounds = CGRectUnion(styleBounds, element.styleBounds);
    }
    return styleBounds;
}

- (void)notifyThumbnailChanged:(id)object {
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerThumbnailChangedNotification object:self.drawing userInfo:userInfo];
    }
}

- (void)invalidateThumbnail {
    if (!_thumbnail) {
        return;
    }
    _thumbnail = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyThumbnailChanged:) object:nil];
    [self performSelector:@selector(notifyThumbnailChanged:) withObject:nil afterDelay:0];
}

#if TARGET_OS_IPHONE
- (UIImage *)thumbnail {
#else
- (NSImage *)thumbnail {
#endif
    if (!_thumbnail) {
        _thumbnail = [self previewInRect:CGRectMake(0, 0, kDefaultThumbnailSize, kDefaultThumbnailSize)];
    }
    return _thumbnail;
}

#if TARGET_OS_IPHONE
- (UIImage *)previewInRect:(CGRect)bounds {
#else
- (NSImage *)previewInRect:(CGRect)bounds {
#endif
    
    CGRect contentBounds = self.styleBounds;
    
    float contentAspect = CGRectGetWidth(contentBounds) / CGRectGetHeight(contentBounds);
    float destAspect = CGRectGetWidth(bounds) / CGRectGetHeight(bounds);
    float scaleFactor = 1.0f;
    CGPoint offset = CGPointZero;
    
#if TARGET_OS_IPHONE
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 0);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
#else
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t imageWidth = bounds.size.width;
    size_t imageHeight = bounds.size.height;
    size_t bitmapBytesPerRow = (imageWidth * 4);
    
    CGContextRef contextRef = CGBitmapContextCreate(NULL,
                                       imageWidth,
                                       imageHeight ,
                                       8,
                                       bitmapBytesPerRow,
                                       colorspace,
                                       (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
#endif
    bounds = CGRectInset(bounds, kDefaultPreviewInset, kDefaultPreviewInset);
    if (contentAspect > destAspect) {
        scaleFactor = CGRectGetWidth(bounds) / CGRectGetWidth(contentBounds);
        offset.y = (CGRectGetHeight(bounds) - scaleFactor * CGRectGetHeight(contentBounds)) / 2;
    }
    else {
        scaleFactor = CGRectGetHeight(bounds) / CGRectGetHeight(contentBounds);
        offset.x = (CGRectGetWidth(bounds) - scaleFactor * CGRectGetWidth(contentBounds)) / 2;
    }
    
    // scale and offset the layer contents to render in the new image
    CGContextSaveGState(contextRef);
    CGContextTranslateCTM(contextRef, offset.x + kDefaultPreviewInset, offset.y + kDefaultPreviewInset);
    CGContextScaleCTM(contextRef, scaleFactor, scaleFactor);
    CGContextTranslateCTM(contextRef, -contentBounds.origin.x, -contentBounds.origin.y);
    
    for (KTElement *element in _elements) {
        [element renderInContext:contextRef metaData:KTRenderingMetaDataMake(scaleFactor, KTRenderThumbnail)];
    }
    CGContextRestoreGState(contextRef);
#if TARGET_OS_IPHONE
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#else
    CGImageRef imageRef = CGBitmapContextCreateImage(contextRef);
    NSImage *result = [[NSImage alloc] initWithCGImage:imageRef size: NSZeroSize];
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorspace);
#endif
    
    return result;
}

    
- (void)toggleLocked {
    self.locked = !self.locked;
}
    
- (void)toggleVisibility {
    self.visible = !self.visible;
}
    
- (BOOL)editable {
    return (!self.locked && self.visible);
}
    
- (BOOL)hidden {
    return self.visible;
}

- (void)setHidden:(BOOL)hidden {
    self.visible = !hidden;
}
    
- (void)setVisible:(BOOL)visible {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] setVisible:_visible];
    _visible = visible;
    
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self, @"rect":[NSValue valueWithRect:self.styleBounds]};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerVisibilityChanged object:self.drawing userInfo:userInfo];
    }
}

- (void)setLocked:(BOOL)locked {
    [[self.drawing.undoManager prepareWithInvocationTarget:self] setLocked:_locked];
    _locked = locked;
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerLockedStatusChanged object:self.drawing userInfo:userInfo];
    }
}
    
- (void)setName:(NSString *)name {
    [(KTLayer *)[self.drawing.undoManager prepareWithInvocationTarget:self] setName:_name];
    _name = name;
    if (!self.isSuppressingNotification) {
        NSDictionary *userInfo = @{@"layer":self};
        [[NSNotificationCenter defaultCenter] postNotificationName:KTLayerNameChanged object:self.drawing userInfo:userInfo];
    }
}
    
@end

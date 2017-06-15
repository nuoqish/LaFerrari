//
//  KTText.h
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "KTStylable.h"

#import "KTTextRenderer.h"

@interface KTText : KTStylable <NSCopying, NSCoding, KTTextRenderer>

@property (nonatomic, assign) float width;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) NSTextAlignment alignment;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, readonly) CGRect naturalBounds;
@property (nonatomic, readonly) CTFontRef fontRef;
@property (nonatomic, readonly, strong) NSAttributedString *attributedString;

+ (float) minimumWidth;
- (void)moveHandle:(NSUInteger)handle toPoint:(CGPoint)point;
- (void)cacheOriginalText;
- (void)registerUndoWithCachedText;
- (void)cacheTransformAndWidth;
- (void)registerUndoWithCachedTransformAndWidth;

// an array of KTPath objects representing each glyph in the text object
- (NSArray *)outlines;

- (void)drawOpenGLTextOutlinesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform;

- (void)setWidthQuiet:(float)width;
- (void)setFontNameQuiet:(NSString *)fontName;
- (void)setFontSizeQuiet:(float)fontSize;
- (void)setTextQuiet:(NSString *)text;
- (void)setTransformQuiet:(CGAffineTransform)transform;

@end

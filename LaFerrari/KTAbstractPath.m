//
//  KTAbstractPath.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTAbstractPath.h"

#import "KTPath.h" //?

#import "KTCompoundPath.h"
#import "KTStrokeStyle.h"
#import "KTLayer.h"
#import "KTColor.h"
#import "KTArrowhead.h"
#import "KTPathFinder.h"
#import "KTXMLElement.h"
#import "KTSVGHelper.h"
#import "KTUtilities.h"

NSString *KTFillRuleKey = @"KTFillRuleKey";

@implementation KTAbstractPath

+ (KTAbstractPath *)pathWithCGPathRef:(CGPathRef)pathRef {
    //? KTPath KTCompoundPath不该在这里
    NSMutableArray *subpaths = [NSMutableArray array];
    
    CGPathApply(pathRef, (__bridge void *)(subpaths), &KTPathApplyAccumulateElement);
    
    if (subpaths.count == 1) {
        // single path
        return [subpaths lastObject];
    } else {
        KTCompoundPath *cp = [[KTCompoundPath alloc] init];
        [cp setSubpathsQuiet:subpaths];
        return cp;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fillRule = KTFillRuleEvenOdd;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _fillRule = (int)[aDecoder decodeIntegerForKey:KTFillRuleKey];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:_fillRule forKey:KTFillRuleKey];
}

- (id)copyWithZone:(NSZone *)zone {
    KTAbstractPath *ap = [super copyWithZone:zone];
    ap.fillRule = self.fillRule;
    return ap;
}


- (CGPathRef)path {
    return NULL; // implemented by subclass
}

- (CGPathRef)strokePath {
    return NULL; // implemented by subclass
}

- (BOOL)containsPoint:(CGPoint)point {
    return CGPathContainsPoint(self.path, NULL, point, false);
}

- (void)renderStrokeInContext:(CGContextRef)ctx {
    CGContextAddPath(ctx, self.strokePath);
    [self.strokeStyle applyInContext:ctx];
    CGContextStrokePath(ctx);
}

- (void)renderInContext:(CGContextRef)ctx metaData:(KTRenderingMetaData)metaData {
    
    if (metaData.flags & KTRenderOutlineOnly) {
        CGContextAddPath(ctx, self.path);
        CGContextStrokePath(ctx);
    }
    else if ([self.strokeStyle willRender] || self.fill || self.maskedElements) {
        
        [self beginTransparencyLayer:ctx metaData:metaData];
        
        if (self.fill) {
            [self.fill paintPath:self inContext:ctx];
        }
        
        if (self.maskedElements) {
            CGContextSaveGState(ctx);
            CGContextAddPath(ctx, self.path);
            CGContextClip(ctx); // clip to the mask boundary
            
            for (KTElement *element in self.maskedElements) {
                [element renderInContext:ctx metaData:metaData];
            }
            CGContextRestoreGState(ctx);
        }
        
        if (self.strokeStyle && [self.strokeStyle willRender]) {
            [self renderStrokeInContext:ctx];
        }
        
        [self endTransparencyLayer:ctx metaData:metaData];
    }
    
}

- (NSString *)nodeSVGRepresentation {
    return nil;
}

- (void)addSVGArrowHeadsToGroup:(KTXMLElement *)group {
    
}

- (KTXMLElement *)SVGElement {
    
    BOOL isMask = (self.maskedElements && [self.maskedElements count] > 0);
    BOOL hasArrow = self.strokeStyle && [self.strokeStyle hasArrow] && !CGPathEqualToPath(self.path, self.strokePath);
    
    KTXMLElement *basePath = [KTXMLElement elementWithName:@"path"];
    [basePath setAttribute:@"d" value:[self nodeSVGRepresentation]];
    if (self.fill && self.fillRule == KTFillRuleEvenOdd) {
        [basePath setAttribute:@"fill-rule" value:@"evenodd"];
    }
    
    if (!isMask && !hasArrow) {
        // this just a normal shape
        [self addSVGOpacityAndShadowAttributes:basePath];
        [self addSVGFillAndStrokeAttributes:basePath];
        
        return basePath;
    }
    
    // we're either a mask or we have arrowheads (or both)... either way, we need a group
    KTXMLElement *group = [KTXMLElement elementWithName:@"g"];
    [self addSVGOpacityAndShadowAttributes:group];
    
    if (isMask) {
        // Produces an element such as:
        // <defs>
        //   <path id="MaskN" d="..."/>
        // </defs>
        // <g opacity="..." inkpad:shadowColor="..." inkpad:mask="#MaskN">
        //   <use xlink:href="#MaskN" fill="..."/>
        //   <clipPath id="ClipPathN">
        //     <use xlink:href="#MaskN" overflow="visible"/>
        //   </clipPath>
        //   <g clip-path="url(#ClipPathN)">
        //     <!-- clipped elements -->
        //   </g>
        //   <use xlink:href="#MaskN" stroke="..."/>
        // </g>
        NSString    *uniqueMask = [[KTSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"Mask"];
        NSString    *uniqueClip = [[KTSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"ClipPath"];
        
        [basePath setAttribute:@"id" value:uniqueMask];
        [[KTSVGHelper sharedSVGHelper] addDefinition:basePath];
        
        [group setAttribute:@"inkpad:mask" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
        
        if (self.fill) {
            // add a path for the fill
            KTXMLElement *use = [KTXMLElement elementWithName:@"use"];
            [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
            [use setAttribute:@"stroke" value:@"none"];
            [self addSVGFillAttributes:use];
            [group addChild:use];
        }
        
        KTXMLElement *clipPath = [KTXMLElement elementWithName:@"clipPath"];
        [clipPath setAttribute:@"id" value:uniqueClip];
        
        KTXMLElement *use = [KTXMLElement elementWithName:@"use"];
        [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
        [use setAttribute:@"overflow" value:@"visible"];
        [use setAttribute:@"fill" value:@"none"];
        [clipPath addChild:use];
        [group addChild:clipPath];
        
        KTXMLElement *elements = [KTXMLElement elementWithName:@"g"];
        [elements setAttribute:@"clip-path" value:[NSString stringWithFormat:@"url(#%@)", uniqueClip]];
        for (KTElement *element in self.maskedElements) {
            [elements addChild:[element SVGElement]];
        }
        [group addChild:elements];
        
        if (self.strokeStyle && !hasArrow) {
            // add a path for the stroke
            KTXMLElement *use = [KTXMLElement elementWithName:@"use"];
            [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
            [use setAttribute:@"fill" value:@"none"];
            [self.strokeStyle addSVGAttributes:use];
            [group addChild:use];
        }
    }
    
    if (hasArrow) {
        if (!isMask && self.fill) {
            // add the fill path
            [self addSVGFillAttributes:basePath];
            [group addChild:basePath];
        }
        
        KTXMLElement *strokeGroup = [KTXMLElement elementWithName:@"g"];
        
        KTXMLElement *strokePath = [KTXMLElement elementWithName:@"path"];
        [strokePath setAttribute:@"fill" value:@"none"];
        [self.strokeStyle addSVGAttributes:strokePath];
        
        if (self.strokeStyle.color.alpha != 1.0) {
            [strokePath.attributes removeObjectForKey:@"stroke-opacity"];
            [strokeGroup setAttribute:@"opacity" floatValue:self.strokeStyle.color.alpha];
        }
        
        KTAbstractPath *path = [KTAbstractPath pathWithCGPathRef:self.strokePath];
        [strokePath setAttribute:@"d" value:[path nodeSVGRepresentation]];
        [strokeGroup addChild:strokePath];
        
        [self addSVGArrowHeadsToGroup:strokeGroup];
        [group addChild:strokeGroup];
    }
    
    return group;
}

- (NSUInteger)subpathCount {
    return 1;
}

- (void)addElementsToOutlinedStroke:(CGMutablePathRef)pathRef {
    // override by subclass
}

- (KTAbstractPath *)outlineStroke {
    
    if (!self.strokeStyle || ![self.strokeStyle willRender]) {
        return nil;
    }
    
    CGRect              mediaBox = self.styleBounds;
    CFMutableDataRef	data = CFDataCreateMutable(NULL, 0);
    CGDataConsumerRef	consumer = CGDataConsumerCreateWithCFData(data);
    CGContextRef        ctx = CGPDFContextCreate(consumer, &mediaBox, NULL);
    CGMutablePathRef    mutableOutline;
    
    CGDataConsumerRelease(consumer);
    CGPDFContextBeginPage(ctx, NULL);
    
    [self.strokeStyle applyInContext:ctx];
    CGContextAddPath(ctx, self.strokePath);
    CGContextReplacePathWithStrokedPath(ctx);
    CGPathRef outline = CGContextCopyPath(ctx);
    
    CGPDFContextEndPage(ctx);
    CGContextRelease(ctx);
    CFRelease(data);
    
    if (CGPathIsEmpty(outline)) {
        CGPathRelease(outline);
        return nil;
    } else {
        mutableOutline = CGPathCreateMutableCopy(outline);
        CGPathRelease(outline);
    }
    
    [self addElementsToOutlinedStroke:mutableOutline];
    KTAbstractPath *result = [KTAbstractPath pathWithCGPathRef:mutableOutline];
    [result simplify];
    CGPathRelease(mutableOutline);
    
    // remove self intersections
    if (result) {
        result = [KTPathFinder combinePaths:@[result, [KTPath pathWithRect:result.styleBounds]] operation:KTPathFinderOperationIntersect]; //? KTPath不该在这里
    }
    
    return result;
    
}

- (void)simplify {
    // implement by concrete subclasses
}

- (void)flatten {
    
}

- (KTAbstractPath *)pathByFlatteningPath {
    return nil;
}

- (NSArray *)erase:(KTAbstractPath *)erasePath {
    return nil;
}

- (BOOL)isErasable {
    return YES;
}

- (BOOL)canOutlineStroke {
    return (self.strokeStyle && [self.strokeStyle willRender]);
}


@end

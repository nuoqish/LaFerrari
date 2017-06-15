//
//  KTFillTransform.m
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTFillTransform.h"

NSString *KTFillTransformStartKey = @"KTFillTransformStartKey";
NSString *KTFillTransformEndKey = @"KTFillTransformEndKey";
NSString *KTFillTransformTransformKey = @"KTFillTransformTransformKey";

@interface KTFillTransform ()

@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGPoint start;
@property (nonatomic, assign) CGPoint end;

@end


@implementation KTFillTransform

+ (KTFillTransform *)fillTransformWithRect:(CGRect)rect centered:(BOOL)centered {
    float startX = centered ? CGRectGetMidX(rect) : CGRectGetMinX(rect);
    CGPoint start = CGPointMake(startX, CGRectGetMidY(rect));
    CGPoint end = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
    
    KTFillTransform *fT = [[KTFillTransform alloc] initWithTransform:CGAffineTransformIdentity start:start end:end];
    return fT;
}

- (id)initWithTransform:(CGAffineTransform)transform start:(CGPoint)start end:(CGPoint)end {
    self = [super init];
    
    if (self) {
        self.transform = transform;
        self.start = start;
        self.end = end;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodePoint:_start forKey:KTFillTransformStartKey];
    [aCoder encodePoint:_end forKey:KTFillTransformEndKey];
    [aCoder encodeObject:[NSValue valueWithBytes:&_transform objCType:@encode(CGAffineTransform)] forKey:KTFillTransformTransformKey]; //?
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    
    _start = [aDecoder decodePointForKey:KTFillTransformStartKey];
    _end = [aDecoder decodePointForKey:KTFillTransformEndKey];
    NSValue *value = [aDecoder decodeObjectForKey:KTFillTransformTransformKey];
    [value getValue:&_transform];
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (BOOL)isDefaultInRect:(CGRect)rect centered:(BOOL)centered {
    return [self isEqual:[KTFillTransform fillTransformWithRect:rect centered:centered]];
}

- (BOOL)isEqual:(KTFillTransform *)fillTransform {
    if (fillTransform == self) {
        return YES;
    }
    if (!fillTransform || ![fillTransform isKindOfClass:[KTFillTransform class]]) {
        return NO;
    }
    
    return (CGPointEqualToPoint(self.start, fillTransform.start) &&
            CGPointEqualToPoint(self.end, fillTransform.end) &&
            CGAffineTransformEqualToTransform(self.transform, fillTransform.transform));
    
}

- (KTFillTransform *)transform:(CGAffineTransform)transform {
    CGAffineTransform modified = CGAffineTransformConcat(self.transform, transform);
    KTFillTransform *new = [[KTFillTransform alloc] initWithTransform:modified start:self.start end:self.end];
    return new;
}

- (KTFillTransform *)transformWithTransformedStart:(CGPoint)start {
    CGAffineTransform inverted = CGAffineTransformInvert(self.transform);
    start = CGPointApplyAffineTransform(start, inverted);
    KTFillTransform *new = [[KTFillTransform alloc] initWithTransform:self.transform start:start end:self.end];
    return new;
}

- (KTFillTransform *)transformWithTransformedEnd:(CGPoint)end {
    CGAffineTransform inverted = CGAffineTransformInvert(self.transform);
    end = CGPointApplyAffineTransform(end, inverted);
    KTFillTransform *new = [[KTFillTransform alloc] initWithTransform:self.transform start:self.start end:end];
    return new;
}

- (CGPoint)transformedStart {
    return CGPointApplyAffineTransform(self.start, self.transform);
}

- (CGPoint)transformedEnd {
    return CGPointApplyAffineTransform(self.end, self.transform);
}

@end

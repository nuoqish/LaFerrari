//
//  KTText.m
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTText.h"

#import "KTColor.h"
#import "KTFillTransform.h"
#import "KTFontManager.h"
#import "KTUtilities.h"
#import "KTGLUtilities.h"

NSString *KTTextWidthKey = @"KTWidthKey";
NSString *KTTextAlignementKey = @"KTTextAlignmentKey";

@interface KTText ()

@property (nonatomic, assign) CTFontRef fontRef;
@property (nonatomic, assign) BOOL naturalBoundsIsDirty;
@property (nonatomic, assign) BOOL needsLayout;
@end

@implementation KTText

- (id)copyWithZone:(NSZone *)zone {
    KTText *text = [super copyWithZone:zone];
    
    text.width = _width;
    text.transform = _transform;
    text.alignment = _alignment;
    text.text = _text.copy;
    text.fontName = _fontName.copy;
    text.fontSize = _fontSize;
    text.needsLayout = YES;
    text.naturalBoundsIsDirty = YES;
    
    return text;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    _width = [aDecoder decodeFloatForKey:KTTextWidthKey];
    _text = [aDecoder decodeObjectForKey:KTTextKey];
    _fontName = [aDecoder decodeObjectForKey:KTFontNameKey];
    _fontSize = [aDecoder decodeFloatForKey:KTFontSizeKey];
    _alignment = [aDecoder decodeInt32ForKey:KTTextAlignementKey];
    NSValue *value = [aDecoder decodeObjectForKey:KTTransformKey];
    [value getValue:&_transform];
    
    if ([[KTFontManager sharedInstance] validFont:_fontName]) {
        _fontName = @"Helvetica";
    }
    _needsLayout = YES;
    _naturalBoundsIsDirty = YES;
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeFloat:_width forKey:KTTextWidthKey];
    [aCoder encodeObject:_text forKey:KTTextKey];
    [aCoder encodeObject:_fontName forKey:KTFontNameKey];
    [aCoder encodeFloat:_fontSize forKey:KTFontSizeKey];
    [aCoder encodeInt32:_alignment forKey:KTTextAlignementKey];
    [aCoder encodeObject:[NSValue valueWithBytes:&_transform objCType:@encode(CGAffineTransform)] forKey:KTTransformKey];//?
    
}

+ (float)minimumWidth {
    return kKTTextMinWidth;
}

- (CTFontRef)fontRef {
    if (!_fontRef) {
        _fontRef = [[KTFontManager sharedInstance] newFontRefForFont:_fontName withSize:_fontSize provideDefault:YES];
    }
    return _fontRef;
}







@end

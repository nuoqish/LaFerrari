//
//  KTUserFont.m
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTUserFont.h"
#import "KTUtilities.h"

@implementation KTUserFont

- (void)dealloc {
    if (_fontRef) {
        CFRelease(_fontRef);
        _fontRef = NULL;
    }
}

+ (KTUserFont *)userFontWithFileName:(NSString *)fileName {
    return [[KTUserFont alloc] initWithFileName:fileName];
}

- (id)initWithFileName:(NSString *)fileName {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    // load the font
    NSData *data = [[NSData alloc] initWithContentsOfFile:fileName];
    CGDataProviderRef fontProvider = CGDataProviderCreateWithCFData((CFDataRef)data);
    self.digest = KTSHA1DigestForData(data);
    CGFontRef cgFont = CGFontCreateWithDataProvider(fontProvider);
    CGDataProviderRelease(fontProvider);
    if (cgFont) {
        self.fontRef = CTFontCreateWithGraphicsFont(cgFont, kKTDefaultFontSize, NULL, NULL);
        CGFontRelease(cgFont);
    }
    if (!self.fontRef) {
        NSLog(@"could not load font: %@", fileName);
        return nil;
    }
    
    self.filePath = fileName;
    
    CFStringRef displayNameRef = CTFontCopyDisplayName(self.fontRef);
    self.displayName = (__bridge NSString *)displayNameRef;
    CFRelease(displayNameRef);
    
    CFStringRef fullNameRef = CTFontCopyFullName(self.fontRef);
    self.fullName = (__bridge NSString *)fullNameRef;
    CFRelease(fullNameRef);
    
    CFStringRef familyNameRef = CTFontCopyFamilyName(self.fontRef);
    self.familyName = (__bridge NSString *)familyNameRef;
    CFRelease(familyNameRef);
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@; %@; %@; %@", [super description], _fontRef, _displayName, _fullName, _filePath];
}

- (CTFontRef)newFontRefForSize:(CGFloat)size {
    if (CTFontGetSize(_fontRef) != size) {
        CTFontRef newFontRef = CTFontCreateCopyWithAttributes(_fontRef, size, NULL, NULL);
        if (_fontRef) {
            CFRelease(_fontRef);
        }
        _fontRef = newFontRef;
    }
    CFRetain(_fontRef);
    return _fontRef;
}

@end

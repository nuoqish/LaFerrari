//
//  KTFontManager.m
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "KTFontManager.h"
#import "KTUserFont.h"
#import "KTUtilities.h"

NSString *KTFontAddedNotification = @"KTFontAddedNotification";
NSString *KTFontDeletedNotification = @"KTFontDeletedNotification";

@interface KTFontManager ()

@property (nonatomic, strong) NSArray *systemFonts;
@property (nonatomic, strong) NSArray *userFonts;
@property (nonatomic, strong) NSArray *supportedFonts;
@property (nonatomic, strong) NSArray *supportedFamilies;

@end

@implementation KTFontManager

+ (KTFontManager *)sharedInstance {
    static KTFontManager *sharedInstance_ = nil;
    if (!sharedInstance_) {
        sharedInstance_ = [[KTFontManager alloc] init];
    }
    return sharedInstance_;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        // create the user font dir if necessary
        [[NSFileManager defaultManager] createDirectoryAtPath:[self pathForUserLibrary] withIntermediateDirectories:YES attributes:nil error:NULL];
        [self loadAllFonts];
    }
    
    return self;
}

- (dispatch_queue_t)fontQueue {
    static dispatch_queue_t fontLoadingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fontLoadingQueue = dispatch_queue_create("com.shenyanhao.kato.font", DISPATCH_QUEUE_SERIAL);
    });
    return fontLoadingQueue;
}

- (void)loadAllFonts {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async([self fontQueue], ^{
            // 加载系统字体
            _systemFontMap = @{}.mutableCopy;
            _systemFamilyMap = @{}.mutableCopy;
            NSArray *fontNames = [[NSFontManager sharedFontManager] availableFonts];
            for (NSString *fontName in fontNames) {
                CTFontRef font = CTFontCreateWithName((CFStringRef)fontName, kKTDefaultFontSize, NULL);
                CFStringRef displayName = CTFontCopyDisplayName(font);
                CFStringRef familyName = CTFontCopyFamilyName(font);
                
                _systemFontMap[fontName] = (__bridge NSString *)displayName;
                _systemFamilyMap[fontName] = (__bridge NSString *)familyName;
                
                CFRelease(displayName);
                CFRelease(familyName);
                CFRelease(font);
            }
            
            _systemFonts = [[_systemFontMap allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)].mutableCopy;
            
            // 加载用户字体
            _userFontMap = @{}.mutableCopy;
            _userFamilyMap = @{}.mutableCopy;
            for (NSString *fontPath in [self userLibraryFontPaths]) {
                KTUserFont *userFont = [KTUserFont userFontWithFileName:fontPath];
                if (userFont) {
                    _userFontMap[userFont.fullName] = userFont;
                    _userFamilyMap[userFont.familyName] = userFont.familyName;
                }
            }
        });
    });
}

- (void)waitForInitialLoad {
    // make sure the fonts are loaded, shoud be done at app lauch
    dispatch_async([self fontQueue], ^{
        [self loadAllFonts];
    });
    
    // wait for load
    dispatch_async([self fontQueue], ^{
        
    });
}

- (NSArray *)systemFonts {
    [self waitForInitialLoad];
    return _systemFonts;
}

- (NSArray *)supportedFonts {
    [self waitForInitialLoad];
    
    if (!_supportedFonts) {
        NSMutableSet *combined = [NSMutableSet setWithArray:self.systemFonts];
        [combined addObjectsFromArray:self.userFonts];
        _supportedFonts = [[combined allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    return _supportedFonts;
}

- (NSArray *)supportedFamilies {
    [self waitForInitialLoad];
    
    if (!_supportedFamilies) {
        NSMutableSet *families = [NSMutableSet setWithArray:[self.systemFamilyMap allValues]];
        [families addObjectsFromArray:[self.userFamilyMap allValues]];
        _supportedFamilies = [[families allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    return _supportedFamilies;
}

- (BOOL)isUserFont:(NSString *)fullName {
    [self waitForInitialLoad];
    return self.userFontMap[fullName] ? YES : NO;
}

- (BOOL)validFont:(NSString *)fullName {
    [self waitForInitialLoad];
    return [self.supportedFonts containsObject:fullName];
}

- (NSString *)typeFaceNameForFont:(NSString *)fullName {
    [self waitForInitialLoad];
    
    NSString *longName = _systemFontMap[fullName] ?: ((KTUserFont *)_userFontMap[fullName]).displayName;
    NSString *familyName = [self familyNameForFont:fullName];
    NSString *typeFace = [longName copy];
    if ([typeFace hasPrefix:familyName]) {
        typeFace = [longName substringFromIndex:[familyName length]];
        typeFace = [typeFace stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([typeFace length] == 0) {
        typeFace = @"Regular";
    }
    return typeFace;
}

- (NSString *)displayNameForFont:(NSString *)fullName {
    [self waitForInitialLoad];
    return _systemFontMap[fullName] ?: ((KTUserFont *)_userFontMap[fullName]).displayName;
}

- (NSString *)familyNameForFont:(NSString *)fullName {
    [self waitForInitialLoad];
    return _systemFamilyMap[fullName] ?: ((KTUserFont *)_userFamilyMap[fullName]);
}

- (NSString *)defaultFontForFamily:(NSString *)familyName {
    [self waitForInitialLoad];
    
    NSArray *fonts = [self fontsInFamily:familyName];
    NSArray *sorted = [fonts sortedArrayUsingComparator:^NSComparisonResult(NSString *aString, NSString *bString) {
        NSNumber *a = @(aString.length);
        NSNumber *b = @(bString.length);
        return [a compare:b];
    }];
    
    for (NSString *fontName in sorted) {
        CTFontRef fontRef = [self newFontRefForFont:fontName withSize:10];
        CTFontSymbolicTraits traits = CTFontGetSymbolicTraits(fontRef);
        CFRelease(fontRef);
        
        BOOL isBold = (traits & kCTFontBoldTrait);
        if (isBold) {
            continue;
        }
        
        BOOL isItalic = (traits & kCTFontItalicTrait);
        if (isItalic) {
            continue;
        }
        
        return fontName;
    }
    
    // Fallback, just return the first font in this family
    return [sorted firstObject];
}

- (NSArray *)fontsInFamily:(NSString *)familyName {
    [self waitForInitialLoad];
    
    NSArray *result = [_systemFamilyMap allKeysForObject:familyName];
    
    if (!result || result.count == 0) {
        result = [_userFamilyMap allKeysForObject:familyName];
    }
    
    return (result ?: @[]);
}

- (NSString *)pathForUserLibrary {
    NSString *fontPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    return [fontPath stringByAppendingPathComponent:@"Fonts"];
}

- (NSArray *)userLibraryFontPaths {
    NSString *fontPath = [self pathForUserLibrary];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *expanded = [NSMutableArray array];
    
    for (NSString *font in [fm contentsOfDirectoryAtPath:fontPath error:NULL]) {
        [expanded addObject:[fontPath stringByAppendingPathComponent:font]];
    }
    
    return expanded;
}

- (CTFontRef)newFontRefForFont:(NSString *)fullName withSize:(CGFloat)size {
    return [self newFontRefForFont:fullName withSize:size provideDefault:NO];
}

- (CTFontRef)newFontRefForFont:(NSString *)fullName withSize:(CGFloat)size provideDefault:(BOOL)provideDefault {
    [self waitForInitialLoad];
    
    if (_systemFontMap[fullName]) {
        // it's built in, just load it
        return CTFontCreateWithName((CFStringRef) fullName, size, NULL);
    } else if (_userFontMap[fullName]) {
        KTUserFont *userFont = (KTUserFont *) _userFontMap[fullName];
        return [userFont newFontRefForSize:size];
    } else if (provideDefault) {
        // if we got this far, return the default font
        return CTFontCreateWithName((CFStringRef) @"Helvetica", size, NULL);
    }
    
    return NULL;
}

- (NSArray *)userFonts {
    [self waitForInitialLoad];
    
    if (!_userFonts) {
        _userFonts = [[_userFontMap allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
    
    return _userFonts;
}


- (KTUserFont *) isFontAlreadyInstalled:(NSString *)path
{
    [self waitForInitialLoad];
    
    NSData *hash = KTSHA1DigestForData([NSData dataWithContentsOfFile:path]);
    
    NSSet *keys = [_userFontMap keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        KTUserFont *userFont = (KTUserFont *) obj;
        *stop = [userFont.digest isEqual:hash];
        return *stop;
    }];
    
    return _userFontMap[[keys anyObject]];
}

- (KTUserFont *) userFontForPath:(NSString *)path
{
    [self waitForInitialLoad];
    
    NSSet *keys = [_userFontMap keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        KTUserFont *userFont = (KTUserFont *) obj;
        *stop = [userFont.filePath caseInsensitiveCompare:path] == NSOrderedSame;
        return *stop;
    }];
    
    return _userFontMap[[keys anyObject]];
}

- (void) userFontsChanged
{
    _userFonts = nil;
    _supportedFonts = nil;
}

- (NSString *)installUserFont:(NSURL *)srcURL alreadyInstalled:(BOOL *)alreadyInstalled {
    [self waitForInitialLoad];
    
    // see if this font is already installed
    KTUserFont *existing = [self isFontAlreadyInstalled:[srcURL path]];
    *alreadyInstalled = existing ? YES : NO;
    if (*alreadyInstalled) {
        return existing.displayName;
    }
    
    // load the font to see if it's valid
    KTUserFont *userFont = [KTUserFont userFontWithFileName:[srcURL path]];
    if (!userFont) {
        return nil;
    }
    
    NSString        *fontPath = [[self pathForUserLibrary] stringByAppendingPathComponent:[srcURL lastPathComponent]];
    NSURL           *dstURL = [NSURL fileURLWithPath:fontPath];
    NSError         *error = nil;
    
    // delete the old font at this path, if any
    [self deleteUserFontWithName:[self userFontForPath:fontPath].fullName];
    
    [[NSFileManager defaultManager] copyItemAtURL:srcURL toURL:dstURL error:&error];
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    
    // make sure the font knows its new location
    userFont.filePath = [dstURL path];
    
    // the font is now copied to ~/Library/Fonts/ so update the user font map and name array
    _userFontMap[userFont.fullName] = userFont;
    _userFamilyMap[userFont.fullName] = userFont.familyName;
    
    [self userFontsChanged];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KTFontAddedNotification
                                                        object:self
                                                      userInfo:@{@"name": userFont.fullName}];
    
    return userFont.displayName;
}

- (void)deleteUserFontWithName:(NSString *)fullName {
    [self waitForInitialLoad];
    
    KTUserFont *userFont = _userFontMap[fullName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (!userFont || ![fm fileExistsAtPath:userFont.filePath]) {
        return;
    }
    
    // actually delete it
    [fm removeItemAtPath:userFont.filePath error:NULL];
    
    // update caches
    [_userFontMap removeObjectForKey:userFont.fullName];
    [_userFamilyMap removeObjectForKey:userFont.fullName];
    
    NSInteger index = [self.userFonts indexOfObject:userFont.fullName];
    [self userFontsChanged];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KTFontDeletedNotification
                                                        object:self
                                                      userInfo:@{@"index": @(index)}];
}

@end

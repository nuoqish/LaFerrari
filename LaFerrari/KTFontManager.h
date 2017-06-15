//
//  KTFontManager.h
//  LaFerrari
//
//  Created by stanshen on 17/6/13.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTUserFont;

extern NSString *KTFontAddedNotification;
extern NSString *KTFontDeletedNotification;

@interface KTFontManager : NSObject

@property (nonatomic, readonly, weak) NSArray *supportedFonts;
@property (nonatomic, readonly, weak) NSArray *supportedFamilies;

@property (nonatomic, readonly, strong) NSMutableDictionary *userFontMap;
@property (nonatomic, readonly, strong) NSMutableDictionary *userFamilyMap;
@property (nonatomic, readonly, strong) NSArray *userFonts;

@property (nonatomic, readonly, strong) NSMutableDictionary *systemFontMap;
@property (nonatomic, readonly, strong) NSMutableDictionary *systemFamilyMap;
@property (nonatomic, readonly, strong) NSArray *systemFonts;

+ (KTFontManager *)sharedInstance;

- (void)loadAllFonts;

- (BOOL)isUserFont:(NSString *)fullName;
- (BOOL)validFont:(NSString *)fullName;
- (NSString *)displayNameForFont:(NSString *)fullName;
- (NSString *)typeFaceNameForFont:(NSString *)fullName;
- (NSString *)defaultFontForFamily:(NSString *)familyName;
- (NSString *)familyNameForFont:(NSString *)fullName;
- (NSArray *)fontsInFamily:(NSString *)familyName;

- (KTUserFont *)userFontForPath:(NSString *)path;
- (NSString *)installUserFont:(NSURL *)srcURL alreadyInstalled:(BOOL *)alreadyInstalled;
- (void)deleteUserFontWithName:(NSString *)fullName;

- (CTFontRef)newFontRefForFont:(NSString *)fullName withSize:(CGFloat)size;
- (CTFontRef)newFontRefForFont:(NSString *)fullName withSize:(CGFloat)size provideDefault:(BOOL)providedDefault;

- (NSString *)pathForUserLibrary;
- (NSArray *)userLibraryFontPaths;

@end

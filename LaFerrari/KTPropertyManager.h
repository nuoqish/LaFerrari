//
//  KTPropertyManager.h
//  LaFerrari
//
//  Created by stanshen on 17/6/11.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KTDrawingController;
@class KTShadow;
@class KTStrokeStyle;

@protocol KTPathPainter;

// notifications
extern NSString *KTActiveStrokeChangedNotification;
extern NSString *KTActiveFillChangedNotification;
extern NSString *KTActiveShadowChangedNotification;
extern NSString *KTInvalidPropertiesNotification;
extern NSString *KTInvalidPropertiesKey;

@interface KTPropertyManager : NSObject

@property (nonatomic, weak) KTDrawingController *drawingController;
@property (nonatomic, assign) BOOL ignoreSelectionChanges;

- (void)addToInvalidProperties:(NSString *)property;
- (void)setDefaultValue:(id)value forProperty:(NSString *)property;
- (id)defaultValueForProperty:(NSString *)property;

- (void)updateUserDefaults;

- (KTShadow *)activeShadow;
- (KTShadow *)defaultShadow;
- (KTStrokeStyle *)activeStrokeStyle;
- (KTStrokeStyle *)defaultStrokeStyle;
- (id<KTPathPainter>)activeFillStyle;
- (id<KTPathPainter>)deafultFillStyle;

@end

//
//  KTXMLElement.h
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KTXMLElement : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSMutableDictionary *attributes;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, readonly, weak) NSString *XMLValue;

+ (KTXMLElement *)elementWithName:(NSString *)name;

- (id)initWithName:(NSString *)name;

- (void)setAttribute:(NSString *)attribute value:(NSString *)value;
- (void)setAttribute:(NSString *)attribute floatValue:(float)value;

- (void)addChild:(KTXMLElement *)element;
- (void)removeAllChildren;

@end

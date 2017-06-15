//
//  KTSVGHelper.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTSVGHelper.h"

#import "KTXMLElement.h"

@interface KTSVGHelper ()

@property (nonatomic, strong) NSMutableDictionary *uniques;
@property (nonatomic, strong) KTXMLElement *definitions;
@property (nonatomic, strong) NSMutableDictionary *images;
@property (nonatomic, strong) NSMutableDictionary *blendModeNames;

@end

@implementation KTSVGHelper

+ (KTSVGHelper *)sharedSVGHelper {
    static KTSVGHelper *sharedHelper_ = nil;
    if (!sharedHelper_) {
        sharedHelper_ = [[KTSVGHelper alloc] init];
    }
    return sharedHelper_;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _uniques = @{}.mutableCopy;
        _definitions = [[KTXMLElement alloc] initWithName:@"defs"];
        _images = @{}.mutableCopy;
        NSArray *blendModeArray = [[NSArray alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"BlendModes" withExtension:@"plist"]];
        _blendModeNames = @{}.mutableCopy;
        for (NSDictionary *dict in blendModeArray) {
            _blendModeNames[dict[@"value"]] = dict[@"name"];
        }
    }
    return self;
}

- (void)beginSVGGeneration {
    // reset the uniqueness tracker
    [_uniques removeAllObjects];
    [_definitions removeAllChildren];
    [_images removeAllObjects];
}

- (void)endSVGGeneration {
    // reset the uniqueness tracker
    [_uniques removeAllObjects];
    [_definitions removeAllChildren];
    [_images removeAllObjects];
}

- (NSString *)uniqueIDWithPrefix:(NSString *)prefix {
    NSNumber *unique = _uniques[prefix];
    if (!unique) {
        _uniques[prefix] = @2;
        return prefix;
    }
    // incremement the old unique value and store it away for next time
    _uniques[prefix] = @([unique integerValue]+1);
    // return the unique string
    return [NSString stringWithFormat:@"%@_%@", prefix, [unique stringValue]];
}

- (void)addDefinition:(KTXMLElement *)def {
    [_definitions addChild:def];
}

- (void)setImageID:(NSString *)uniqueID forDigest:(NSData *)digest {
    _images[digest] = uniqueID;
}

- (NSString *)imageIDForDigest:(NSData *)digest {
    return _images[digest];
}

- (NSString *)displayNameForBlendMode:(CGBlendMode)blendMode {
    return _blendModeNames[[NSNumber numberWithInt:blendMode]];
}

@end

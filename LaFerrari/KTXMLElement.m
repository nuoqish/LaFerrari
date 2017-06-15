//
//  KTXMLElement.m
//  LaFerrari
//
//  Created by stanshen on 17/6/9.
//  Copyright © 2017年 stanshen. All rights reserved.
//

#import "KTXMLElement.h"

@implementation KTXMLElement

+ (KTXMLElement *)elementWithName:(NSString *)name {
    KTXMLElement *element = [[KTXMLElement alloc] initWithName:name];
    return element;
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.name = name;
        self.children = @[].mutableCopy;
        self.attributes = @{}.mutableCopy;
    }
    return self;
}

- (void)setAttribute:(NSString *)attribute value:(NSString *)value {
    [self.attributes setValue:value forKey:attribute];
}

- (void)setAttribute:(NSString *)attribute floatValue:(float)value {
    [self.attributes setValue:[NSString stringWithFormat:@"%g", value] forKey:attribute];
}

- (void)addChild:(KTXMLElement *)element {
    [self.children addObject:element];
}

- (void)removeAllChildren {
    [self.children removeAllObjects];
}

- (NSString *)XMLValue {
    NSMutableString *xmlValue = @"".mutableCopy;
    BOOL needsCloseTag = (self.value || self.children.count) ? YES : NO;
    [xmlValue appendString:[NSString stringWithFormat:@"<%@", _name]];
    
    for (NSString *key in [_attributes allKeys]) {
        [xmlValue appendString:[NSString stringWithFormat:@" %@=\"%@\"", key, [_attributes valueForKey:key]]];
    }
    
    if (needsCloseTag) {
        [xmlValue appendString:@">\n"];
    }
    else {
        [xmlValue appendString:@"/>\n"];
    }
    
    if (self.value) {
        [xmlValue appendString:@"<![CDATA["];
        [xmlValue appendString:self.value];
        [xmlValue appendString:@"]]>"];
    }
    else if (self.children) {
        for (KTXMLElement *element in self.children) {
            [xmlValue appendString:[element XMLValue]];
        }
    }
    
    if (needsCloseTag) {
        [xmlValue appendString:[NSString stringWithFormat:@"</%@>\n", _name]];
    }
    
    return xmlValue;
}

- (NSString *)description {
    return [self XMLValue];
}































@end

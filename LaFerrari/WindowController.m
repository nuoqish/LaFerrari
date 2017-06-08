//
//  WindowController.m
//  MoguMattor
//
//  Created by longyan on 2017/5/11.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "WindowController.h"

#import "ViewController.h"
#import "KTToolbar.h"

@interface WindowController ()<KTToolbarDelegate>


@property (nonatomic, strong) KTToolbar *toolbar;


@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    
    [self.window setToolbar:self.toolbar];
    self.toolbar.ktDelegate = self;
    
}

- (KTToolbar *)toolbar {
    if (!_toolbar) {
        _toolbar = [[KTToolbar alloc] initWithIdentifier:@"MoguMattorToolbar"];
    }
    return _toolbar;
}

#pragma mark - KTToolbarDelegate

- (void)toolbar:(KTToolbar *)toolbar didOpenImageUrl:(NSURL *)imagePath {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        [vc openImageUrl:imagePath];
    }
}

- (void)toolbar:(KTToolbar *)toolbar didSaveImageUrl:(NSURL *)imagePath {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        [vc saveImageUrl:imagePath];
    }
}

- (void)toolbar:(KTToolbar *)toolbar didOpenImageUrls:(NSArray<NSURL *> *)imageUrls {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        [vc openImageUrls:imageUrls];
    }
}

- (void)toolbar:(KTToolbar *)toolbar didSaveImageUrls:(NSURL *)imageDirPath {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        [vc saveImagesToDir:imageDirPath];
    }
}


- (void)undoButtonTappedForToolbar:(KTToolbar *)toolbar {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        [vc undo];
    }
}

- (NSString *)fileNameForToolbar:(KTToolbar *)toolbar {
    if ([self.contentViewController isKindOfClass:[ViewController class]]) {
        ViewController *vc = (ViewController *)self.contentViewController;
        return vc.view.window.representedFilename;
    }
    return nil;
}

@end

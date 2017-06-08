//
//  KTToolbar.m
//  MoguMattor
//
//  Created by longyan on 2017/5/11.
//  Copyright © 2017年 shenyanhao. All rights reserved.
//

#import "KTToolbar.h"

NS_ENUM(NSInteger, KTToolbarTag) {
    kToolbarOpen,
    kToolbarUndo,
    kToolbarRedo,
    kToolbarSave,
    kToolbarHelp
};


@interface KTToolbar () <NSToolbarDelegate>

@end

@implementation KTToolbar

- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.allowsUserCustomization = YES;
        self.autosavesConfiguration = NO;
        self.displayMode = NSToolbarDisplayModeIconAndLabel;
        self.sizeMode = NSToolbarSizeModeSmall;
        self.delegate = self;
        
    }
    
    return self;
}




#pragma mark - NSToolbarDelegate methods

- (NSArray<NSString *> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"Open",@"Undo",@"Redo",@"Save",@"Help"];
}

- (NSArray<NSString *> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return @[@"Open",@"Undo",@"Redo",@"Save",@"Help"];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    if ([theItem.itemIdentifier isEqualToString:@"Redo"] ||
        [theItem.itemIdentifier isEqualToString:@"Help"]) {
        return NO;
    }
    return YES;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:@"Open"]) {
        [toolbarItem setLabel:@"打开"];
        [toolbarItem setPaletteLabel:@"打开"];
        [toolbarItem setToolTip:@"打开目录选择图片文件"];
        [toolbarItem setImage:[NSImage imageNamed:@"document_2"]];
        toolbarItem.tag = kToolbarOpen;
    }
    else if ([itemIdentifier isEqualToString:@"Undo"]) {
        [toolbarItem setLabel:@"撤销"];
        [toolbarItem setPaletteLabel:@"撤销"];
        [toolbarItem setToolTip:@"撤销当前步骤，回到上一步状态"];
        [toolbarItem setImage:[NSImage imageNamed:@"undo"]];
        toolbarItem.tag = kToolbarUndo;
    }
    else if ([itemIdentifier isEqualToString:@"Redo"]) {
        [toolbarItem setLabel:@"返回"];
        [toolbarItem setPaletteLabel:@"返回"];
        [toolbarItem setToolTip:@"暂时不支持这个"];
        [toolbarItem setImage:[NSImage imageNamed:@"redo"]];
        toolbarItem.tag = kToolbarRedo;
    }
    else if ([itemIdentifier isEqualToString:@"Save"]) {
        [toolbarItem setLabel:@"保存"];
        [toolbarItem setPaletteLabel:@"保存"];
        [toolbarItem setToolTip:@"保存当前文件"];
        [toolbarItem setImage:[NSImage imageNamed:@"document_4"]];
        toolbarItem.tag = kToolbarSave;
    }
    else if ([itemIdentifier isEqualToString:@"Help"]) {
        [toolbarItem setLabel:@"帮助"];
        [toolbarItem setPaletteLabel:@"帮助"];
        [toolbarItem setToolTip:@"经常问的问题"];
        [toolbarItem setImage:[NSImage imageNamed:@"faq_blue"]];
        toolbarItem.tag = kToolbarHelp;
    }
    else {
        toolbarItem = nil;
    }
    
    [toolbarItem setMinSize:CGSizeMake(10, 10)];
    [toolbarItem setMaxSize:CGSizeMake(20, 20)];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(toolbarItemClicked:)];
    return toolbarItem;
}

#pragma mark - toolbar actions

- (void)toolbarItemClicked:(id)sender {
    NSToolbarItem *item =  sender;
    NSInteger tag = item.tag;
    //根据每个ToolbarItem的tag做流程处理
    if(tag == kToolbarOpen) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.allowsMultipleSelection = YES;
        NSInteger modalType = [openPanel runModal];
        if (modalType == NSFileHandlingPanelOKButton) {
            NSArray<NSURL *> *fileUrls = [openPanel URLs];
            if (fileUrls.count == 1) {
                NSURL *imageUrl = fileUrls[0];
                if (self.ktDelegate && [self.ktDelegate respondsToSelector:@selector(toolbar:didOpenImageUrl:)]) {
                    [self.ktDelegate toolbar:self didOpenImageUrl:imageUrl];
                }
            }
            else {
                if (self.ktDelegate && [self.ktDelegate respondsToSelector:@selector(toolbar:didOpenImageUrl:)]) {
                    [self.ktDelegate toolbar:self didOpenImageUrls:fileUrls];
                }
            }
            
        }
    }
    if(tag == kToolbarUndo) {
        if (self.ktDelegate && [self.ktDelegate respondsToSelector:@selector(undoButtonTappedForToolbar:)]) {
            [self.ktDelegate undoButtonTappedForToolbar:self];
        }
    }
    else if (tag == kToolbarSave) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        NSString *fileName = [[self.ktDelegate fileNameForToolbar:self] lastPathComponent];
        savePanel.nameFieldStringValue = [NSString stringWithFormat:@"%@.png", fileName != nil ? fileName : @"Untitled"];
        savePanel.canCreateDirectories = YES;
        NSInteger modalType = [savePanel runModal];
        if (modalType == NSFileHandlingPanelOKButton) {
            NSURL *fileUrl = [savePanel URL];
            if (self.ktDelegate && [self.ktDelegate respondsToSelector:@selector(toolbar:didOpenImageUrl:)]) {
                [self.ktDelegate toolbar:self didSaveImageUrl:fileUrl];
            }
        }
    }
}

@end

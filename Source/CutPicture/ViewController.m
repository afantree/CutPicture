//
//  ViewController.m
//  CutPicture
//
//  Created by 阿凡树 on 2016/12/16.
//  Copyright © 2016年 阿凡树. All rights reserved.
//

#import "ViewController.h"
typedef NS_ENUM(NSInteger,TextFieldType) {
    TextFieldTypePng     = 0,
    TextFieldTypePlist   = 1,
    TextFieldTypeOutput  = 2,
};
@interface NSImage (Resize)
- (NSImage *)croppedImage:(CGRect)bounds;
@end
@implementation NSImage (Resize)
- (NSImage *)croppedImage:(CGRect)rect {
    CGRect r = CGRectMake(0, 0, self.size.width, self.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImageForProposedRect:&r context:NULL hints:nil], rect);
    NSImage *croppedImage = [[NSImage alloc] initWithCGImage:imageRef size:rect.size];
    CGImageRelease(imageRef);
    return croppedImage;
}
@end
@interface NSAlert (error)
+ (void)alertWithErrorMessage:(NSString*)message;
@end
@implementation NSAlert (error)
+ (void)alertWithErrorMessage:(NSString*)message {
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = message;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}
@end
@interface ViewController()<NSOpenSavePanelDelegate>
@property (strong) IBOutlet NSTextField *pngTextField;
@property (strong) IBOutlet NSTextField *plistTextField;
@property (strong) IBOutlet NSTextField *outputTextField;
@property (strong) NSOpenPanel *openPanel;
@property (strong) NSURL * selectedPath;
@property (strong) IBOutlet NSTextField *tipLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _openPanel = [[NSOpenPanel alloc] init];
    _openPanel.canChooseFiles = true;
    _openPanel.canChooseDirectories = true;
    _openPanel.delegate = self;
    _openPanel.canCreateDirectories = true;
    _openPanel.allowedFileTypes = @[@"png",@"plist",@"jpg",@"jpeg"];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)selectPath:(NSButton *)sender {
    NSTextField* textField = _pngTextField;
    switch (sender.tag) {
        case TextFieldTypePlist:
            textField = _plistTextField;
            break;
        case TextFieldTypeOutput:
            textField = _outputTextField;
            break;
        default:
            break;
    }
    if (textField.stringValue.length != 0) {
        _openPanel.directoryURL = [NSURL URLWithString:textField.stringValue].URLByDeletingLastPathComponent;
    }
    __weak typeof(self) weakSelf = self;
    [_openPanel beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            textField.stringValue = weakSelf.selectedPath.path;
            switch (sender.tag) {
                case TextFieldTypePng:
                    [weakSelf predictValueWithType:TextFieldTypePlist andPath:weakSelf.selectedPath inTextField:_plistTextField];
                    [weakSelf predictValueWithType:TextFieldTypeOutput andPath:weakSelf.selectedPath inTextField:_outputTextField];
                    break;
                case TextFieldTypePlist:
                    [weakSelf predictValueWithType:TextFieldTypePng andPath:weakSelf.selectedPath inTextField:_pngTextField];
                    [weakSelf predictValueWithType:TextFieldTypeOutput andPath:weakSelf.selectedPath inTextField:_outputTextField];
                    break;
                case TextFieldTypeOutput:
                    [weakSelf predictValueWithType:TextFieldTypePng andPath:weakSelf.selectedPath inTextField:_pngTextField];
                    [weakSelf predictValueWithType:TextFieldTypePlist andPath:weakSelf.selectedPath inTextField:_plistTextField];
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)predictValueWithType:(TextFieldType)type andPath:(NSURL*)path inTextField:(NSTextField*)textField {
    switch (type) {
        case TextFieldTypePng: {
            NSString* pngPath = [NSString stringWithFormat:@"%@/%@.png",path.URLByDeletingLastPathComponent.path,[self getPathName:path]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:pngPath]) {
                textField.stringValue = pngPath;
            }
            break;
        }
        case TextFieldTypePlist: {
            NSString* plistPath = [NSString stringWithFormat:@"%@/%@.plist",path.URLByDeletingLastPathComponent.path,[self getPathName:path]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
                textField.stringValue = plistPath;
            }
            break;
        }
        case TextFieldTypeOutput: {
            NSString* outputPath = [NSString stringWithFormat:@"%@/%@",path.URLByDeletingLastPathComponent.path,[self getPathName:path]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            textField.stringValue = outputPath;
            break;
        }
        default:break;
    }
}

- (NSString*)getPathName:(NSURL*)path {
    NSString* name = path.lastPathComponent;
    NSRange range = [name rangeOfString:@"."];
    return [name substringToIndex:range.location];
}

#pragma mark - Button Action

- (IBAction)cut:(NSButton *)sender {
    if (_pngTextField.stringValue.length == 0 || _plistTextField.stringValue.length == 0 || _outputTextField.stringValue.length ==0) {
        [NSAlert alertWithErrorMessage:@"路径不能为空"];
        return;
    }
    NSDictionary* plist = [[NSDictionary alloc] initWithContentsOfFile:_plistTextField.stringValue];
    if (plist == nil) {
        [NSAlert alertWithErrorMessage:@"plist文件有错"];
        return;
    }
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:_pngTextField.stringValue];
    if (image == nil) {
        [NSAlert alertWithErrorMessage:@"png图片有错"];
        return;
    }
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:_outputTextField.stringValue isDirectory:&isDirectory]) {
        [NSAlert alertWithErrorMessage:@"输出路径有错"];
        return;
    }
    if (!isDirectory) {
        [NSAlert alertWithErrorMessage:@"输出路径请选择文件夹"];
        return;
    }
    NSDictionary* frames = plist[@"frames"];
    if (frames != nil) {
        for (NSString* key in frames) {
            _tipLabel.stringValue = [NSString stringWithFormat:@"正在裁切 %@",key];
            if (frames[key][@"frame"] == nil) {
                continue;
            }
            NSImage* subImage = [image croppedImage:NSRectFromString(frames[key][@"frame"])];
            if (CGSizeEqualToSize(subImage.size, CGSizeZero)) {
                continue;
            }
            NSData* subData = [subImage TIFFRepresentation];
            if (subData.length == 0 ) {
                continue;
            }
            NSString* filename = key;
            if (![filename hasPrefix:@".png"]) {
                filename = [filename stringByAppendingString:@".png"];
            }
            if (subData != nil) {
                NSString* path = [NSString stringWithFormat:@"%@/%@",_outputTextField.stringValue,filename];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
                [subData writeToFile:path atomically:YES];
            }
        }
        _tipLabel.stringValue = @"已完成";
    }
}

#pragma mark - NSOpenSavePanelDelegate

- (void)panelSelectionDidChange:(NSOpenPanel*)sender {
    _selectedPath = sender.URL;
    NSLog(@"sender.URL = %@",sender.URL);
}
@end



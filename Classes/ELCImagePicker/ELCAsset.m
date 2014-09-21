//
//  Asset.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAsset.h"
#import "ELCAssetTablePicker.h"

@import Photos;

NSString * localizedString(NSString * key)
{
    static NSBundle *bundle = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        NSURL * URL = [[NSBundle mainBundle] URLForResource:@"ELCImagePickerController" withExtension:@"bundle"];
        bundle = [NSBundle bundleWithURL:URL];
    });
    return [bundle localizedStringForKey:key value:nil table:nil];
}

@implementation ELCAsset

//Using auto synthesizers

- (id)initWithAsset:(NSObject *)asset
{
	self = [super init];
	if (self) {
		self.asset = asset;
        _selected = NO;
    }
	return self;	
}

- (void)toggleSelection
{
    self.selected = !self.selected;
}

- (void)setSelected:(BOOL)selected
{
    if (selected) {
        if ([_parent respondsToSelector:@selector(shouldSelectAsset:)]) {
            if (![_parent shouldSelectAsset:self]) {
                return;
            }
        }
    }
    _selected = selected;
    if (selected) {
        if (_parent != nil && [_parent respondsToSelector:@selector(assetSelected:)]) {
            [_parent assetSelected:self];
        }
    }
}

- (void)showThumbnailInImageView:(UIImageView *)imageView
{
    if ([_asset isKindOfClass:[ALAsset class]]) {
        imageView.image = [UIImage imageWithCGImage:((ALAsset *)_asset).thumbnail];
    } else {
        float scale = [UIScreen mainScreen].scale;

        [[PHImageManager defaultManager]
         requestImageForAsset:(PHAsset *)_asset
         targetSize:CGSizeMake(THUMBNAIL_SIZE * scale, THUMBNAIL_SIZE * scale)
         contentMode:PHImageContentModeAspectFill
         options:nil
         resultHandler:^(UIImage *result, NSDictionary *info) {
             imageView.image = result;
         }];
    }
}

@end


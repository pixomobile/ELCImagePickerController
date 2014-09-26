//
//  AssetCell.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetCell.h"

@implementation ELCAssetCell {
    UIImageView * _imageView;
    UIImageView * _overlayView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.frame = self.bounds;
        [self addSubview:_imageView];

        _overlayView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Overlay"]];
        _overlayView.frame = _imageView.frame;
        _overlayView.hidden = YES;
        [self addSubview:_overlayView];
    }
    
    return self;
}

- (void)setAsset:(ELCAsset *)asset
{
    _asset = asset;

    _imageView.image = [UIImage imageWithCGImage:asset.asset.thumbnail];

    _overlayView.hidden = _asset.selected ? NO : YES;
}

- (void)toggleSelection
{
    _asset.selected = ! _asset.selected;

    _overlayView.hidden = !_asset.selected;
}

@end

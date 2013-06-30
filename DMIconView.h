//
//  DMIconView.h
//  IconView
//
//  Created by Daniel Moreh on 6/6/12.
//  Copyright (c) 2012 Lockysoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol DMIconViewDelegate;
@protocol DMIconViewDataSource;

//--------------------------------------------------------------------------------------
// INTERFACE
//--------------------------------------------------------------------------------------

@interface DMIconView : UIScrollView {
    UIImageView *indicator;
}


@property (nonatomic, unsafe_unretained) id<DMIconViewDelegate, UIScrollViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<DMIconViewDataSource> dataSource;
@property (nonatomic, unsafe_unretained) CGRect onScreenFrame;
@property (nonatomic, unsafe_unretained) CGRect offScreenFrame;

- (void)reloadData;
- (void)showItemAtIndex:(NSNumber *)index;
- (void)moveIndicatorToIndex:(int)index;
- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;
- (void)toggleHiddenAnimated:(BOOL)animated;
- (BOOL)isHidden;

@end

//--------------------------------------------------------------------------------------
// PROTOCOLS
//--------------------------------------------------------------------------------------

// Delegate Protocol Declaration 

@protocol DMIconViewDelegate <UIScrollViewDelegate>

@required

- (BOOL)iconView:(DMIconView *)iconView didSelectItemAtIndex:(int)index;

@end

// Data Source Protocol Declaration 

@protocol DMIconViewDataSource <NSObject>

@optional

- (CGFloat)iconView:(DMIconView *)iconView scaleFactorForImageAtIndex:(int)index;

@required

- (int)numberOfIconsInIconView:(DMIconView *)iconView;
- (UIImage *)iconView:(DMIconView *)iconView imageAtIndex:(int)index;
- (NSString *)iconView:(DMIconView *)iconView titleAtIndex:(int)index;
- (UIImage *)iconView:(DMIconView *)iconView backgroundAtIndex:(int)index;
- (UIImage *)indicatorForIconView:(DMIconView *)iconView;


@end


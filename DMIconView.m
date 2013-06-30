//
//  DMIconView.m
//  IconView
//
//  Created by Daniel Moreh on 6/6/12.
//  Copyright (c) 2012 Lockysoft. All rights reserved.
//

#import "DMIconView.h"
#import "UIImage+Resize.h"

#define ICON_SIDE_LENGTH 60.0
#define SPACE 10.0 // Space between each icon
#define FONT_SIZE 13.0

// Private methods
@interface DMIconView ()
-(CGRect)getScreenBoundsForCurrentOrientation;
-(CGRect)getScreenBoundsForOrientation:(UIInterfaceOrientation)orientation;
@end

@implementation DMIconView
@synthesize delegate;
@synthesize dataSource;
@synthesize onScreenFrame;
@synthesize offScreenFrame;

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.bounces = YES;
    self.alwaysBounceHorizontal = YES;
}

- (void)reloadData
{
    // Check for data source
    if (!self.dataSource) {
        NSLog(@"Error: DMIconViewDataSource unspecified");
        return;
    }
    
    // Set up indicator
	UIImage *indicatorImage = [self.dataSource indicatorForIconView:self];
    const float indicatorHeight = indicatorImage.size.height;
    
    // Resize frame
    CGRect frame = self.frame;
    frame.size.height = ICON_SIDE_LENGTH + indicatorHeight + (1.8 * SPACE);
    frame.size.width = [self getScreenBoundsForCurrentOrientation].size.width;
    [self setFrame:frame];
	
    // Initialize indicator if necessary
    if (!indicator) {
        indicator = [[UIImageView alloc] initWithImage:indicatorImage];
        
        // Start indicator at 0th icon
        CGPoint initialCenter;
        initialCenter.x = SPACE + (ICON_SIDE_LENGTH / 2);
        initialCenter.y = self.frame.size.height - (indicatorHeight / 2);
        [indicator setCenter:initialCenter];
        [self addSubview:indicator];
    } else if (indicatorImage != indicator.image) {
        [indicator setImage:indicatorImage];
    }
    
    // Adjust content size
    int iconCount = [self.dataSource numberOfIconsInIconView:self];
    if (iconCount < 1)
        NSLog(@"Error: DMIconViewDataSource specified invalid number of icons (%d).", iconCount);
    
    CGSize contentSize;
    contentSize.height = ICON_SIDE_LENGTH + indicatorHeight;
    contentSize.width = (ICON_SIDE_LENGTH * iconCount) + (SPACE * (iconCount + 1));
    [self setContentSize:contentSize];
    
    for (int i = 0; i < iconCount; i++) {
        // Put each image in a button
        UIImage *image = [self.dataSource iconView:self imageAtIndex:i];
        
        // Scale the image if a scale factor is specified
        CGFloat scaleFactor = [self.dataSource iconView:self scaleFactorForImageAtIndex:i];
        if (0.0 < scaleFactor && scaleFactor < 1.0) {
            CGFloat ratio = image.size.height / image.size.width;
            CGSize scaledSize = CGSizeZero;
            scaledSize.width = ICON_SIDE_LENGTH * 2 * scaleFactor;
            scaledSize.height = scaledSize.width * ratio;
            image = [image resizedImage:scaledSize interpolationQuality:kCGInterpolationHigh];
        }
        
        // Set up the button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTag:i]; // Tag functions as index
        [button setImage:image forState:UIControlStateNormal];
        if (image.size.width > (2 * ICON_SIDE_LENGTH))
            [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
        else
            [button.imageView setContentMode:UIViewContentModeCenter];
        [button setClipsToBounds:NO];
        [button setAdjustsImageWhenHighlighted:NO];
        [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[button setBackgroundImage:[dataSource iconView:self backgroundAtIndex:i] forState:UIControlStateNormal];
        
        CGRect buttonFrame;
        buttonFrame.origin.x = (SPACE * (i + 1)) + (ICON_SIDE_LENGTH * i);
        buttonFrame.origin.y = SPACE;
        buttonFrame.size.width = ICON_SIDE_LENGTH;
        buttonFrame.size.height = ICON_SIDE_LENGTH;
        button.frame = buttonFrame;
        
        // Add a label to the button
        NSString *title = [self.dataSource iconView:self titleAtIndex:i];
        UIFont *font = [UIFont fontWithName:@"Futura-CondensedMedium" size:FONT_SIZE];
        CGSize size = [title sizeWithFont:font];
        size.width = ICON_SIDE_LENGTH + (SPACE / 2);
        
        UILabel *label = [[UILabel alloc] init];
        [label setFont:font];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setShadowColor:[UIColor blackColor]];
        [label setShadowOffset:CGSizeMake(1.0, 1.0)];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setText:title];
		[label sizeToFit];
		[label setCenter:CGPointMake(button.frame.size.width / 2, button.frame.size.height)];
        [button addSubview:label];
        
        // Add the button to the view
        [self addSubview:button];
    }
}

- (void)showItemAtIndex:(NSTimer *)timer {
	CGFloat rectOriginX = (ICON_SIDE_LENGTH + SPACE) * ([[timer userInfo] intValue] + 1);
	[self scrollRectToVisible:CGRectMake(rectOriginX, 0, 1, 1) animated:NO];
}

- (void)showAnimated:(BOOL)animated {
	if (![self isHidden])
		return;
    
	if (animated) {
		[UIView animateWithDuration:.3 animations:^{
			[self setFrame:onScreenFrame];
		}];
	} else {
		[self setFrame:onScreenFrame];
	}
}

- (void)hideAnimated:(BOOL)animated {
	if ([self isHidden])
		return;
    
	if (animated) {
		[UIView animateWithDuration:.3 animations:^{
			[self setFrame:offScreenFrame];
		}];
	} else {
		[self setFrame:offScreenFrame];
	}
}

- (void)toggleHiddenAnimated:(BOOL)animated {
	if ([self isHidden])
		[self showAnimated:animated];
	else
		[self hideAnimated:animated];
}

- (BOOL)isHidden {
	return CGRectEqualToRect(self.frame, offScreenFrame);
}

- (void)moveIndicatorToIndex:(int)index {
	if (self.delegate && [self.delegate iconView:self didSelectItemAtIndex:index]) {
		CGPoint center = indicator.center;
		center.x = (SPACE * (index + 1)) + (ICON_SIDE_LENGTH * (index + 0.5));
		indicator.center = center;
	}
}

- (void)buttonPressed:(id)sender
{
    NSInteger buttonIndex = [sender tag];
    
    // Alert the delegate
	BOOL shouldMoveIndicator = YES;
    if (self.delegate) {
        shouldMoveIndicator = [self.delegate iconView:self didSelectItemAtIndex:buttonIndex];
    }
	
    // Update content offset and indicator
    [UIView animateWithDuration:.2 animations:^{
        // If the button selected is partially off the screen, adjust the content offset to bring it on the screen.
        CGRect buttonFrame = [sender frame];
        float offsetX = [self contentOffset].x;
        if (offsetX > buttonFrame.origin.x) {
            // Button is off the left of the screen
            [self setContentOffset:CGPointMake((buttonFrame.origin.x - SPACE), 0)];
        } else if ((buttonFrame.origin.x + buttonFrame.size.width) > offsetX + self.frame.size.width) {
            // Button is off the right of the screen
            [self setContentOffset:CGPointMake((buttonFrame.origin.x + buttonFrame.size.width + SPACE - self.frame.size.width), 0)];
        }
        
		if (shouldMoveIndicator) {
			CGPoint center = indicator.center;
			center.x = (SPACE * (buttonIndex + 1)) + (ICON_SIDE_LENGTH * (buttonIndex + 0.5));
			indicator.center = center;
		}
    }];
}


-(CGRect)getScreenBoundsForCurrentOrientation
{
    return [self getScreenBoundsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

-(CGRect)getScreenBoundsForOrientation:(UIInterfaceOrientation)orientation
{
    UIScreen *screen = [UIScreen mainScreen];
    CGRect fullScreenRect = screen.bounds; //implicitly in Portrait orientation.
    
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        CGRect temp;
        temp.size.width = fullScreenRect.size.height;
        temp.size.height = fullScreenRect.size.width;
        fullScreenRect = temp;
    }
    
    return fullScreenRect;
}

@end

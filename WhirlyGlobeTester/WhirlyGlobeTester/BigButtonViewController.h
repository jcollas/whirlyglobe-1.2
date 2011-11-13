//
//  BigButtonViewController.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 11/12/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BigButtonViewController;

// Fill this in to get notified when the big button is pushed
@protocol BigButtonDelegate <NSObject>
- (void)bigButtonPushed:(BigButtonViewController *)viewC;
@end

/** Big Button View Controller
    A view with a big old button.  For pressing.
 */
@interface BigButtonViewController : UIViewController
{
    NSObject<BigButtonDelegate> *delegate;
}

@property(nonatomic,assign) NSObject<BigButtonDelegate> *delegate;

// Use this to create one
+ (BigButtonViewController *)loadFromNib;

// Called when button pressed (shocking)
- (IBAction)buttonPress:(id)sender;

@end

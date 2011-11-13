//
//  AppDelegate.h
//  WhirlyGlobeTester
//
//  Created by Steve Gifford on 10/26/11.
//  Copyright (c) 2011 mousebird consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BigButtonViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,BigButtonDelegate>
{
    UINavigationController *navC;
}

@property (strong, nonatomic) UIWindow *window;

@end

//
//  WhirlyGlobeAppAppDelegate.h
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WhirlyGlobeAppViewController;

@interface WhirlyGlobeAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    WhirlyGlobeAppViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WhirlyGlobeAppViewController *viewController;

@end


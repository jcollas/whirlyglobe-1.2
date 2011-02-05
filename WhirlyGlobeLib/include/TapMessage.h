/*
 *  TapMessage.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/3/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <UIKit/UIKit.h>
#import "WhirlyVector.h"
#import "GlobeView.h"

// Message name for the notification center
#define WhirlyGlobeTapMsg @"WhirlyGlobeTap"

/* Tap Message
	Indication that the user tapped on the globe.
	Passed as the object in a notification.
 */
@interface TapMessage : NSObject
{
	WhirlyGlobe::GeoCoord whereGeo; // Lon/Lat
	Point3f worldLoc;  // Model coordinates
}

@property (nonatomic,assign) WhirlyGlobe::GeoCoord whereGeo;
@property (nonatomic,assign) Point3f worldLoc;

@end

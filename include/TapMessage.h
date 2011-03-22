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

// Message names for the notification center
#define WhirlyGlobeTapMsg @"WhirlyGlobeTap"
#define WhirlyGlobeLongPressMsg @"WhirlyGlobeLongPress"

/* Tap Message
	Indication that the user tapped on the globe.
	Passed as the object in a notification.
 */
@interface TapMessage : NSObject
{
	WhirlyGlobe::GeoCoord whereGeo; // Lon/Lat
	Point3f worldLoc;  // Model coordinates
    float heightAboveGlobe;   // Where the eye was.  0 is sea level.  Globe has a radius of 1.0
}

@property (nonatomic,assign) WhirlyGlobe::GeoCoord whereGeo;
@property (nonatomic,assign) Point3f worldLoc;
@property (nonatomic,assign) float heightAboveGlobe;

@end

/*
 *  TapMessage.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/3/11.
 *  Copyright 2011 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import <UIKit/UIKit.h>
#import "WhirlyVector.h"
#import "GlobeView.h"

// Message names for the notification center
#define WhirlyGlobeTapMsg @"WhirlyGlobeTap"
#define WhirlyGlobeTapOutsideMsg @"WhirlyGlobeTapOutside"
#define WhirlyGlobeLongPressMsg @"WhirlyGlobeLongPress"

/* Tap Message
	Indication that the user tapped on the globe.
	Passed as the object in a notification.
 */
@interface TapMessage : NSObject
{
    UIView *view;      // View that was touched
    CGPoint touchLoc;  // Touch location on view

	WhirlyGlobe::GeoCoord whereGeo; // Lon/Lat
	Point3f worldLoc;  // Model coordinates
    float heightAboveGlobe;   // Where the eye was.  0 is sea level.  Globe has a radius of 1.0
}

@property (nonatomic,retain) UIView *view;
@property (nonatomic,assign) CGPoint touchLoc;
@property (nonatomic,assign) WhirlyGlobe::GeoCoord whereGeo;
@property (nonatomic,assign) Point3f worldLoc;
@property (nonatomic,assign) float heightAboveGlobe;

@end

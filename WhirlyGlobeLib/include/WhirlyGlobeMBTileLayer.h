/*
 *  WhirlyGlobeMBTileLayer.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/24/12.
 *  Copyright 2011 mousebird consulting. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <math.h>
#import "WhirlyVector.h"
#import "TextureGroup.h"
#import "GlobeScene.h"
#import "DataLayer.h"
#import "RenderCache.h"
#import "LayerThread.h"
#import "GlobeMath.h"
#import "sqlhelpers.h"

/** WhirlyGlobe MBTiles is a simple wrapper for an MBTiles sqlite3
    database.
  */
@interface WhirlyGlobeMBTiles : NSObject
{
    sqlite3 *sqlDb;
    // Bounds in lat/lon
    WhirlyGlobe::GeoMbr geoMbr;
    // Bounds in Spherical Mercator
    WhirlyGlobe::Mbr mbr;
}

// Conversion from lat/lon to spherical mercator
+ (Point2f) geoToSphericalMercator:(WhirlyGlobe::GeoCoord &)geoCoord;

// Conversion from spherical mercator to lat/lon
+ (WhirlyGlobe::GeoCoord) sphericalMercatorToGeo:(Point2f &)coord;

/// Construct with a file name.  Will return nil on failure.
- (id)initWithName:(NSString *)fileName;

/// Read an image out for the given level, row, and column
/// This will return nil if there is no image.  This is common.
- (NSData *)fetchImageForLevel:(int)level col:(int)col row:(int)row;

@property (nonatomic,readonly) WhirlyGlobe::GeoMbr geoMbr;
@property (nonatomic,readonly) WhirlyGlobe::Mbr mbr;

@end

@interface WhirlyGlobeMBTileLayer : NSObject<WhirlyGlobeLayer>
{
    WhirlyGlobeLayerThread *layerThread;
	WhirlyGlobe::GlobeScene *scene;
    WhirlyGlobeMBTiles *mbTiles;
    unsigned int xDim,yDim;
    int chunkX,chunkY;
    int level;
}

- (id)initWithMBTiles:(WhirlyGlobeMBTiles *)mbTiles level:(int)level;

@end



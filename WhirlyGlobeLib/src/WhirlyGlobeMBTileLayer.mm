/*
 *  WhirlyGlobeMBTileLayer.mm
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

#import "WhirlyGlobeMBTileLayer.h"

using namespace Eigen;
using namespace WhirlyGlobe;

@implementation WhirlyGlobeMBTiles

@synthesize geoMbr;
@synthesize mbr;


// Conversion from lat/lon to spherical mercator
+ (Point2f) geoToSphericalMercator:(GeoCoord &)geoCoord
{
    Point2f pt;
    pt.x() = geoCoord.lon();
    pt.y() = logf(tanf(M_PI/4+geoCoord.lat()/2));
    
    return pt;
}

// Conversion from spherical mercator to lat/lon
+ (GeoCoord) sphericalMercatorToGeo:(Point2f &)coord
{
    GeoCoord geoCoord;
    geoCoord.lon() = coord.x();
    geoCoord.lat() = 2 * atanf(expf(coord.y())) - M_PI/2;
    
    return geoCoord;
}

- (id)initWithName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        // Open the sqlite DB
        if (sqlite3_open([fileName cStringUsingEncoding:NSASCIIStringEncoding],&sqlDb) != SQLITE_OK)
        {
            [self release];
            return nil;
        }
        
        // Look at the metadata
        sqlhelpers::StatementRead readStmt(sqlDb,@"select value from metadata where name='bounds';");
        if (!readStmt.stepRow())
        {
            [self release];
            return nil;
        }
        NSString *bounds = readStmt.getString();
        NSScanner *scan = [NSScanner scannerWithString:bounds];
        NSMutableCharacterSet *charSet = [[[NSMutableCharacterSet alloc] init] autorelease];
        [charSet addCharactersInString:@","];
        [scan setCharactersToBeSkipped:charSet];
        double ll_lat,ll_lon,ur_lat,ur_lon;
        if (![scan scanDouble:&ll_lon] ||
            ![scan scanDouble:&ll_lat] ||
            ![scan scanDouble:&ur_lon] ||
            ![scan scanDouble:&ur_lat])
        {
            [self release];
            return nil;
        }
        geoMbr.ll() = GeoCoord::CoordFromDegrees(ll_lon,ll_lat);
        geoMbr.ur() = GeoCoord::CoordFromDegrees(ur_lon,ur_lat);
        
        // And let's convert that over to spherical mercator
        mbr.ll() = [WhirlyGlobeMBTiles geoToSphericalMercator:geoMbr.ll()];
        mbr.ur() = [WhirlyGlobeMBTiles geoToSphericalMercator:geoMbr.ur()];
    }
    
    return self;
}

- (void)dealloc
{
    if (sqlDb)
        sqlite3_close(sqlDb);
    
    [super dealloc];
}

- (NSData *)fetchImageForLevel:(int)level col:(int)col row:(int)row
{
    sqlhelpers::StatementRead readStmt(sqlDb,[NSString stringWithFormat:@"SELECT tile_id from map where zoom_level='%d' AND tile_column='%d' AND tile_row='%d';",level,col,row]);
    if (!readStmt.stepRow())
        return nil;
    
    NSString *tile_id = readStmt.getString();
    sqlhelpers::StatementRead readStmt2(sqlDb,[NSString stringWithFormat:@"SELECT tile_data from images where tile_id='%@';",tile_id]);
    if (!readStmt2.stepRow())
        return nil;
    
    NSData *data = readStmt2.getBlob();
    
    return data;
}

@end

@interface WhirlyGlobeMBTileLayer()
@property (nonatomic,retain) WhirlyGlobeMBTiles *mbTiles;
@end

@implementation WhirlyGlobeMBTileLayer

@synthesize mbTiles;

- (id)initWithMBTiles:(WhirlyGlobeMBTiles *)inMbTiles level:(int)inLevel
{
    self = [super init];
    if (self)
    {
        self.mbTiles = inMbTiles;
        level = inLevel;
        xDim = yDim = 1<<level;    
        chunkX = chunkY = 0;
    }
    
    return self;
}

- (void)dealloc
{
    self.mbTiles = nil;
    
    [super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
    layerThread = inLayerThread;
	scene = inScene;
	[self performSelector:@selector(process:) withObject:nil];
}

// Tesselation for each chunk of the sphere
const int SphereTessX = 10, SphereTessY = 10;

- (void)process:(id)sender
{
    Mbr mbr = mbTiles.mbr;
    
    // Size of each chunk
    Point2f chunkSize((mbr.ur().x()-mbr.ll().x())/xDim,(mbr.ur().y()-mbr.ll().y())/yDim);
    
    // Unit size of each tesselation in spherical mercator
    Point2f incr(chunkSize.x()/SphereTessX,chunkSize.y()/SphereTessY);
    
    // Texture increment for each tesselation
    TexCoord texIncr(1.0/(float)SphereTessX,1.0/(float)SphereTessY);
    
	// We're viewing this as a parameterization from ([0->1.0],[0->1.0]) so we'll
	//  break up these coordinates accordingly
    Point2f paramSize(1.0/(xDim*SphereTessX),1.0/(yDim*SphereTessY));
    
    // We need the corners in geographic for the cullable
    Point2f chunkLL(chunkX*chunkSize.x()+mbr.ll().x(),chunkY*chunkSize.y()+mbr.ll().y());
    Point2f chunkUR((chunkX+1)*chunkSize.x()+mbr.ll().x(),(chunkY+1)*chunkSize.y()+mbr.ll().y());
    GeoCoord geoLL = [WhirlyGlobeMBTiles sphericalMercatorToGeo:chunkLL];
    GeoCoord geoUR = [WhirlyGlobeMBTiles sphericalMercatorToGeo:chunkUR];
    
	// We'll set up and fill in the drawable
	BasicDrawable *chunk = new BasicDrawable((SphereTessX+1)*(SphereTessY+1),2*SphereTessX*SphereTessY);
	chunk->setType(GL_TRIANGLES);
//	chunk->setType(GL_POINTS);
	chunk->setGeoMbr(GeoMbr(geoLL,geoUR));

    // Generate point, texture coords, and normals
    for (unsigned int iy=0;iy<SphereTessY+1;iy++)
        for (unsigned int ix=0;ix<SphereTessX+1;ix++)
        {
            // Location in spherical mercator for this particular point
            Point2f loc(chunkLL.x()+ix*incr.x(),chunkLL.y()+iy*incr.y());
            // Then convert to lat/lon and snap (probably not necessary)
            GeoCoord geoLoc = [WhirlyGlobeMBTiles sphericalMercatorToGeo:loc];
			if (geoLoc.x() < -M_PI)  geoLoc.x() = -M_PI;
			if (geoLoc.x() > M_PI) geoLoc.x() = M_PI;
			if (geoLoc.y() < -M_PI/2.0)  geoLoc.y() = -M_PI/2.0;
			if (geoLoc.y() > M_PI/2.0) geoLoc.y() = M_PI/2.0;
            // And on to the physical coordinate, which is conveniently the normal
            Point3f loc3D = PointFromGeo(geoLoc);
            
			// Do the texture coordinate seperately
			TexCoord texCoord(ix*texIncr.x(),1.0-iy*texIncr.y());
            
			chunk->addPoint(loc3D);
			chunk->addTexCoord(texCoord);
			chunk->addNormal(loc3D);
        }

	// Two triangles per cell
	for (unsigned int iy=0;iy<SphereTessY;iy++)
	{
		for (unsigned int ix=0;ix<SphereTessX;ix++)
		{
			BasicDrawable::Triangle triA,triB;
			triA.verts[0] = iy*(SphereTessX+1)+ix;
			triA.verts[1] = iy*(SphereTessX+1)+(ix+1);
			triA.verts[2] = (iy+1)*(SphereTessX+1)+(ix+1);
			triB.verts[0] = triA.verts[0];
			triB.verts[1] = triA.verts[2];
			triB.verts[2] = (iy+1)*(SphereTessX+1)+ix;
			chunk->addTriangle(triA);
			chunk->addTriangle(triB);
		}
	}
    
    // Now for the changes to the scenegraph
	std::vector<ChangeRequest *> changeRequests;

    // Texture first
    NSData *texData = [mbTiles fetchImageForLevel:level col:chunkX row:chunkY];
    UIImage *texImage = [UIImage imageWithData:texData];
    if (texImage)
    {
        Texture *tex = new Texture(texImage);
        changeRequests.push_back(new AddTextureReq(tex));
        chunk->setTexId(tex->getId());
    }

    // Then drawable
	changeRequests.push_back(new AddDrawableReq(chunk));
	scene->addChangeRequests(changeRequests);
    

    if (++chunkX >= xDim)
    {
        chunkX = 0;
        chunkY++;
    }
    
    // Schedule the next chunk
    if (chunkY < yDim)
        [self performSelector:@selector(process:) withObject:nil afterDelay:0.0];
    else {
        // We're done
        // Note: Notification would be good
    }
}

@end


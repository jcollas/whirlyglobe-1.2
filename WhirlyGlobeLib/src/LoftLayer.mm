/*
 *  LoftLayer.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 7/16/11.
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

#import "LoftLayer.h"
#import "GridClipper.h"
#import "Tesselator.h"
#import "UIColor+Stuff.h"
#import "NSDictionary+Stuff.h"

using namespace WhirlyGlobe;

// Used to describe the drawables we want to construct for a given vector
@interface LoftedPolyInfo : NSObject
{
@public
    SimpleIdentity sceneRepId;
    // For a creation request
    ShapeSet    shapes;
    UIColor     *color;
    NSString    *key;
    float       height;
    float       fade;
    float       minVis,maxVis;
    int         priority;
}

@property (nonatomic,retain) UIColor *color;
@property (nonatomic,retain) NSString *key;
@property (nonatomic,assign) float fade;

- (void)parseDesc:(NSDictionary *)desc key:(NSString *)key;

@end

@implementation LoftedPolyInfo

@synthesize color;
@synthesize key;
@synthesize fade;

- (id)initWithShapes:(ShapeSet *)inShapes desc:(NSDictionary *)desc key:(NSString *)inKey
{
    if ((self = [super init]))
    {
        if (inShapes)
            shapes = *inShapes;
        [self parseDesc:desc key:inKey];
    }
    
    return self;
}

- (id)initWithSceneRepId:(SimpleIdentity)inId desc:(NSDictionary *)desc
{
    if ((self = [super init]))
    {
        sceneRepId = inId;
        [self parseDesc:desc key:nil];
    }
    
    return self;
}

- (void)dealloc
{
    self.color = nil;
    self.key = nil;
    
    [super dealloc];
}

- (void)parseDesc:(NSDictionary *)dict key:(NSString *)inKey
{
    self.color = [dict objectForKey:@"color" checkType:[UIColor class] default:[UIColor whiteColor]];
    priority = [dict intForKey:@"priority" default:0];
    height = [dict floatForKey:@"height" default:.01];
    minVis = [dict floatForKey:@"minVis" default:DrawVisibleInvalid];
    maxVis = [dict floatForKey:@"maxVis" default:DrawVisibleInvalid];
    fade = [dict floatForKey:@"fade" default:0.0];
    self.key = inKey;
}

@end

namespace WhirlyGlobe
{
    
// Read the lofted poly representation from a cache file
// We're just saving the MBR and triangle mesh here
bool LoftedPolySceneRep::readFromCache(NSString *key)
{
    // Look for cache files in the doc and bundle dirs
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *bundleDir = [[NSBundle mainBundle] resourcePath];

    NSString *cache0 = [NSString stringWithFormat:@"%@/%@.loftcache",bundleDir,key];
    NSString *cache1 = [NSString stringWithFormat:@"%@/%@.loftcache",docDir,key];
    
    // Look for an existing file
    NSString *cacheFile = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cache0])
        cacheFile = cache0;
    else
        if ([fileManager fileExistsAtPath:cache1])
            cacheFile = cache1;
    
    if (!cacheFile)
        return false;

    // Let's try to read it
    FILE *fp = fopen([cacheFile cStringUsingEncoding:NSASCIIStringEncoding],"r");
    if (!fp)
        return false;

    try {
        // MBR first
        float ll_x,ll_y,ur_x,ur_y;
        if (fread(&ll_x,sizeof(float),1,fp) != 1 ||
            fread(&ll_y,sizeof(float),1,fp) != 1 ||
            fread(&ur_x,sizeof(float),1,fp) != 1 ||
            fread(&ur_y,sizeof(float),1,fp) != 1)
            throw 1;
        shapeMbr.addGeoCoord(GeoCoord(ll_x,ll_y));
        shapeMbr.addGeoCoord(GeoCoord(ur_x,ur_y));
        
        // Triangle meshes
        unsigned int numMesh = 0;
        if (fread(&numMesh,sizeof(unsigned int),1,fp) != 1)
            throw 1;
        triMesh.resize(numMesh);
        for (unsigned int ii=0;ii<numMesh;ii++)
        {
            VectorRing &ring = triMesh[ii];
            unsigned int numPt = 0;
            if (fread(&numPt,sizeof(unsigned int),1,fp) != 1)
                throw 1;
            ring.resize(numPt);
            for (unsigned int jj=0;jj<numPt;jj++)
            {
                Point2f &pt = ring[jj];
                float x,y;
                if (fread(&x,sizeof(float),1,fp) != 1 ||
                    fread(&y,sizeof(float),1,fp) != 1)
                    throw 1;
                pt.x() = x;
                pt.y() = y;                
            }
        }
        
        fclose(fp);  fp = NULL;
    }
    catch (...)
    {
        fclose(fp);
        fp = NULL;
        return false;
    }
    
    return true;
}
    
// Write the lofted poly representation to a cache
// Just the MBR and triangle mesh
bool LoftedPolySceneRep::writeToCache(NSString *key)
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *cacheFile = [NSString stringWithFormat:@"%@/%@.loftcache",docDir,key];

    FILE *fp = fopen([cacheFile cStringUsingEncoding:NSASCIIStringEncoding],"w");
    if (!fp)
        return false;
    
    try {
        // MBR first
        GeoCoord ll = shapeMbr.ll(), ur = shapeMbr.ur();
        if (fwrite(&ll.x(),sizeof(float),1,fp) != 1 ||
            fwrite(&ll.y(),sizeof(float),1,fp) != 1 ||
            fwrite(&ur.x(),sizeof(float),1,fp) != 1 ||
            fwrite(&ur.y(),sizeof(float),1,fp) != 1)
            throw 1;
        
        // Triangle meshes
        unsigned int numMesh = triMesh.size();
        if (fwrite(&numMesh,sizeof(unsigned int),1,fp) != 1)
            throw 1;
        for (unsigned int ii=0;ii<numMesh;ii++)
        {
            VectorRing &ring = triMesh[ii];
            unsigned int numPt = ring.size();
            if (fwrite(&numPt,sizeof(unsigned int),1,fp) != 1)
                throw 1;
            for (unsigned int jj=0;jj<numPt;jj++)
            {
                Point2f &pt = ring[jj];
                if (fwrite(&pt.x(),sizeof(float),1,fp) != 1 ||
                    fwrite(&pt.y(),sizeof(float),1,fp) != 1)
                    throw 1;
            }
        }
        
        fclose(fp);  fp = NULL;
    }
    catch (...)
    {
        fclose(fp);  fp = NULL;
        return false;
    }
    
    return true;
}
    
/* Drawable Builder
 Used to construct drawables with multiple shapes in them.
 Eventually, will move this out to be a more generic object.
 */
class DrawableBuilder2
{
public:
    DrawableBuilder2(GlobeScene *scene,LoftedPolySceneRep *sceneRep,
                     LoftedPolyInfo *polyInfo,const GeoMbr &inDrawMbr)
    : scene(scene), sceneRep(sceneRep), polyInfo(polyInfo), drawable(NULL)
    {
        primType = GL_TRIANGLES;
        drawMbr = inDrawMbr;
    }
    
    ~DrawableBuilder2()
    {
        flush();
    }
    
    // Initialize or flush a drawable, as needed
    void setupDrawable(int numToAdd)
    {
        if (!drawable || (drawable->getNumPoints()+numToAdd > MaxDrawablePoints))
        {
            // We're done with it, toss it to the scene
            if (drawable)
                flush();
            
            drawable = new BasicDrawable();
            drawable->setType(primType);
            // Adjust according to the vector info
            //            drawable->setOnOff(polyInfo->enable);
            //            drawable->setDrawOffset(vecInfo->drawOffset);
            drawable->setColor([polyInfo.color asRGBAColor]);
            drawable->setAlpha(true);
            //            drawable->setDrawPriority(vecInfo->priority);
            //            drawable->setVisibleRange(vecInfo->minVis,vecInfo->maxVis);
        }
    }
    
    // Add a triangle, keeping track of limits
    void addLoftTriangle(Point2f verts[3])
    {
        setupDrawable(3);
        
        int startVert = drawable->getNumPoints();
        for (unsigned int ii=0;ii<3;ii++)
        {
            // Get some real world coordinates and corresponding normal
            Point2f &geoPt = verts[ii];
            GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
            Point3f norm = PointFromGeo(geoCoord);
            Point3f pt1 = norm * (1.0 + polyInfo->height);
            
            drawable->addPoint(pt1);
            drawable->addNormal(norm);
        }
        
        BasicDrawable::Triangle tri;
        tri.verts[0] = startVert;
        tri.verts[1] = startVert+1;
        tri.verts[2] = startVert+2;
        drawable->addTriangle(tri);
    }

    // Add a whole mess of triangles, adding
    //  in the height
    void addPolyGroup(std::vector<VectorRing> &rings)
    {
        for (unsigned int ii=0;ii<rings.size();ii++)
        {
            VectorRing &tri = rings[ii];
            if (tri.size() == 3)
            {
                Point2f verts[3];
                verts[2] = tri[0];  verts[1] = tri[1];  verts[0] = tri[2];
                addLoftTriangle(verts);
            }
        }
    }
    
    void addSkirtPoints(VectorRing &pts)
    {            
        // Decide if we'll appending to an existing drawable or
        //  create a new one
        int ptCount = 4*(pts.size()+1);
        setupDrawable(ptCount);
        
        Point3f prevPt0,prevPt1,prevNorm,firstPt0,firstPt1,firstNorm;
        for (unsigned int jj=0;jj<pts.size();jj++)
        {
            // Get some real world coordinates and corresponding normal
            Point2f &geoPt = pts[jj];
            GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
            Point3f norm = PointFromGeo(geoCoord);
            Point3f pt0 = norm;
            Point3f pt1 = pt0 + norm * polyInfo->height;
                        
            // Add to drawable
            if (jj > 0)
            {
                int startVert = drawable->getNumPoints();
                drawable->addPoint(prevPt0);
                drawable->addPoint(prevPt1);
                drawable->addPoint(pt1);
                drawable->addPoint(pt0);

                // Normal points out
                Point3f crossNorm = norm.cross(pt1-prevPt1);
                crossNorm *= -1;
                
                drawable->addNormal(crossNorm);
                drawable->addNormal(crossNorm);
                drawable->addNormal(crossNorm);
                drawable->addNormal(crossNorm);
                
                BasicDrawable::Triangle triA,triB;
                triA.verts[0] = startVert+0;
                triA.verts[1] = startVert+1;
                triA.verts[2] = startVert+3;
                triB.verts[0] = startVert+1;
                triB.verts[1] = startVert+2;
                triB.verts[2] = startVert+3;
                
                drawable->addTriangle(triA);
                drawable->addTriangle(triB);
            } else {
                firstPt0 = pt0;
                firstPt1 = pt1;
                firstNorm = norm;
            }
            prevPt0 = pt0;  prevPt1 = pt1;
            prevNorm = norm;
        }
        
        // Close the loop
        if (primType == GL_LINES)
        {
            int startVert = drawable->getNumPoints();
            drawable->addPoint(prevPt0);
            drawable->addPoint(prevPt1);
            drawable->addPoint(firstPt1);
            drawable->addPoint(firstPt0);

            Point3f crossNorm = prevNorm.cross(firstPt1-prevPt1);
            crossNorm *= -1;
            drawable->addNormal(crossNorm);
            drawable->addNormal(crossNorm);
            drawable->addNormal(crossNorm);
            drawable->addNormal(crossNorm);

            BasicDrawable::Triangle triA,triB;
            triA.verts[0] = startVert+0;
            triA.verts[1] = startVert+1;
            triA.verts[2] = startVert+3;
            triB.verts[0] = startVert+1;
            triB.verts[1] = startVert+2;
            triB.verts[2] = startVert+3;
        }
    }
    
    void flush()
    {
        if (drawable)
        {
            if (drawable->getNumPoints() > 0)
            {
                drawable->setGeoMbr(drawMbr);
                sceneRep->drawIDs.insert(drawable->getId());
                if (polyInfo.fade > 0)
                {
                    NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
                    drawable->setFade(curTime,curTime+polyInfo.fade);
                }
                scene->addChangeRequest(new AddDrawableReq(drawable));
            } else
                delete drawable;
            drawable = NULL;
        }
    }
    
protected:   
    GlobeScene *scene;
    LoftedPolySceneRep *sceneRep;
    GeoMbr drawMbr;
    BasicDrawable *drawable;
    LoftedPolyInfo *polyInfo;
    GLenum primType;
};

}

@interface WGLoftLayer()

@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;

@end

@implementation WGLoftLayer

@synthesize layerThread;
@synthesize gridSize;
@synthesize useCache;

- (id)init
{
    if ((self = [super init]))
    {
        gridSize = 10.0 / 180.0 * M_PI;  // Default to 10 degrees
        useCache = NO;
    }
    
    return self;
}

- (void)dealloc
{
    self.layerThread = nil;
    for (LoftedPolySceneRepMap::iterator it = polyReps.begin();
         it != polyReps.end(); ++it)
        delete it->second;
    polyReps.clear();
    [super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
    self.layerThread = inLayerThread;
}

// From a scene rep and a description, add the given polygons to the drawable builder
- (void)addGeometryToBuilder:(LoftedPolySceneRep *)sceneRep polyInfo:(LoftedPolyInfo *)polyInfo drawMbr:(GeoMbr &)drawMbr
{
    int numShapes = 0;
    
    // Used to toss out drawables as we go
    // Its destructor will flush out the last drawable
    DrawableBuilder2 drawBuild(scene,sceneRep,polyInfo,drawMbr);
    
    // Toss in the polygons for the sides
    for (ShapeSet::iterator it = sceneRep->shapes.begin();
         it != sceneRep->shapes.end(); ++it)
    {
        VectorArealRef theAreal = boost::dynamic_pointer_cast<VectorAreal>(*it);
        if (theAreal.get())
        {
            for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
            {
                drawBuild.addSkirtPoints(theAreal->loops[ri]);
                numShapes++;
            }
        }
    }
    
    // Tweak the mesh polygons and toss 'em in
    drawBuild.addPolyGroup(sceneRep->triMesh);

//    printf("Added %d shapes and %d triangles from mesh\n",(int)numShapes,(int)sceneRep->triMesh.size());        
}

// Generate drawables for a lofted poly
- (void)runAddPoly:(LoftedPolyInfo *)polyInfo
{
    LoftedPolySceneRep *sceneRep = new LoftedPolySceneRep();
    sceneRep->setId(polyInfo->sceneRepId);
    sceneRep->fade = polyInfo.fade;
    polyReps[sceneRep->getId()] = sceneRep;
    
    sceneRep->shapes = polyInfo->shapes;
    
    // Try reading from the cache
    if (!useCache || !polyInfo.key || !sceneRep->readFromCache(polyInfo.key))
    {
        // If that fails, we'll regenerate everything
        for (ShapeSet::iterator it = polyInfo->shapes.begin();
             it != polyInfo->shapes.end(); ++it)
        {
            VectorArealRef theAreal = boost::dynamic_pointer_cast<VectorAreal>(*it);        
            if (theAreal.get())
            {            
                // Work through the loops
                for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
                {
                    VectorRing &ring = theAreal->loops[ri];					
                    
                    sceneRep->shapeMbr.addGeoCoords(ring);
                                                    
                    // Clip the polys for the top
                    std::vector<VectorRing> clippedMesh;
                    ClipLoopToGrid(ring,Point2f(0.f,0.f),Point2f(gridSize,gridSize),clippedMesh);

                    for (unsigned int ii=0;ii<clippedMesh.size();ii++)
                    {
                        VectorRing &ring = clippedMesh[ii];
                        // Tesselate the ring, even if it's concave (it's concave a lot)
                        TesselateRing(ring,sceneRep->triMesh);
                    }
                }
            }
        }
        
        // And save out to the cache if we're doing that
        if (useCache && polyInfo.key)
            sceneRep->writeToCache(polyInfo.key);
    }
    
//    printf("runAddPoly: handing off %d clipped loops to addGeometry\n",(int)sceneRep->triMesh.size());
    
    [self addGeometryToBuilder:sceneRep polyInfo:polyInfo drawMbr:sceneRep->shapeMbr];
}

// Change the visual representation of a lofted poly
- (void)runChangePoly:(LoftedPolyInfo *)polyInfo
{
    LoftedPolySceneRepMap::iterator it = polyReps.find(polyInfo->sceneRepId);
    if (it != polyReps.end())
    {
        LoftedPolySceneRep *sceneRep = it->second;

        // Clean out old geometry
        for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
             idIt != sceneRep->drawIDs.end(); ++idIt)
            scene->addChangeRequest(new RemDrawableReq(*idIt));
        sceneRep->drawIDs.clear();
        
        // And add the new back
        [self addGeometryToBuilder:sceneRep polyInfo:polyInfo drawMbr:sceneRep->shapeMbr];
    }
}

// Remove the lofted poly
- (void)runRemovePoly:(NSNumber *)num
{
    LoftedPolySceneRepMap::iterator it = polyReps.find([num intValue]);
    if (it != polyReps.end())
    {
        LoftedPolySceneRep *sceneRep = it->second;

        if (sceneRep->fade > 0.0)
        {
            NSTimeInterval curTime = [NSDate timeIntervalSinceReferenceDate];
            for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
                 idIt != sceneRep->drawIDs.end(); ++idIt)
                scene->addChangeRequest(new FadeChangeRequest(*idIt,curTime,curTime+sceneRep->fade));                
            
            // Reset the fade and try to delete again later
            [self performSelector:@selector(runRemovePoly:) withObject:num afterDelay:sceneRep->fade];
            sceneRep->fade = 0.0;            
        } else {
            for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
                 idIt != sceneRep->drawIDs.end(); ++idIt)
                scene->addChangeRequest(new RemDrawableReq(*idIt));
            polyReps.erase(it);
        
            delete sceneRep;
        }
    }
}

// Add a lofted poly
- (SimpleIdentity)addLoftedPolys:(ShapeSet *)shapes desc:(NSDictionary *)desc cacheName:(NSString *)cacheName
{
    LoftedPolyInfo *polyInfo = [[[LoftedPolyInfo alloc] initWithShapes:shapes desc:desc key:cacheName] autorelease];
    polyInfo->sceneRepId = Identifiable::genId();
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddPoly:polyInfo];
    else
        [self performSelector:@selector(runAddPoly:) onThread:layerThread withObject:polyInfo waitUntilDone:NO];
    
    return polyInfo->sceneRepId;
}

- (WhirlyGlobe::SimpleIdentity) addLoftedPoly:(WhirlyGlobe::VectorShapeRef)shape desc:(NSDictionary *)desc cacheName:(NSString *)cacheName
{
    ShapeSet shapes;
    shapes.insert(shape);
    
    return [self addLoftedPolys:&shapes desc:desc cacheName:(NSString *)cacheName];
}

// Change how the lofted poly is represented
- (void)changeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID desc:(NSDictionary *)desc
{
    LoftedPolyInfo *polyInfo = [[[LoftedPolyInfo alloc] initWithSceneRepId:polyID desc:desc] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runChangePoly:polyInfo];
    else
        [self performSelector:@selector(runChangePoly:) onThread:layerThread withObject:polyInfo waitUntilDone:NO];
}

// Remove the lofted poly
- (void)removeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID
{
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runRemovePoly:[NSNumber numberWithInt:polyID]];
    else
        [self performSelector:@selector(runRemovePoly:) onThread:layerThread withObject:[NSNumber numberWithInt:polyID] waitUntilDone:NO];
}

@end

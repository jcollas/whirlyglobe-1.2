//
//  LoftLayer.mm
//  WhirlyGlobeApp
//
//  Created by Stephen Gifford on 7/16/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import "LoftLayer.h"
#import "GridClipper.h"
#import "Tesselator.h"

using namespace WhirlyGlobe;

// Used to describe the drawables we want to construct for a given vector
@interface LoftedPolyInfo : NSObject
{
@public
    SimpleIdentity sceneRepId;
    // For a creation request
    ShapeSet    shapes;
    UIColor     *color;
    float       height;
}

@property (nonatomic,retain) UIColor *color;

- (void)parseDesc:(LoftedPolyDesc *)desc;

@end

@implementation LoftedPolyInfo

@synthesize color;

- (id)initWithShapes:(ShapeSet *)inShapes desc:(LoftedPolyDesc *)desc
{
    if ((self = [super init]))
    {
        if (inShapes)
            shapes = *inShapes;
        [self parseDesc:desc];
    }
    
    return self;
}

- (id)initWithSceneRepId:(SimpleIdentity)inId desc:(LoftedPolyDesc *)desc
{
    if ((self = [super init]))
    {
        sceneRepId = inId;
        [self parseDesc:desc];
    }
    
    return self;
}

- (void)dealloc
{
    self.color = nil;
    
    [super dealloc];
}

- (void)parseDesc:(LoftedPolyDesc *)desc
{
    self.color = desc.color;
    height = desc.height;
}

@end

namespace WhirlyGlobe
{
    
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
    
    // Add a whole mess of rings, presumably post-clip
    void addPolyGroup(std::vector<VectorRing> &rings)
    {
        for (unsigned int ii=0;ii<rings.size();ii++)
        {
            VectorRing &ring = rings[ii];
            // Tesselate the ring, even if it's concave (it's concave a lot)
            std::vector<VectorRing> triRings;
            TesselateRing(ring,triRings);
            for (unsigned int jj=0;jj<triRings.size();jj++)
            {
                VectorRing &thisTriRing = triRings[jj];
                Point2f verts[3];
                verts[2] = thisTriRing[0];  verts[1] = thisTriRing[1];  verts[0] = thisTriRing[2];
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
                scene->addChangeRequest(new AddDrawableReq(drawable));
                
//                printf("Adding drawable with %d points and %d triangles\n",(int)drawable->getNumPoints(),(int)drawable->getNumTris());
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

@implementation LoftedPolyDesc

@synthesize color;
@synthesize height;

- (void)dealloc
{
    self.color = nil;
    
    [super dealloc];
}

@end

@interface LoftLayer()

@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;

@end

@implementation LoftLayer

@synthesize layerThread;
@synthesize gridSize;

- (id)init
{
    if ((self = [super init]))
    {
        gridSize = 10.0 / 180.0 * M_PI;  // Default to 10 degrees
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
    polyReps[sceneRep->getId()] = sceneRep;
    
    sceneRep->shapes = polyInfo->shapes;

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
                ClipLoopToGrid(ring,Point2f(0.f,0.f),Point2f(gridSize,gridSize),sceneRep->triMesh);
            }
        }
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

        for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
             idIt != sceneRep->drawIDs.end(); ++idIt)
            scene->addChangeRequest(new RemDrawableReq(*idIt));
        polyReps.erase(it);
        
        delete sceneRep;
    }
}

// Add a lofted poly
- (SimpleIdentity)addLoftedPolys:(ShapeSet *)shapes desc:(LoftedPolyDesc *)desc
{
    LoftedPolyInfo *polyInfo = [[[LoftedPolyInfo alloc] initWithShapes:shapes desc:desc] autorelease];
    polyInfo->sceneRepId = Identifiable::genId();
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddPoly:polyInfo];
    else
        [self performSelector:@selector(runAddPoly:) onThread:layerThread withObject:polyInfo waitUntilDone:NO];
    
    return polyInfo->sceneRepId;
}

// Change how the lofted poly is represented
- (void)changeLoftedPoly:(WhirlyGlobe::SimpleIdentity)polyID desc:(LoftedPolyDesc *)desc
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

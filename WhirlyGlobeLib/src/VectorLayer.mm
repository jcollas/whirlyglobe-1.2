/*
 *  ShapeDisplay.mm
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/26/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import "WhirlyGeometry.h"
#import "VectorLayer.h"
#import "NSDictionary+Stuff.h"
#import "UIColor+Stuff.h"

using namespace WhirlyGlobe;

// Used to describe the drawable we'll construct for a given vector
@interface VectorInfo : NSObject
{
@public
    // The scene representation (for vectors) we're referring to
    SimpleIdentity              sceneRepId;
    // For creation request, the shapes
    ShapeSet                    shapes;
    BOOL                        enable;
    int                         drawOffset;
    UIColor                     *color;
    int                         priority;
    float                       minVis,maxVis;
}

@property (nonatomic,retain) UIColor *color;

- (void)parseDict:(NSDictionary *)dict;

@end

@implementation VectorInfo

@synthesize color;

- (id)initWithShapes:(ShapeSet *)inShapes desc:(NSDictionary *)dict
{
    if ((self = [super init]))
    {
        if (inShapes)
            shapes = *inShapes;
        [self parseDict:dict];
    }
    
    return self;
}

- (id)initWithSceneRepId:(SimpleIdentity)inId desc:(NSDictionary *)dict
{
    if ((self = [super init]))
    {
        sceneRepId = inId;
        [self parseDict:dict];
    }
    
    return self;
}

- (void)dealloc
{
    self.color = nil;
    
    [super dealloc];
}

- (void)parseDict:(NSDictionary *)dict
{
    enable = [dict boolForKey:@"enable" default:YES];
    drawOffset = [dict intForKey:@"drawOffset" default:1];
    self.color = [dict objectForKey:@"color" checkType:[UIColor class] default:[UIColor whiteColor]];
    priority = [dict intForKey:@"priority" default:0];
    minVis = [dict floatForKey:@"minVis" default:DrawVisibleInvalid];
    maxVis = [dict floatForKey:@"maxVis" default:DrawVisibleInvalid];
}

@end

namespace WhirlyGlobe
{
    
/* Drawable Builder
    Used to construct drawables with multiple shapes in them.
    Eventually, will move this out to be a more generic object.
 */
class DrawableBuilder
{
public:
    DrawableBuilder(GlobeScene *scene,VectorSceneRep *sceneRep,
                    VectorInfo *vecInfo,bool linesOrPoints)
    : scene(scene), sceneRep(sceneRep), vecInfo(vecInfo), drawable(NULL)
    {
        primType = (linesOrPoints ? GL_LINES : GL_POINTS);
    }
    
    ~DrawableBuilder()
    {
        flush();
    }
        
    void addPoints(VectorRing &pts)
    {            
        // Decide if we'll appending to an existing drawable or
        //  create a new one
        int ptCount = 2*(pts.size()+1);
        if (!drawable || (drawable->getNumPoints()+ptCount > MaxDrawablePoints))
        {
            // We're done with it, toss it to the scene
            if (drawable)
                flush();
                
            drawable = new BasicDrawable();
            drawMbr.reset();
            drawable->setType(GL_LINES);
            // Adjust according to the vector info
            drawable->setOnOff(vecInfo->enable);
            drawable->setDrawOffset(vecInfo->drawOffset);
            drawable->setColor([vecInfo.color asRGBAColor]);
            drawable->setDrawPriority(vecInfo->priority);
            drawable->setVisibleRange(vecInfo->minVis,vecInfo->maxVis);
        }
        drawMbr.addGeoCoords(pts);
            
        Point3f prevPt,prevNorm,firstPt,firstNorm;
        for (unsigned int jj=0;jj<pts.size();jj++)
        {
            // Convert to real world coordinates and offset from the globe
            Point2f &geoPt = pts[jj];
            GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
            Point3f norm = PointFromGeo(geoCoord);
            // Note: Should be reading this from the dictionary
            drawable->setDrawOffset(1);
            Point3f pt = norm;
            
            // Add to drawable
            // Depending on the type, we do this differently
            if (jj > 0)
            {
                drawable->addPoint(prevPt);
                drawable->addPoint(pt);
                drawable->addNormal(prevNorm);
                drawable->addNormal(norm);
            } else {
                firstPt = pt;
                firstNorm = norm;
            }
            prevPt = pt;
            prevNorm = norm;
        }
        
        // Close the loop
        drawable->addPoint(prevPt);
        drawable->addPoint(firstPt);
        drawable->addNormal(prevNorm);
        drawable->addNormal(firstNorm);
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
            } else
                delete drawable;
            drawable = NULL;
        }
    }
    
protected:   
    GlobeScene *scene;
    VectorSceneRep *sceneRep;
    GeoMbr drawMbr;
    BasicDrawable *drawable;
    VectorInfo *vecInfo;
    GLenum primType;
};

}

@interface VectorLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@end

@implementation VectorLayer

@synthesize layerThread;

- (void)dealloc
{
    self.layerThread = nil;
    for (VectorSceneRepMap::iterator it = vectorReps.begin();
         it != vectorReps.end(); ++it)
        delete it->second;
    vectorReps.clear();
	[super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
    self.layerThread = inLayerThread;
}

// Generate drawables.  We'll stack areas into as few drawables
//  as possible
- (void)runAddVector:(VectorInfo *)vecInfo
{
    VectorSceneRep *sceneRep = new VectorSceneRep(vecInfo->shapes);
    sceneRep->setId(vecInfo->sceneRepId);
    vectorReps[sceneRep->getId()] = sceneRep;
        
    // All the shape types should be the same
    ShapeSet::iterator first = vecInfo->shapes.begin();
    VectorPointsRef thePoints = boost::dynamic_pointer_cast<VectorPoints>(*first);
    bool linesOrPoints = (thePoints.get() ? false : true);
    
    // Used to toss out drawables as we go
    // Its destructor will flush out the last drawable
    DrawableBuilder drawBuild(scene,sceneRep,vecInfo,linesOrPoints);
    
    for (ShapeSet::iterator it = vecInfo->shapes.begin();
         it != vecInfo->shapes.end(); ++it)
    {
        VectorArealRef theAreal = boost::dynamic_pointer_cast<VectorAreal>(*it);        
        if (theAreal.get())
        {
            // Work through the loops
            for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
            {
                VectorRing &ring = theAreal->loops[ri];					

                drawBuild.addPoints(ring);
            }
        } else {
            VectorLinearRef theLinear = boost::dynamic_pointer_cast<VectorLinear>(*it);
            if (theLinear.get())
            {
                drawBuild.addPoints(theLinear->pts);
            } else {
                VectorPointsRef thePoints = boost::dynamic_pointer_cast<VectorPoints>(*it);
                if (thePoints.get())
                {
                    drawBuild.addPoints(thePoints->pts);
                }
            }
        }
    }        
}

// Change a vector representation according to the request
// We'll change color or enabled for now
- (void)runChangeVector:(VectorInfo *)vecInfo
{
    VectorSceneRepMap::iterator it = vectorReps.find(vecInfo->sceneRepId);
    
    if (it != vectorReps.end())
    {    
        VectorSceneRep *sceneRep = it->second;
        
        for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
             idIt != sceneRep->drawIDs.end(); ++idIt)
        {
            // Turned it on or off
            scene->addChangeRequest(new OnOffChangeRequest(*idIt, vecInfo->enable));
    
            // Changed color
            RGBAColor newColor = [vecInfo.color asRGBAColor];
            scene->addChangeRequest(new ColorChangeRequest(*idIt, newColor));
        }
    }
}

// Remove the vector (in the layer thread here)
- (void)runRemoveVector:(NSNumber *)num
{
    VectorSceneRepMap::iterator it = vectorReps.find((SimpleIdentity)[num intValue]);
    
    if (it != vectorReps.end())
    {
        VectorSceneRep *sceneRep = it->second;
    
        for (SimpleIDSet::iterator idIt = sceneRep->drawIDs.begin();
             idIt != sceneRep->drawIDs.end(); ++idIt)
            scene->addChangeRequest(new RemDrawableReq(*idIt));
        vectorReps.erase(it);
        
        delete sceneRep;
    }    
}

// Add a vector
// We make up an ID for it before it's actually created
- (SimpleIdentity)addVector:(WhirlyGlobe::VectorShapeRef)shape desc:(NSDictionary *)dict
{
    ShapeSet shapes;
    shapes.insert(shape);
    return [self addVectors:&shapes desc:dict];
}

// Add a group of vectors.  These will all be referred to by the same ID.
- (SimpleIdentity)addVectors:(ShapeSet *)shapes desc:(NSDictionary *)desc
{
    VectorInfo *vecInfo = [[[VectorInfo alloc] initWithShapes:shapes desc:desc] autorelease];
    vecInfo->sceneRepId = Identifiable::genId();
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddVector:vecInfo];
    else
        [self performSelector:@selector(runAddVector:) onThread:layerThread withObject:vecInfo waitUntilDone:NO];
    
    return vecInfo->sceneRepId;
}

// Change how the vector is represented
- (void)changeVector:(WhirlyGlobe::SimpleIdentity)vecID desc:(NSDictionary *)dict
{
    VectorInfo *vecInfo = [[[VectorInfo alloc] initWithSceneRepId:vecID desc:dict] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runChangeVector:vecInfo];
    else
        [self performSelector:@selector(runChangeVector:) onThread:layerThread withObject:vecInfo waitUntilDone:NO];
}

// Remove the vector
- (void)removeVector:(WhirlyGlobe::SimpleIdentity)vecID
{
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runRemoveVector:[NSNumber numberWithInt:vecID]];
    else
        [self performSelector:@selector(runRemoveVector:) onThread:layerThread withObject:[NSNumber numberWithInt:vecID] waitUntilDone:NO];
}

@end

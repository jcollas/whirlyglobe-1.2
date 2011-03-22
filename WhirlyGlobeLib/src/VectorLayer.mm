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
    WhirlyGlobe::VectorShape    *shape;
    BOOL                        enable;
    int                         drawOffset;
    UIColor                     *color;
    int                         priority;
    float                       minVis,maxVis;
    WhirlyGlobe::SimpleIdentity drawId;
}

@property (nonatomic,assign) WhirlyGlobe::VectorShape *shape;
@property (nonatomic,assign) BOOL enable;
@property (nonatomic,assign) int drawOffset;
@property (nonatomic,retain) UIColor *color;
@property (nonatomic,assign) int priority;
@property (nonatomic,assign) float minVis,maxVis;
@property (nonatomic,assign) WhirlyGlobe::SimpleIdentity drawId;

@end

@implementation VectorInfo

@synthesize shape;
@synthesize enable;
@synthesize drawOffset;
@synthesize color;
@synthesize priority;
@synthesize minVis,maxVis;
@synthesize drawId;

- (id)initWithShape:(WhirlyGlobe::VectorShape *)inShape desc:(NSDictionary *)dict
{
    if ((self = [super init]))
    {
        shape = inShape;
        enable = [dict boolForKey:@"enable" default:YES];
        drawOffset = [dict intForKey:@"drawOffset" default:1];
        self.color = [dict objectForKey:@"color" checkType:[UIColor class] default:[UIColor whiteColor]];
        priority = [dict intForKey:@"priority" default:0];
        minVis = [dict floatForKey:@"minVis" default:DrawVisibleInvalid];
        maxVis = [dict floatForKey:@"maxVis" default:DrawVisibleInvalid];
        drawId = EmptyIdentity;
    }
    
    return self;
}

- (void)dealloc
{
    self.color = nil;
    [super dealloc];
}

@end

@interface VectorLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@end

@implementation VectorLayer

@synthesize layerThread;

- (void)dealloc
{
    self.layerThread = nil;
	for (ShapeMap::iterator it = shapes.begin();it != shapes.end();++it)
		delete it->second;
	[super dealloc];
}

- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
	scene = inScene;
    self.layerThread = inLayerThread;
}

// Generate drawables, one per areal feature (for now)
- (void)runAddVector:(VectorInfo *)vecInfo
{
	VectorAreal *theAreal = dynamic_cast<VectorAreal *> (vecInfo.shape);
	if (!theAreal)
    {
        // If we're not going to represent it, we need to delete it
        delete vecInfo.shape;
		return;
    }
	
	BasicDrawable *drawable = new BasicDrawable();
	drawable->setType(theAreal->loops.size() > 1 ? GL_LINES : GL_LINE_LOOP);
	//				drawable->setType(GL_TRIANGLES);
	
	for (unsigned int ri=0;ri<theAreal->loops.size();ri++)
	{
		VectorRing &ring = theAreal->loops[ri];					
		
		Point3f prevPt,prevNorm,firstPt,firstNorm;
		for (unsigned int jj=0;jj<ring.size();jj++)
		{
			// Convert to real world coordinates and offset from the globe
			Point2f &geoPt = ring[jj];
			GeoCoord geoCoord = GeoCoord(geoPt.x(),geoPt.y());
			theAreal->geoMbr.addGeoCoord(geoCoord);
			Point3f norm = PointFromGeo(geoCoord);
			drawable->setDrawOffset(1);
			Point3f pt = norm;
			
			// Add to drawable
			// Depending on the type, we do this differently
			if (drawable->getType() == GL_LINES || drawable->getType() == GL_TRIANGLES)
			{
				if (jj > 0)
				{
#if 1
					drawable->addPoint(prevPt);
					drawable->addPoint(pt);
					drawable->addNormal(prevNorm);
					drawable->addNormal(norm);
#else
					drawable->addRect(prevPt,prevNorm,pt,norm,ShapeOffset);
#endif
				} else {
					firstPt = pt;
					firstNorm = norm;
				}
				prevPt = pt;
				prevNorm = norm;
			} else {
				drawable->addPoint(pt);
				drawable->addNormal(norm);
			}
		}
		
		// Close the loop
		if (drawable->getType() == GL_LINES || drawable->getType() == GL_TRIANGLES)
		{
#if 1
			drawable->addPoint(prevPt);
			drawable->addPoint(firstPt);
			drawable->addNormal(prevNorm);
			drawable->addNormal(firstNorm);
#else
			drawable->addRect(prevPt,prevNorm,firstPt,firstNorm,ShapeOffset/4.0);
#endif
		}
	}
	
	drawable->setGeoMbr(theAreal->geoMbr);
    
    // Adjust according to the vector info
    drawable->setOnOff(vecInfo.enable);
    drawable->setDrawOffset(vecInfo.drawOffset);
    drawable->setColor([vecInfo.color asRGBAColor]);
    drawable->setDrawPriority(vecInfo.priority);
    drawable->setId(vecInfo.drawId);
    drawable->setVisibleRange(vecInfo.minVis,vecInfo.maxVis);
		
	scene->addChangeRequest(new AddDrawableReq(drawable));
	
	// Keep track of this for later
	shapes[theAreal->getId()] = theAreal;
}

// Change a vector representation according to the request
// We'll change color or enabled for now
- (void)runChangeVector:(VectorInfo *)vecInfo
{
    // Turned it on or off
    scene->addChangeRequest(new OnOffChangeRequest(vecInfo.drawId, vecInfo.enable));
    
    // Changed color
    RGBAColor newColor = [vecInfo.color asRGBAColor];
    scene->addChangeRequest(new ColorChangeRequest(vecInfo.drawId, newColor));
}

// Remove the vector (in the layer thread here)
- (void)runRemoveVector:(NSNumber *)num
{
    WhirlyGlobe::SimpleIdentity vecID = [num intValue];
    ShapeMap::iterator it = shapes.find(vecID);
    if (it == shapes.end())
        return;
    
    scene->addChangeRequest(new RemDrawableReq(it->second->getDrawableId()));
    
    shapes.erase(it);
}

- (VectorShape *)findHitAtGeoCoord:(WhirlyGlobe::GeoCoord)geoCoord
{
    // Only call this in the layer thread
    if (layerThread && ([NSThread currentThread] != layerThread))
        return nil;
    
	// Look through the shapes for an interior point
	for (ShapeMap::iterator it = shapes.begin(); it != shapes.end(); ++it)
	{
		VectorAreal *theAreal = dynamic_cast<VectorAreal *>(it->second);
		if (theAreal && theAreal->geoMbr.inside(geoCoord))
		{
			for (unsigned int ii=0;ii<theAreal->loops.size();ii++)
				if (PointInPolygon(geoCoord,theAreal->loops[ii]))
					return theAreal;
		}
	}
	
	return nil;
}

// Add a vector
// We make up an ID for it before it's actually created
- (void)addVector:(WhirlyGlobe::VectorShape *)shape desc:(NSDictionary *)dict
{
    VectorInfo *vecInfo = [[[VectorInfo alloc] initWithShape:shape desc:dict] autorelease];
    vecInfo.drawId = Identifiable::genId();
    shape->setDrawableId(vecInfo.drawId);
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddVector:vecInfo];
    else
        [self performSelector:@selector(runAddVector:) onThread:layerThread withObject:vecInfo waitUntilDone:NO];
}

// Change how the vector is represented
- (void)changeVector:(WhirlyGlobe::SimpleIdentity)vecID desc:(NSDictionary *)dict
{
    ShapeMap::iterator it = shapes.find(vecID);
    if (it == shapes.end())
        return;
    
    VectorInfo *vecInfo = [[[VectorInfo alloc] initWithShape:it->second desc:dict] autorelease];
    vecInfo.drawId = it->second->getDrawableId();
    
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

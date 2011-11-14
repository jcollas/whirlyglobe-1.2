/*
 *  MarkerLayer.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 10/21/11.
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

#import "MarkerLayer.h"
#import "NSDictionary+Stuff.h"
#import "UIColor+Stuff.h"
#import "GlobeMath.h"

using namespace WhirlyGlobe;

@implementation WGMarker

@synthesize isSelectable;
@synthesize selectID;
@synthesize loc;
@synthesize width,height;
@synthesize texIDs;
@synthesize period;

- (id)init
{
    self = [super init];
    
    if (self)
    {
        isSelectable = false;
        selectID = EmptyIdentity;
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)addTexID:(WhirlyGlobe::SimpleIdentity)texID
{
    texIDs.push_back(texID);
}

@end

// Drawable that turns it self on and off at appropriate times
class TimedDrawable : public BasicDrawable
{
public:
    TimedDrawable() : startTime(0), period(0), onDuration(0) { }
    virtual ~TimedDrawable() { };
    
    // Set the period and on duration.  Start controls the offset.
    void setTimedVisibility(NSTimeInterval start,NSTimeInterval period,NSTimeInterval onDuration)
    {
        this->startTime = start;
        this->period = period;
        this->onDuration = onDuration;
    }
    
    // Decide when this on based on the time intervals
    virtual bool isOn(RendererFrameInfo *frameInfo) const
    {
        if (!BasicDrawable::isOn(frameInfo))
            return false;
        
        float since = frameInfo.currentTime - startTime;
        float where = fmod(since,period);
        
        return (where < onDuration);
    }
    
protected:
    NSTimeInterval startTime;
    NSTimeInterval period,onDuration;
};

@interface WGMarkerLayer()
@property (nonatomic,retain) WhirlyGlobeLayerThread *layerThread;
@end

// Used to pass marker information between threads
@interface MarkerInfo : NSObject
{
    NSArray         *markers;  // Individual marker objects
    UIColor         *color;
    int             drawOffset;
    float           minVis,maxVis;
    float           width,height;
    int             drawPriority;
    SimpleIdentity  markerId;
}

@property (nonatomic,retain) NSArray *markers;
@property (nonatomic,retain) UIColor *color;
@property (nonatomic,assign) int drawOffset;
@property (nonatomic,assign) float minVis,maxVis;
@property (nonatomic,assign) float width,height;
@property (nonatomic,assign) int drawPriority;
@property (nonatomic,assign) SimpleIdentity markerId;

- (id)initWithMarkers:(NSArray *)markers desc:(NSDictionary *)desc;

- (void)parseDesc:(NSDictionary *)desc;

@end

@implementation MarkerInfo

@synthesize markers;
@synthesize color;
@synthesize drawOffset;
@synthesize minVis,maxVis;
@synthesize width,height;
@synthesize drawPriority;
@synthesize markerId;

// Initialize with an array of makers and parse out parameters
- (id)initWithMarkers:(NSArray *)inMarkers desc:(NSDictionary *)desc
{
    self = [super init];
    
    if (self)
    {
        self.markers = inMarkers;
        [self parseDesc:desc];
        
        markerId = Identifiable::genId();
    }
    
    return self;
}

- (void)dealloc
{
    self.markers = nil;
    self.color = nil;
    
    [super dealloc];
}

- (void)parseDesc:(NSDictionary *)desc
{
    self.color = [desc objectForKey:@"color" checkType:[UIColor class] default:[UIColor whiteColor]];
    drawOffset = [desc intForKey:@"drawOffset" default:0];
    minVis = [desc floatForKey:@"minVis" default:DrawVisibleInvalid];
    maxVis = [desc floatForKey:@"maxVis" default:DrawVisibleInvalid];
    drawPriority = [desc intForKey:@"drawPriority" default:MarkerDrawPriority];
    width = [desc floatForKey:@"width" default:0.001];
    height = [desc floatForKey:@"height" default:0.001];
}

@end


@implementation WGMarkerLayer

@synthesize layerThread;
@synthesize selectLayer;

- (void)dealloc
{
    for (MarkerSceneRepSet::iterator it = markerReps.begin();
         it != markerReps.end(); ++it)
        delete *it;
    markerReps.clear();
    
    [super dealloc];
}

// Called in the layer thread
- (void)startWithThread:(WhirlyGlobeLayerThread *)inLayerThread scene:(WhirlyGlobe::GlobeScene *)inScene
{
    self.layerThread = inLayerThread;
    scene = inScene;    
}

// Add a bunch of markers at once
// We're in the layer thread here
- (void)runAddMarkers:(MarkerInfo *)markerInfo
{
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    MarkerSceneRep *markerRep = new MarkerSceneRep();
    markerRep->setId(markerInfo.markerId);
    markerReps.insert(markerRep);
    
    // Work through the markers
    TimedDrawable *draw = NULL;
    for (WGMarker *marker in markerInfo.markers)
    {
        // Do one per textures
        // Note: This is kind of horrible
        const std::vector<SimpleIdentity> &texIDs = marker.texIDs;
        int numInstances = texIDs.size();
        if (marker.period == 0.0)
            numInstances = 0;
        numInstances = std::max(1,numInstances);

        float duration = marker.period / numInstances;
        
        for (unsigned int ti=0;ti<numInstances;ti++)
        {
            SimpleIdentity texId = (texIDs.empty() ? EmptyIdentity : texIDs[ti]);
            
            // Note: One drawable per marker bad.  BAD!
            if (!draw || true)
            {
                if (draw)
                {
                    // Flush it out
                    scene->addChangeRequest(new AddDrawableReq(draw));
                }
                draw = new TimedDrawable();
                draw->setType(GL_TRIANGLES);
                draw->setDrawOffset(markerInfo.drawOffset);
                draw->setColor([markerInfo.color asRGBAColor]);
                draw->setDrawPriority(markerInfo.drawPriority);
                draw->setVisibleRange(markerInfo.minVis, markerInfo.maxVis);
                draw->setTexId(texId);
                markerRep->drawIDs.insert(draw->getId());
                
                // Note: Testing
                draw->setTimedVisibility(currentTime + ti*duration, marker.period, duration);
            }
            
            // Build the rectangle for this one
            float width2 = (marker.width == 0.0 ? markerInfo.width : marker.width)/2.0;
            float height2 = (marker.height == 0.0 ? markerInfo.height : marker.height)/2.0;
            
            Vector3f norm = PointFromGeo(marker.loc);
            Point3f center = norm;
            Vector3f up(0,0,1);
            Point3f horiz = up.cross(norm).normalized();
            Point3f vert = norm.cross(horiz).normalized();;        
            
            Point3f ll = center - width2*horiz - height2*vert;
            
            Point3f pts[4];
            pts[0] = ll;
            pts[1] = ll + 2 * width2 * horiz;
            pts[2] = ll + 2 * width2 * horiz + 2 * height2 * vert;
            pts[3] = ll + 2 * height2 * vert;
            
            TexCoord texCoord[4];
            texCoord[0].u() = 0.0;  texCoord[0].v() = 0.0;
            texCoord[1].u() = 1.0;  texCoord[1].v() = 0.0;
            texCoord[2].u() = 1.0;  texCoord[2].v() = 1.0;
            texCoord[3].u() = 0.0;  texCoord[3].v() = 1.0;
            
            // Toss the geometry into the drawable
            int vOff = draw->getNumPoints();
            for (unsigned int ii=0;ii<4;ii++)
            {
                Point3f &pt = pts[ii];
                draw->addPoint(pt);
                draw->addNormal(norm);
                draw->addTexCoord(texCoord[ii]);
                GeoMbr geoMbr = draw->getGeoMbr();
                geoMbr.addGeoCoord(marker.loc);
                draw->setGeoMbr(geoMbr);
            }
            
            draw->addTriangle(BasicDrawable::Triangle(0+vOff,1+vOff,2+vOff));
            draw->addTriangle(BasicDrawable::Triangle(2+vOff,3+vOff,0+vOff));
            
            // While we're at it, let's add this to the selection layer
            if (selectLayer && marker.isSelectable)
            {
                // If the marker doesn't already have an ID, it needs one
                if (!marker.selectID)
                    marker.selectID = Identifiable::genId();
                
                [selectLayer addSelectableRect:marker.selectID rect:pts];
            }
        }
    }
    
    // Flush out the last drawable
    if (draw)
        scene->addChangeRequest(new AddDrawableReq(draw));
}

// Remove the given marker(s)
- (void)runRemoveMarkers:(NSNumber *)num
{
    SimpleIdentity markerId = [num unsignedIntValue];
    
    MarkerSceneRep dummyRep;
    dummyRep.setId(markerId);
    MarkerSceneRepSet::iterator it = markerReps.find(&dummyRep);
    if (it != markerReps.end())
    {
        MarkerSceneRep *markerRep = *it;
        
        for (SimpleIDSet::iterator idIt = markerRep->drawIDs.begin();
             idIt != markerRep->drawIDs.end(); ++idIt)
            scene->addChangeRequest(new RemDrawableReq(*idIt));
        for (SimpleIDSet::iterator idIt = markerRep->texIDs.begin();
             idIt != markerRep->texIDs.end(); ++idIt)        
            scene->addChangeRequest(new RemTextureReq(*idIt));
        
        markerReps.erase(it);
        delete markerRep;
    }
}


// Add a single marker 
- (WhirlyGlobe::SimpleIdentity) addMarker:(WGMarker *)marker desc:(NSDictionary *)desc
{
    MarkerInfo *markerInfo = [[[MarkerInfo alloc] initWithMarkers:[NSArray arrayWithObject:marker] desc:desc] autorelease];
    
    if (!layerThread || ([NSThread currentThread] == layerThread))
        [self runAddMarkers:markerInfo];
    else
        [self performSelector:@selector(runAddMarkers:) onThread:layerThread withObject:markerInfo waitUntilDone:NO];
    
    return markerInfo.markerId;
}

// Remove a group of markers
- (void) removeMarkers:(WhirlyGlobe::SimpleIdentity)markerID
{
    NSNumber *num = [NSNumber numberWithUnsignedInt:markerID];
    if (!layerThread | ([NSThread currentThread] == layerThread))
        [self runRemoveMarkers:num];
    else
        [self performSelector:@selector(runRemoveMarkers:) onThread:layerThread withObject:num waitUntilDone:NO];
}


@end
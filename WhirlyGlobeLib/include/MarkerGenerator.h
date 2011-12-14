/*
 *  MarkerGenerator.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 11/21/11.
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

#import <math.h>
#import <set>
#import <map>
#import "Identifiable.h"
#import "Drawable.h"
#import "Generator.h"

namespace WhirlyGlobe
{
    
/** The Marker Generator produces geometry for individual markers on the
    rendering thread.  In general, you won't be interacting with this.
 */
class MarkerGenerator : public Generator 
{
public:
    MarkerGenerator();
    virtual ~MarkerGenerator();

    /// Generate the drawables for the given frame
    void generateDrawables(RendererFrameInfo *frameInfo,std::vector<Drawable *> &drawables);
    
    typedef std::map<SimpleIdentity,BasicDrawable *> DrawableMap;

    /** An individual marker contains the geometry we want to put on top
        of the globe at any given time.  These are only used when the marker
        will iterate through multiple textures over a given period.
      */
    class Marker : public Identifiable
    {
    public:
        /// Called by the marker generator build the geometry
        void addToDrawables(RendererFrameInfo *frameInfo,DrawableMap &drawables,float minZres);
        
        RGBAColor color;
        GeoCoord loc;
        Vector3f norm;
        Point3f pts[4];
        std::vector<std::vector<TexCoord> > texCoords;
        std::vector<SimpleIdentity> texIDs;
        NSTimeInterval start;
        NSTimeInterval period;
        int drawOffset;
        float minVis,maxVis;
    };

    /// Called by the renderer to add a marker from a layer
    void addMarker(Marker *marker);
    
    /// Called by the renderer to remove a marker
    void removeMarker(SimpleIdentity markerId);
    
protected:
    typedef std::set<Marker *,IdentifiableSorter> MarkerSet;
    MarkerSet markers;
};
    
/** The Marker Generator Add Request comes from the MarkerLayer and is
    routed through the renderer to the MarkerGenerator which keeps track
    of it.  Markers are then referred to by ID.
  */
class MarkerGeneratorAddRequest : public GeneratorChangeRequest
{
public:
    /// Construct with the marker generator's ID and the marker
    MarkerGeneratorAddRequest(SimpleIdentity genID,MarkerGenerator::Marker *marker);
    ~MarkerGeneratorAddRequest();
    
    virtual void execute2(GlobeScene *scene,Generator *gen);
    
protected:
    MarkerGenerator::Marker *marker;
};

/** A Marker Generator Remove Request comes form the MarkerLayer, is routed
    through the renderer and handed off to the MarkerGenerator.
  */
class MarkerGeneratorRemRequest : public GeneratorChangeRequest
{
public:
    // Construct with the marker generator's ID and the marker ID to remove
    MarkerGeneratorRemRequest(SimpleIdentity genID,SimpleIdentity markerID);
    ~MarkerGeneratorRemRequest();
    
    virtual void execute2(GlobeScene *scene,Generator *gen);
    
protected:
    SimpleIdentity markerID;
};
    
}
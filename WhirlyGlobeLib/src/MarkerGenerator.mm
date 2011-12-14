/*
 *  MarkerGenerator.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 12/14/11.
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

#import "MarkerGenerator.h"
#import "SceneRendererES1.h"

namespace WhirlyGlobe
{

// Add this marker to the appropriate drawable
void MarkerGenerator::Marker::addToDrawables(RendererFrameInfo *frameInfo,DrawableMap &drawables,float minZres)
{
    float visVal = frameInfo.globeView.heightAboveGlobe;
    if (!(minVis == DrawVisibleInvalid || maxVis == DrawVisibleInvalid ||
         ((minVis <= visVal && visVal <= maxVis) ||
          (maxVis <= visVal && visVal <= minVis))))
        return;
    
    // If it's pointed away from the user, don't bother
    if (norm.dot(frameInfo.globeView.eyeVec) < 0.0)
        return;
    
    float where = fmod(frameInfo.currentTime - start,period);
    int which = where/(float)period * texIDs.size();

    std::vector<TexCoord> &theTexCoords = texCoords[which];
    SimpleIdentity texID = texIDs[which];
    
    // Look for an existing Drawable or set one up
    DrawableMap::iterator it = drawables.find(texID);
    BasicDrawable *draw = NULL;
    if (it == drawables.end())
    {
        draw = new BasicDrawable();
        draw->setType(GL_TRIANGLES);
        draw->setTexId(texID);
        drawables[texID] = draw;
    } else
        draw = it->second;
    
    // Deal with a draw offset
    Point3f thePts[4];
    for (unsigned int ii=0;ii<4;ii++)
        thePts[ii] = pts[ii];
    if (drawOffset != 0)
    {        
		float scale = minZres*drawOffset;
		for (unsigned int ii=0;ii<4;ii++)
		{
			Vector3f pt = thePts[ii];
			thePts[ii] = norm * scale + pt;
		}
    }
    
    // Add the geometry to the drawable
    int vOff = draw->getNumPoints();
    for (unsigned int ii=0;ii<4;ii++)
    {
        draw->addPoint(thePts[ii]);
        draw->addNormal(norm);
        draw->addTexCoord(theTexCoords[ii]);
    }
    draw->addTriangle(BasicDrawable::Triangle(0+vOff,1+vOff,2+vOff));
    draw->addTriangle(BasicDrawable::Triangle(2+vOff,3+vOff,0+vOff));

    GeoMbr geoMbr = draw->getGeoMbr();
    geoMbr.addGeoCoord(loc);
    draw->setGeoMbr(geoMbr);
}

MarkerGenerator::MarkerGenerator()
{    
}
    
MarkerGenerator::~MarkerGenerator()
{
    for (MarkerSet::iterator it = markers.begin();
         it != markers.end(); ++it)
    {
        delete *it;
    }
    markers.clear();
}
    
void MarkerGenerator::addMarker(Marker *marker)
{
    markers.insert(marker);
}
    
void MarkerGenerator::removeMarker(SimpleIdentity markerId)
{
    Marker dummyMarker;
    dummyMarker.setId(markerId);
    MarkerSet::iterator it = markers.find(&dummyMarker);
    if (it != markers.end())
    {
        delete *it;
        markers.erase(it);
    }
}
    
void MarkerGenerator::generateDrawables(RendererFrameInfo *frameInfo, std::vector<Drawable *> &outDrawables)
{
    if (markers.empty())
        return;

    float minZres = [frameInfo.globeView calcZbufferRes];
    
    // Keep drawables sorted by destination teture ID
    DrawableMap drawables;
    
    // Work through the markers, asking each to generate its content
    for (MarkerSet::iterator it = markers.begin();
         it != markers.end(); ++it)
    {
        Marker *marker = *it;
        marker->addToDrawables(frameInfo,drawables,minZres);
    }

    // Copy the drawables out
    for (DrawableMap::iterator it = drawables.begin();
         it != drawables.end(); ++it)
        outDrawables.push_back(it->second);
}

MarkerGeneratorAddRequest::MarkerGeneratorAddRequest(SimpleIdentity genId,MarkerGenerator::Marker *marker)
    : GeneratorChangeRequest(genId), marker(marker)
{   
}
    
MarkerGeneratorAddRequest::~MarkerGeneratorAddRequest()
{
    if (marker)
        delete marker;
    marker = NULL;
}
    
void MarkerGeneratorAddRequest::execute2(GlobeScene *scene,Generator *gen)
{
    MarkerGenerator *markerGen = (MarkerGenerator *)gen;
    markerGen->addMarker(marker);
    marker = NULL;
}
    
MarkerGeneratorRemRequest::MarkerGeneratorRemRequest(SimpleIdentity genID,SimpleIdentity markerID)
    : GeneratorChangeRequest(genID), markerID(markerID)
{    
}
    
MarkerGeneratorRemRequest::~MarkerGeneratorRemRequest()
{    
}
    
void MarkerGeneratorRemRequest::execute2(GlobeScene *scene,Generator *gen)
{
    MarkerGenerator *markerGen = (MarkerGenerator *)gen;
    markerGen->removeMarker(markerID);
}

}

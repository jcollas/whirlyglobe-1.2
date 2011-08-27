/*
 *  Drawable.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 2/1/11.
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

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <vector>
#import <set>
#import "Identifiable.h"
#import "WhirlyVector.h"
#import "GlobeView.h"

using namespace Eigen;

namespace WhirlyGlobe
{
	
class GlobeScene;
	
/* Change Requests
	These are change requests made to the scene.
    The renderer will call them (via the scene) and they'll make
	their changes.  They're allowed to change the scene as whole,
	but most will modify a drawable.
 */
	
// Change Request base class
class ChangeRequest
{
public:
	ChangeRequest() { }
	virtual ~ChangeRequest() { }
		
	// Make a change to the scene
	virtual void execute(GlobeScene *scene,WhirlyGlobeView *view) = 0;
};	

/* Drawable
 Base class for all things to be drawn.
 */
class Drawable : public Identifiable
{
public:
	Drawable();
	virtual ~Drawable();
	
	// Return a geo MBR for sorting into cullables
	virtual GeoMbr getGeoMbr() const = 0;
	
	// We use this to sort drawables
	virtual unsigned int getDrawPriority() const = 0;
	
	// We're allowed to turn drawables off completely
	virtual bool isOn(WhirlyGlobeView *view) const = 0;
	
	// Do any OpenGL initialization you may want
	// For instance, set up VBOs
	// We pass in the minimum Z buffer resolution (for offsets)
	virtual void setupGL(float minZres) { };
	
	// Clean up any OpenGL objects you may have (e.g. VBOs)
	virtual void teardownGL() { };

	// Set up what you need in the way of context and draw
	virtual void draw(GlobeScene *scene) const = 0;	
    
    // Return true if the drawable has alpha.  These will be sorted last
    virtual bool hasAlpha() const = 0;
};

/* Drawable Change Request
	Base class for change requests that operate on Drawables.
 */
class DrawableChangeRequest : public ChangeRequest
{
public:
	DrawableChangeRequest(SimpleIdentity drawId) : drawId(drawId) { }
	~DrawableChangeRequest() { }
	
	// This will look for the drawable by ID and then call
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
	// This is called by execute if there's a drawable to modify
	// Fill this one in
	virtual void execute2(GlobeScene *scene,Drawable *draw) = 0;
	
protected:
	SimpleIdentity drawId;
};

// Turn off visibility checking
static const float DrawVisibleInvalid = 1e10;
    
// Maximum number of points we want in a drawable
static const unsigned int MaxDrawablePoints = ((1<<16)-1);

/* BasicDrawable
   Simple drawable object used to keep track of geometry.
   Also contains a reference to texture.
 */
class BasicDrawable : public Drawable
{
public:
	BasicDrawable();
	// Construct with some idea how big things are
	BasicDrawable(unsigned int numVert,unsigned int numTri);
	virtual ~BasicDrawable();

	// Set up the VBOs
	virtual void setupGL(float minZres);
	
	// Clean up the VBOs
	virtual void teardownGL();	
	
	// Draw this
	virtual void draw(GlobeScene *scene) const;
	
	// Draw priority
	virtual unsigned int getDrawPriority() const { return drawPriority; }
	
	// We use the on/off flag as well as a visibility check
	virtual bool isOn(WhirlyGlobeView *view) const;
	// true to turn it on, false to turn it off
	void setOnOff(bool onOff) { on = onOff; }
    
    // Used for alpha sorting
    virtual bool hasAlpha() const { return isAlpha; }
    void setAlpha(bool onOff) { isAlpha = onOff; }
	
	// Extents
	virtual GeoMbr getGeoMbr() const { return geoMbr; }
	
	// Set extents (don't forget this)
	void setGeoMbr(GeoMbr mbr) { geoMbr = mbr; }
	
	// Simple triangle.  Can obviously only have 2^16 vertices
	class Triangle
	{
	public:
		Triangle() { }
		Triangle(unsigned short v0,unsigned short v1,unsigned short v2) { verts[0] = v0;  verts[1] = v1;  verts[2] = v2; }
		unsigned short verts[3];
	};
	
	void setDrawPriority(unsigned int newPriority) { drawPriority = newPriority; }
	unsigned int getDrawPriority() { return drawPriority; }
	void setDrawOffset(unsigned int newOffset) { drawOffset = newOffset; }
	unsigned int getDrawOffset() { return drawOffset; }
	
	void setType(GLenum inType) { type = inType; }
	GLenum getType() const { return type; }
	void setTexId(SimpleIdentity inId) { texId = inId; }
	void setColor(RGBAColor inColor) { color = inColor; }
	void setColor(unsigned char inColor[]) { color.r = inColor[0];  color.g = inColor[1];  color.b = inColor[2];  color.a = inColor[3]; }
    RGBAColor getColor() const { return color; }
    void setVisibleRange(float minVis,float maxVis) { minVisible = minVis;  maxVisible = maxVis; }
    void getVisibleRange(float &minVis,float &maxVis) { minVis = minVisible;  maxVis = maxVisible; }
	
	unsigned int addPoint(Point3f pt) { points.push_back(pt); return points.size()-1; }
	void addTexCoord(TexCoord coord) { texCoords.push_back(coord); }
	void addNormal(Point3f norm) { norms.push_back(norm); }
	void addTriangle(Triangle tri) { tris.push_back(tri); }
    
    unsigned int getNumPoints() const { return points.size(); }
    unsigned int getNumTris() const { return tris.size(); }
    unsigned int getNumNorms() const { return norms.size(); }
    unsigned int getNumTexCoords() const { return texCoords.size(); }
	
	// Widen a line and turn it into a rectangle of the given width
	void addRect(const Point3f &l0, const Vector3f &ln0, const Point3f &l1, const Vector3f &ln1,float width);
		
protected:
	void drawReg(GlobeScene *scene) const;
	void drawVBO(GlobeScene *scene) const;
	
	bool on;  // If set, draw.  If not, not
	unsigned int drawPriority;  // Used to sort drawables
	unsigned int drawOffset;    // Number of units of Z buffer resolution to offset upward (by the normal)
    bool isAlpha;  // Set if we want to be drawn last
	GeoMbr geoMbr;  // Extents on the globe
	GLenum type;  // Primitive(s) type
	SimpleIdentity texId;  // ID for Texture (in scene)
	RGBAColor color;
    float minVisible,maxVisible;
    // We'll nuke the data arrays when we hand over the data to GL
    unsigned int numPoints, numTris;
	std::vector<Vector3f> points;
	std::vector<Vector2f> texCoords;
	std::vector<Vector3f> norms;
	std::vector<Triangle> tris;
	
	GLuint pointBuffer,texCoordBuffer,normBuffer,triBuffer;
};
	
// Change a given basic drawable's color
class ColorChangeRequest : public DrawableChangeRequest
{
public:
	ColorChangeRequest(SimpleIdentity drawId,RGBAColor color);
	
	void execute2(GlobeScene *scene,Drawable *draw);
	
protected:
	unsigned char color[4];
};
	
// Turn a given basic drawable on/off
class OnOffChangeRequest : public DrawableChangeRequest
{
public:
	OnOffChangeRequest(SimpleIdentity drawId,bool OnOff);
	
	void execute2(GlobeScene *scene,Drawable *draw);
	
protected:
	bool newOnOff;
};	
    
// Visibility distance change request
class VisibilityChangeRequest : public DrawableChangeRequest
{
public:
    VisibilityChangeRequest(SimpleIdentity drawId,float minVis,float maxVis);
    
    void execute2(GlobeScene *scene,Drawable *draw);
    
protected:
    float minVis,maxVis;
};

}

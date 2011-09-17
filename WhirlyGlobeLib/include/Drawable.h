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
	
/** This is the base clase for a change request.  Change requests
    are how we modify things in the scene.  The renderer is running
    on the main thread and we want to keep our interaction with it
    very simple.  So instead of deleting things or modifying them
    directly, we ask the renderer to do so through a change request.
 */
class ChangeRequest
{
public:
	ChangeRequest() { }
	virtual ~ChangeRequest() { }
		
	/// Make a change to the scene.  For the renderer.  Never call this.
	virtual void execute(GlobeScene *scene,WhirlyGlobeView *view) = 0;
};	

/** The Drawable base class.  Inherit from this and fill in the virtual
    methods.  In general, use the BasicDrawable.
 */
class Drawable : public Identifiable
{
public:
    /// Construct empty
	Drawable();
	virtual ~Drawable();
	
	/// Return a geo MBR for sorting into cullables
	virtual GeoMbr getGeoMbr() const = 0;
	
	/// We use this to sort drawables
	virtual unsigned int getDrawPriority() const = 0;
	
	/// We're allowed to turn drawables off completely
	virtual bool isOn(WhirlyGlobeView *view) const = 0;
	
	/// Do any OpenGL initialization you may want.
	/// For instance, set up VBOs.
	/// We pass in the minimum Z buffer resolution (for offsets).
	virtual void setupGL(float minZres) { };
	
	/// Clean up any OpenGL objects you may have (e.g. VBOs).
	virtual void teardownGL() { };

	/// Set up what you need in the way of context and draw.
	virtual void draw(GlobeScene *scene) const = 0;	
    
    /// Return true if the drawable has alpha.  These will be sorted last.
    virtual bool hasAlpha() const = 0;
};

/** Drawable Change Request is a subclass of the change request
    for drawables.  This is, itself, subclassed for specific
    change requests.
 */
class DrawableChangeRequest : public ChangeRequest
{
public:
    /// Construct with the ID of the Drawable we'll be changing
	DrawableChangeRequest(SimpleIdentity drawId) : drawId(drawId) { }
	~DrawableChangeRequest() { }
	
	/// This will look for the drawable by ID and then call execute2()
	void execute(GlobeScene *scene,WhirlyGlobeView *view);
	
	/// This is called by execute if there's a drawable to modify.
    /// This is the one you override.
	virtual void execute2(GlobeScene *scene,Drawable *draw) = 0;
	
protected:
	SimpleIdentity drawId;
};

/// Turn off visibility checking
static const float DrawVisibleInvalid = 1e10;
    
/// Maximum number of points we want in a drawable
static const unsigned int MaxDrawablePoints = ((1<<16)-1);

/** The Basic Drawable is the one we use the most.  It's
    a general purpose container for static geometry which
    may or may not be textured.
 */
class BasicDrawable : public Drawable
{
public:
    /// Construct empty
	BasicDrawable();
	/// Construct with some idea how big things are.
    /// You can violate this, but it will reserve space
	BasicDrawable(unsigned int numVert,unsigned int numTri);
	virtual ~BasicDrawable();

	/// Set up the VBOs
	virtual void setupGL(float minZres);
	
	/// Clean up the VBOs
	virtual void teardownGL();	
	
	/// Fill this in to draw the basic drawable
	virtual void draw(GlobeScene *scene) const;
	
	/// Draw priority
	virtual unsigned int getDrawPriority() const { return drawPriority; }
	
	/// We use the on/off flag as well as a visibility check
	virtual bool isOn(WhirlyGlobeView *view) const;
	/// True to turn it on, false to turn it off
	void setOnOff(bool onOff) { on = onOff; }
    
    /// Used for alpha sorting
    virtual bool hasAlpha() const { return isAlpha; }
    /// Set the alpha sorting on or off
    void setAlpha(bool onOff) { isAlpha = onOff; }
	
	/// Extents used for display culling
	virtual GeoMbr getGeoMbr() const { return geoMbr; }
	
	/// Set extents (don't forget this)
	void setGeoMbr(GeoMbr mbr) { geoMbr = mbr; }
	
	/// Simple triangle.  Can obviously only have 2^16 vertices
	class Triangle
	{
	public:
		Triangle() { }
        /// Construct with vertex IDs
		Triangle(unsigned short v0,unsigned short v1,unsigned short v2) { verts[0] = v0;  verts[1] = v1;  verts[2] = v2; }
		unsigned short verts[3];
	};

	/// Set the draw priority.  We sort by draw priority before rendering.
	void setDrawPriority(unsigned int newPriority) { drawPriority = newPriority; }
	unsigned int getDrawPriority() { return drawPriority; }

    /// Set the draw offset.  This is an integer offset from the base terrain.
    /// Geometry is moved upward by a certain number of units.
	void setDrawOffset(unsigned int newOffset) { drawOffset = newOffset; }
	unsigned int getDrawOffset() { return drawOffset; }

	/// Set the geometry type.  Probably triangles.
	void setType(GLenum inType) { type = inType; }
	GLenum getType() const { return type; }

    /// Set the texture ID.  You get this from the Texture object.
	void setTexId(SimpleIdentity inId) { texId = inId; }

    /// Set the color as an RGB color
	void setColor(RGBAColor inColor) { color = inColor; }

    /// Set the color as an array.
	void setColor(unsigned char inColor[]) { color.r = inColor[0];  color.g = inColor[1];  color.b = inColor[2];  color.a = inColor[3]; }
    RGBAColor getColor() const { return color; }

    /// Set what range we can see this drawable within.
    /// The units are in distance from the center of the globe and
    ///  the surface of the globe as at 1.0
    void setVisibleRange(float minVis,float maxVis) { minVisible = minVis;  maxVisible = maxVis; }
    
    /// Retrieve the visibile range
    void getVisibleRange(float &minVis,float &maxVis) { minVis = minVisible;  maxVis = maxVisible; }

	/// Add a point when building up geometry.  Returns the index.
	unsigned int addPoint(Point3f pt) { points.push_back(pt); return points.size()-1; }

    /// Add a texture coordinate.
	void addTexCoord(TexCoord coord) { texCoords.push_back(coord); }

    /// Add a normal
	void addNormal(Point3f norm) { norms.push_back(norm); }

    /// Add a triangle.  Should point to the vertex IDs.
	void addTriangle(Triangle tri) { tris.push_back(tri); }
    
    /// Return the number of points added so far
    unsigned int getNumPoints() const { return points.size(); }
    
    /// Return the number of triangles added so far
    unsigned int getNumTris() const { return tris.size(); }
    
    /// Return the number of normals added so far
    unsigned int getNumNorms() const { return norms.size(); }
    
    /// Return the number of texture coordinates added so far
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

/// Ask the renderer to change a drawable's color
class ColorChangeRequest : public DrawableChangeRequest
{
public:
	ColorChangeRequest(SimpleIdentity drawId,RGBAColor color);
	
	void execute2(GlobeScene *scene,Drawable *draw);
	
protected:
	unsigned char color[4];
};
	
/// Turn a given drawable on or off.  This doesn't delete it.
class OnOffChangeRequest : public DrawableChangeRequest
{
public:
	OnOffChangeRequest(SimpleIdentity drawId,bool OnOff);
	
	void execute2(GlobeScene *scene,Drawable *draw);
	
protected:
	bool newOnOff;
};	

/// Change the visibility distances for the given drawable
class VisibilityChangeRequest : public DrawableChangeRequest
{
public:
    VisibilityChangeRequest(SimpleIdentity drawId,float minVis,float maxVis);
    
    void execute2(GlobeScene *scene,Drawable *draw);
    
protected:
    float minVis,maxVis;
};

}

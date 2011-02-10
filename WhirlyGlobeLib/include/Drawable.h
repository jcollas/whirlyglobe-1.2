/*
 *  Drawable.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 2/1/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
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

namespace WhirlyGlobe
{
	
class GlobeScene;

// Just the globe, please
#define  BaseDrawPriority		0  
// Everything gets this to start
#define  DefaultDrawPriority	100  
#define Layer1DrawPriority		200
#define Layer2DrawPriority		300
#define Layer3DrawPriority		400
// We're sticking labels out here
#define LabelDrawPriority		1000  

/* Drawable
 Base class for all things to be drawn.
 */
class Drawable : public Identifiable
{
public:
	Drawable();
	virtual ~Drawable();
	
	// Set up what you need in the way of context and draw
	virtual void draw(GlobeScene *scene) const = 0;

	// Return a geo MBR for sorting into cullables
	virtual GeoMbr getGeoMbr() const = 0;
	
	// We use this to sort drawables
	virtual unsigned int getDrawPriority() const = 0;
	
	// We're allowed to turn drawables off completely
	virtual bool isOn() const = 0;
	
	// Do any OpenGL initialization you may want
	// For instance, set up VBOs
	virtual void setupGL() { };
	
	// Clean up any OpenGL objects you may have (e.g. VBOs)
	virtual void teardownGL() { };
};

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
	virtual void setupGL();
	
	// Clean up the VBOs
	virtual void teardownGL();	
	
	// Draw this
	virtual void draw(GlobeScene *scene) const;
	
	// Draw priority
	virtual unsigned int getDrawPriority() const { return drawPriority; }
	
	// We can turn drawables on/off individually
	virtual bool isOn() const { return on; }
	// true to turn it on, false to turn it off
	void setOnOff(bool onOff) { on = onOff; }
	
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
	
	void setType(GLenum inType) { type = inType; }
	GLenum getType() const { return type; }
	void setTexId(SimpleIdentity inId) { texId = inId; }
	void setColor(RGBAColor inColor) { color = inColor; }
	void setColor(unsigned char inColor[]) { color.r = inColor[0];  color.g = inColor[1];  color.b = inColor[2];  color.a = inColor[3]; }
	
	unsigned int addPoint(Point3f pt) { points.push_back(pt); return points.size()-1; }
	void addTexCoord(TexCoord coord) { texCoords.push_back(coord); }
	void addNormal(Point3f norm) { norms.push_back(norm); }
	void addTriangle(Triangle tri) { tris.push_back(tri); }
	
	// Widen a line and turn it into a rectangle of the given width
	void addRect(const Point3f &l0, const Vector3f &ln0, const Point3f &l1, const Vector3f &ln1,float width);
	
protected:
	void drawReg(GlobeScene *scene) const;
	void drawVBO(GlobeScene *scene) const;
	
	bool on;  // If set, draw.  If not, not
	unsigned int drawPriority;  // Used to sort drawables
	GeoMbr geoMbr;  // Extents on the globe
	GLenum type;  // Primitive(s) type
	SimpleIdentity texId;  // ID for Texture (in scene)
	RGBAColor color;
	std::vector<Vector3f> points;
	std::vector<Vector2f> texCoords;
	std::vector<Vector3f> norms;
	std::vector<Triangle> tris;
	
	GLuint pointBuffer,texCoordBuffer,normBuffer,triBuffer;
};

}

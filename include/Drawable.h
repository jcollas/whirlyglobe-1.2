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
#import "WhirlyVector.h"

namespace WhirlyGlobe
{
	
class GlobeScene;
	
// ID we'll pass around for scene objects
typedef unsigned long SimpleIdentity;
static const SimpleIdentity EmptyIdentity = 0;

// Simple unique ID base class
// We're not expecting very many of these at once
class Identifiable
{
public:
	// Construct with a new ID
	// Note: This may not work with multiple threads
	Identifiable() { static unsigned long curId = 0;  myId = ++curId; }
	virtual ~Identifiable() { }
	
	// Return the identity
	SimpleIdentity getId() const { return myId; }
	
protected:
	SimpleIdentity myId;
};

/* Texture
 Simple representation of texture.
 */
class Texture : public Identifiable
{
public:
	// Construct with raw texture data
	Texture(NSData *texData,bool isPVRTC) : texData(texData), isPVRTC(isPVRTC) { [texData retain]; glId = 0; }
	// Construct with a file name and extension
	Texture(NSString *baseName,NSString *ext);
	
	~Texture();
	
	GLuint getGLId() const { return glId; }
	
	// Create the openGL version
	bool createInGL(bool releaseData=true);
	
	// Destroy the openGL version
	void destroyInGL();

protected:
	// Raw texture data
	NSData *texData;
	// Need to know how we're going to load it
	bool isPVRTC;
	
	unsigned int width,height;
	
	// OpenGL ES ID
	// Set to 0 if we haven't loaded yet
	GLuint glId;
};

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
	
	// Extents
	virtual GeoMbr getGeoMbr() const { return geoMbr; }
	
	// Set extents (don't forget this)
	void setGeoMbr(GeoMbr mbr) { geoMbr = mbr; }
	
	// Simple triangle.  Can obviously only have 2^16 vertices
	typedef struct
	{
		unsigned short verts[3];
	} Triangle;
	
	void setType(GLenum inType) { type = inType; }
	GLenum getType() const { return type; }
	void setTexId(SimpleIdentity inId) { texId = inId; }
	void setColor(RGBAColor inColor) { color = inColor; }
	void setColor(unsigned char inColor[]) { color.r = inColor[0];  color.g = inColor[1];  color.b = inColor[2];  color.a = inColor[3]; }
	
	void addPoint(Point3f pt) { points.push_back(pt); }
	void addTexCoord(TexCoord coord) { texCoords.push_back(coord); }
	void addNormal(Point3f norm) { norms.push_back(norm); }
	void addTriangle(Triangle tri) { tris.push_back(tri); }
	
protected:
	void drawReg(GlobeScene *scene) const;
	void drawVBO(GlobeScene *scene) const;
	
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

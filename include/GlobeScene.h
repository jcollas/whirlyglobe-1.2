//
//  GlobeScene.h
//  WhirlyGlobeLib
//
//  Created by Stephen Gifford on 1/3/11.
//  Copyright 2011 mousebird consulting. All rights reserved.
//

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <vector>
#import <set>
#import "WhirlyVector.h"

namespace WhirlyGlobe {
		
/* Drawable
	Simple drawable object used to keep track of geometry.
	Also contains a reference to texture.
 */
class Drawable
{
public:
	Drawable() { };
	
	// Simple triangle.  Can obviously only have 2^16 vertices
	typedef struct
	{
		unsigned short verts[3];
	} Triangle;
	
	void addPoint(Point3f pt) { points.push_back(pt); }
	void addTexCoord(TexCoord coord) { texCoords.push_back(coord); }
	void addNormal(Point3f norm) { norms.push_back(norm); }
	void addTriangle(Triangle tri) { tris.push_back(tri); }
	
	void draw();
	
	GLenum type;  // Primitive(s) type
	GLuint textureId;
	std::vector<Vector3f> points;
	std::vector<Vector2f> texCoords;
	std::vector<Vector3f> norms;
	std::vector<Triangle> tris;
};
	
/* Cullable unit
	This is a representation of cullable geometry.  It has
     geometry/direction info and a list of associated
     Drawables.
    Cullables are always rectangles in lon/lat.
 */
class Cullable
{
public:
	// Construct with a geographic MBR
	Cullable(const GeoMbr &geoMbr);

	// Add the given drawable to our set
	void addDrawable(Drawable *drawable) { drawables.insert(drawable); }
	
	std::set<Drawable *> &getDrawables() { return drawables; }
	
public:
	// 3D locations (in model space) of the corners
	Point3f cornerPoints[4];
	// Normal vectors (in model space) for the corners
	Vector3f cornerNorms[4];
	// Geographic coordinates of our bounding box
	GeoMbr geoMbr;
	
	std::set<Drawable *> drawables;
};

/* GlobeScene
	Top level object used to keep track of a central globe and the
	drawables on top of it.
 */
class GlobeScene
{
public:
	GlobeScene() { }

	// Add to the display set
	// Caller is responsible for deletion
	void addCullable(Cullable *cullable) { cullables.insert(cullable); }
	
	std::set<Cullable *> &getCullables() { return cullables; }
	
protected:
	std::set<Cullable *> cullables;
};
	
}

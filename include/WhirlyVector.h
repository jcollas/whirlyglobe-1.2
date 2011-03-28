/*
 *  WhirlyVector.h
 *  WhirlyGlobeLib
 *
 *  Created by Stephen Gifford on 1/18/11.
 *  Copyright 2011 mousebird consulting. All rights reserved.
 *
 */

#import <Eigen/Eigen>

USING_PART_OF_NAMESPACE_EIGEN

typedef Vector3f Point3f;
typedef Vector2f Point2f;

namespace WhirlyGlobe
{
	
// Convenience wrapper for texture coordinate
class TexCoord : public Vector2f
{
public:
	TexCoord() { }
	TexCoord(float u,float v) : Vector2f(u,v) { }
	float u() const { return x(); }
	float &u() { return x(); }
	float v() const { return y(); }
	float &v() { return y(); }
};

// Convenience wrapper for geodetic coordinates
class GeoCoord : public Vector2f
{
public:
	GeoCoord() { }
	GeoCoord(float lon,float lat) : Vector2f(lon,lat) { }
	float lon() const { return x(); }
	float &lon() { return x(); }
	float lat() const { return y(); }
	float &lat() { return y(); }
	GeoCoord operator + (const GeoCoord &that) { return GeoCoord(x()+that.x(),y()+that.y()); }
};
	
// Color. RGBA, 8 bits per
class RGBAColor
{
public:
	RGBAColor() { }
	RGBAColor(unsigned char r,unsigned char g,unsigned char b,unsigned char a) : r(r), g(g), b(b), a(a) { }
	RGBAColor(unsigned char r,unsigned char g,unsigned char b) : r(r), g(g), b(b), a(255) { }
    
    bool operator == (RGBAColor &that) const { return (r == that.r && g == that.g && b == that.b && a == that.a); }
	
	unsigned char r,g,b,a;
};
	
// Bounding rectangle
class Mbr
{
public:
	Mbr() : pt_ll(0,0), pt_ur(-1,-1) { }
	Mbr(Point2f ll,Point2f ur) : pt_ll(ll), pt_ur(ur) { }
	// Construct from the MBR of a vector of points
	Mbr(const std::vector<Point2f> &pts);
	
	const Point2f &ll() const { return pt_ll; }
	Point2f &ll() { return pt_ll; }
	const Point2f &ur() const { return pt_ur; }
	Point2f &ur() { return pt_ur; }

	// Check validity
	bool valid() const { return pt_ur.x() >= pt_ll.x(); }
	
	// Calculate area
	float area() const;
	
	// Add the given point
	void addPoint(Point2f pt);
	
	// Check for overlap
	bool overlaps(const Mbr &that) const;
	
	// Point inside MBR
	bool inside(Point2f pt) const { return ((pt_ll.x() < pt.x()) && (pt_ll.y() < pt.y()) && (pt.x() < pt_ur.x()) && (pt.y() < pt_ur.y())); }
	
protected:
	Point2f pt_ll,pt_ur;
};
	
// Geographic MBR.
// Coordinates are restricted to [-180,-90]->[+180,+90]
class GeoMbr
{
public:
	GeoMbr() : pt_ll(-1000,-1000), pt_ur(-1000,-1000) { }
	GeoMbr(GeoCoord ll,GeoCoord ur) : pt_ll(ll), pt_ur(ur) { }
	// Construct from a list of coordinates
	GeoMbr(const std::vector<GeoCoord> &coords);
	// X is lon, Y is lat
	GeoMbr(const std::vector<Point2f> &pts);
    
    void reset() { pt_ll = GeoCoord(-1000,-1000);  pt_ur = GeoCoord(-1000,-1000); }
	
	const GeoCoord &ll() const { return pt_ll; }
	GeoCoord &ll() { return pt_ll; }
	const GeoCoord &ur() const { return pt_ur; }
	GeoCoord &ur() { return pt_ur; }
	GeoCoord lr() const { return GeoCoord(pt_ur.x(),pt_ll.y()); }
	GeoCoord ul() const { return GeoCoord(pt_ll.x(),pt_ur.y()); }
	
	// Mid point
	GeoCoord mid() const { return GeoCoord((pt_ll.x()+pt_ur.x())/2,(pt_ll.y()+pt_ur.y())/2); }
	
	bool valid() { return (pt_ll.x() != -1000); }

	// Calculate area
	// This is an approximation, treating the coordinates as Euclidean
	float area() const;
	
	// Expand the MBR by this amount
	void addGeoCoord(GeoCoord coord);
	
	// Expand by the vector of geo coords
	void addGeoCoords(const std::vector<GeoCoord> &coords);
	void addGeoCoords(const std::vector<Point2f> &coords);
	
	// Determine overlap.
	// This takes into account MBRs that wrap over -180/+180
	bool overlaps(const GeoMbr &that) const;
	
	// Single point check
	bool inside(GeoCoord coord) const;

protected:
	// Break into one or two MBRs
	void splitIntoMbrs(std::vector<Mbr> &mbrs) const;
	
	GeoCoord pt_ll,pt_ur;
};

}

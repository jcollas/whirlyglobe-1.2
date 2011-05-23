/*
 *  sqlhelpers.h
 *  SousVide
 *
 *  Created by Stephen Gifford on 9/8/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include <Foundation/Foundation.h>
#include "sqlite3.h"

namespace sqlhelpers
{

// Create the statement, run it, finalize it
// Kicks out an exception on failure
void OneShot(sqlite3 *,const char *);
// NSString version
void OneShot(sqlite3 *,NSString *);

/* Encapsulates a SQLite3 statement in a way that does not make me
    want to punch someone.
 */
class StatementRead
{
public:
	// Construct with the statement and maybe just run the damn thing
	StatementRead(sqlite3 *db,const char *,bool justRun=false);
	StatementRead(sqlite3 *db,NSString *,bool justRun=false);
	// Constructor will call finalize
	~StatementRead();
	
	// Calls step, expecting a row
	// Returns false if we're done, throws an exception on error
	bool stepRow();

	// You can force a finalize here
	void finalize();
	
	// Return an int from the current row
	int getInt();
	// Return a double from the current row
	double getDouble();	
	// Return an NSString from the current row
	NSString *getString();
	// Return a boolean from the current row
	BOOL getBool();
	
protected:
	void init(sqlite3 *db,const char *,bool justRun=false);
	
	sqlite3 *db;
	sqlite3_stmt *stmt;
	bool isFinalized;
	int curField;
};

/* This version is for an insert or update.
 */
class StatementWrite
{
public:
	StatementWrite(sqlite3 *db,const char *);
	StatementWrite(sqlite3 *db,NSString *);
	~StatementWrite();
	
	// Run the insert/update
	// Triggers an exception on failure
	void go();
	
	// Finalize it (optional)
	void finalize();
	
	// Add an integer
	void add(int);
	// Add a double
	void add(double);
	// Add a string
	void add(NSString *);
	// Add a boolean
	void add(BOOL);
	
protected:
	void init(sqlite3 *db,const char *);
	
	sqlite3_stmt *stmt;
	bool isFinalized;
	int curField;
};	

}

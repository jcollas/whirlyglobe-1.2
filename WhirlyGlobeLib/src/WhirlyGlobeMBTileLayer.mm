/*
 *  WhirlyGlobeMBTileLayer.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 1/24/12.
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

#import "WhirlyGlobeMBTileLayer.h"

@implementation WhirlyGlobeMBTiles

@synthesize mbr;

- (id)initWithName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        // Open the sqlite DB
        if (sqlite3_open([fileName cStringUsingEncoding:NSASCIIStringEncoding],&sqlDb) != SQLITE_OK)
        {
            [self release];
            return nil;
        }
        
        // Look at the metadata
        sqlhelpers::StatementRead readStmt(sqlDb,@"SELECT bounds from metadata;");
        if (!readStmt.stepRow())
        {
            [self release];
            return nil;
        }
        NSString *bounds = readStmt.getString();
        NSScanner *scan = [NSScanner scannerWithString:bounds];
        if (![scan scanFloat:&(mbr.ll().lon())] ||
            ![scan scanFloat:&mbr.ll().lat()] ||
            ![scan scanFloat:&mbr.ur().lon()] ||
            ![scan scanFloat:&mbr.ur().lat()])
        {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    if (sqlDb)
        sqlite3_close(sqlDb);
    
    [super dealloc];
}

- (NSData *)fetchImageForLevel:(int)level col:(int)col row:(int)row
{
    sqlhelpers::StatementRead readStmt(sqlDb,[NSString stringWithFormat:@"SELECT tile_id from map where zoom_level='%d' AND tile_column='%d' AND tile_row='%d';",level,col,row]);
    if (!readStmt.stepRow())
        return nil;
    
    NSString *tile_id = readStmt.getString();
    sqlhelpers::StatementRead readStmt2(sqlDb,[NSString stringWithFormat:@"SELECT tile_data where tile_id='%@';",tile_id]);
    if (!readStmt2.stepRow())
        return nil;
    
    NSData *data = readStmt2.getBlob();
    
    return data;
}

@end

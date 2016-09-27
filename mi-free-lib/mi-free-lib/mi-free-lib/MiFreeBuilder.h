//
//  MiFreeBuilder.h
//  mi-free-lib
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MiFreeBuilder : NSObject

-(id)init;

-(NSData*)getData;

-(void)appendByte:(uint8_t)byte;

-(void)appendInt:(uint32_t)Int;

-(void)appendString:(NSString*)string MaxLength:(int)length;

-(uint8_t)getCRC8;

@end

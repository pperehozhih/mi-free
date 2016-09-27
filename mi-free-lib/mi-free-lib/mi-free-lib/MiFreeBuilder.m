//
//  MiFreeBuilder.m
//  mi-free-lib
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import "MiFreeBuilder.h"

@implementation MiFreeBuilder {
   NSMutableData* _data;
}

//! Byte swap unsigned int
uint32_t swap_uint32( uint32_t val )
{
   val = ((val << 8) & 0xFF00FF00 ) | ((val >> 8) & 0xFF00FF );
   return (val << 16) | (val >> 16);
}

//! Byte swap int
int32_t swap_int32( int32_t val )
{
   val = ((val << 8) & 0xFF00FF00) | ((val >> 8) & 0xFF00FF );
   return (val << 16) | ((val >> 16) & 0xFFFF);
}

-(id)init {
   self = [super init];
   if (self) {
      _data = [[NSMutableData alloc] init];
   }
   return self;
}

-(NSData*)getData {
   return _data;
}

-(void)appendByte:(uint8_t)byte {
   [_data appendBytes:&byte length:1];
}

-(void)appendInt:(uint32_t)Int {
   [_data appendBytes:&Int length:sizeof(Int)];
}

-(void)appendString:(NSString*)string MaxLength:(int)length {
   if ([string length] >= length) {
      [_data appendBytes:[string UTF8String] length:length];
   } else {
      [_data appendBytes:[string UTF8String] length:[string length]];
      for (NSUInteger i = [string length]; i < length; i++) {
         char null = 0;
         [_data appendBytes:&null length:1];
      }
   }
}

-(uint8_t)getCRC8 {
   NSUInteger len = _data.length;
   const uint8_t *data = _data.bytes;
   uint8_t crc = 0;
   while (len--) {
      uint8_t extract = *data++;
      for (uint8_t tempI = 8; tempI; tempI--) {
         uint8_t sum = (crc ^ extract) & 0x01;
         crc >>= 1;
         if (sum) {
            crc ^= 0x8C;
         }
         extract >>= 1;
      }
   }
   return crc;
}

@end

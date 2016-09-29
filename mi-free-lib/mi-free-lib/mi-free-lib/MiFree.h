//
//  MiFree.h
//  mi-free-lib
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GregorianCalendar : NSObject

@property NSInteger year;
@property NSInteger month;
@property NSInteger day;
@property NSInteger hour;
@property NSInteger minute;
@property NSInteger second;

-(id)initFromData:(NSData*)data Offset:(int)offset;

-(id)initFromDate:(NSDate*)date;

-(NSData*)toData;

-(NSString*)description;

@end

typedef enum : NSUInteger {
   MiFreeUserInfoWoman = 0,
   MiFreeUserInfoMan
} MiFreeUserInfoGender;

@interface MiFreeAcitivityData : NSObject

@property int category;
@property int intensity;
@property int steps;

@end

@interface MiFreeAcitivityDataDay : NSObject

@property (readonly, nonatomic) NSArray*           info;
@property (readonly, nonatomic) GregorianCalendar* date;
@property (readonly, nonatomic) int                length;

-(id)initFromDate:(GregorianCalendar*)date Length:(int)length;

-(void)appendInfo:(MiFreeAcitivityData*)info;

-(BOOL)appendData:(NSData*)data;

-(void)parseData;

@end

@interface MiFreeDevice : NSObject

/*
 Name of device
*/
@property (nonatomic,readonly) NSString* name;
/*
 Mac address of device
*/
@property (nonatomic,readonly) NSString* mac;

@property (nonatomic,readonly) int                 profile_version;
@property (nonatomic,readonly) int                 fw_version;
@property (nonatomic,readonly) int                 hw_version;
@property (nonatomic,readonly) int                 appearance;
@property (nonatomic,readonly) int                 feature;
@property (nonatomic,readonly) int                 fw2_version;
@property (nonatomic,readonly) uint8_t             correction;
@property (nonatomic,readonly) GregorianCalendar*  date;

-(BOOL)isMili1;

-(BOOL)isMili1A;

-(BOOL)isAmazFit;

-(BOOL)isMili1S;

-(BOOL)isMiliPro;

-(BOOL)isReady;

@end

@interface MiFreeUserInfo : NSString

@property (nonatomic, retain, readwrite) NSString* nick;
@property NSInteger uid;
@property NSInteger gender;
@property NSInteger age;
@property NSInteger height;
@property NSInteger weight;
@property NSInteger type;

-(id)init;

-(id)initFromData:(NSData*)data;

-(NSData*)getData:(MiFreeDevice*)device;

@end

@protocol MiFreeDelegate <NSObject>;

@required

/*!
@function foundDevice callback for found device
@param device
@result need to connect device
*/
-(BOOL)foundDevice:(MiFreeDevice*) device;

@optional

/*!
 @function updateStep update step info
 @param step count of step
 */
-(void)updateStep:(int) step;

/*!
 @function updateCharge update charge info
 @param percent percent of charge
 */
-(void)updateCharge:(int) percent;

/*!
 @function bluetoothEnabled callback of enabled bluetooth
 */
-(void)bluetoothEnabled;

/*!
 @function bluetoothDisabled callback of disabled bluetooth
 */
-(void)bluetoothDisabled;

/*!
 @function connectedToDevice callback after connect device
 @param decide
 */
-(void)connectedToDevice:(MiFreeDevice*)device;

/*!
 @function disconnectedFromDevice callback after disconnect device
 @param device
 @param error
 */
-(void)disconnectedFromDevice:(MiFreeDevice*)device Error:(NSError*)error;

/*!
 @function activityUpdate update current activity
 @param activity current activity
 */
-(void)activityUpdate:(MiFreeAcitivityDataDay*)activity;

@end

@interface MiFree : NSObject

-(id)initWithDelegate:(id<MiFreeDelegate>) delegate AutoConnect:(BOOL) autoconnect;

-(void)searchDevices;

-(void)connectToDevice:(MiFreeDevice*)device;

-(void)disconnectFromDevice;

-(void)getCurrentActivity;

-(void)vibrate;

-(void)stopMotor;

-(void)test;

-(void)readStatistic;

-(void)login:(MiFreeUserInfo*)userInfo;

@end

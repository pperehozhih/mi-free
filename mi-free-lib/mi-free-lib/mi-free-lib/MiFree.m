//
//  MiFree.m
//  mi-free-lib
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import "MiFree.h"
#import "MiFreeBuilder.h"
#import <CoreBluetooth/CoreBluetooth.h>
static NSString* const kMiFreeUUIDDeviceInfoKey = @"FF01";
static NSString* const kMiFreeUUIDUserInfoKey   = @"FF04";
static NSString* const kMiFreeUUIDControlKey    = @"FF05";
static NSString* const kMiFreeUUIDStepKey       = @"FF06";
static NSString* const kMiFreeUUIDActivityKey   = @"FF07";
static NSString* const kMiFreeUUIDDateTimeKey   = @"FF0A";
static NSString* const kMiFreeUUIDChargedKey    = @"FF0C";
static NSString* const kMiFreeUUIDTestKey       = @"FF0D";
static NSString* const kMiFreeUUIDSensorKey     = @"FF0E";
static NSString* const kMiFreeUUIDPairKey       = @"FF0F";
static NSString* const kMiFreeUUIDVibarateKey   = @"2A06";
static NSString* const kMiFreeUUIDStatisticKey  = @"FF0B";

static NSString* const kMiFreeUUIDAcitityDescKey= @"2902";

static int const kMiFreeActivityDataMetaLen     = 11;
//static int const kMiFreeModeRegularDataLenByte  = 0;
static int const kMiFreeModeRegularDataLenMinute= 1;

@implementation GregorianCalendar

@synthesize year     = _year;
@synthesize month    = _month;
@synthesize day      = _day;
@synthesize hour     = _hour;
@synthesize minute   = _minute;
@synthesize second   = _second;

-(id)initFromData:(NSData*)data Offset:(int)offset {
   self = [super init];
   if (self) {
      _year    = ((uint8_t*)data.bytes)[offset + 0] + 2000;
      _month   = ((uint8_t*)data.bytes)[offset + 1];
      _day     = ((uint8_t*)data.bytes)[offset + 2];
      _hour    = ((uint8_t*)data.bytes)[offset + 3];
      _minute  = ((uint8_t*)data.bytes)[offset + 4];
      _second  = ((uint8_t*)data.bytes)[offset + 5];
   }
   return self;
}

-(id)initFromDate:(NSDate*)date {
   self = [super init];
   if (self) {
      NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
      NSDateComponents* components = [calendar components:
                                      NSCalendarUnitDay |
                                      NSCalendarUnitYear |
                                      NSCalendarUnitMonth |
                                      NSCalendarUnitHour |
                                      NSCalendarUnitMinute |
                                      NSCalendarUnitSecond
                                                 fromDate:date];
      _year    = components.year;
      _month   = components.month;
      _day     = components.day;
      _hour    = components.hour;
      _minute  = components.minute;
      _second  = components.second;
   }
   return self;
}

-(NSData*)toData {
   MiFreeBuilder* builder = [[MiFreeBuilder alloc] init];
   [builder appendByte:_year - 2000];
   [builder appendByte:_month];
   [builder appendByte:_day];
   [builder appendByte:_hour];
   [builder appendByte:_minute];
   [builder appendByte:_second];
   return [builder getData];
}

-(NSString*)description {
   return [NSString stringWithFormat: @"%ld.%ld.%ld %ld:%ld:%ld",
           _year, _month, _day, _hour, _minute, _second];
}

@end

@implementation MiFreeUserInfo

@synthesize nick     = _nick;
@synthesize age      = _age;
@synthesize type     = _type;
@synthesize height   = _height;
@synthesize weight   = _weight;
@synthesize gender   = _gender;
@synthesize uid      = _uid;

-(id)init {
   self = [super init];
   if (self) {
      _nick    = [[NSString alloc] init];
      _age     = 0;
      _type    = 0;
      _height 	= 0;
      _weight  = 0;
      _gender  = 0;
      _uid     = 0;
   }
   return self;
}

-(NSData*)getData:(MiFreeDevice*)device {
   MiFreeBuilder* build = [[MiFreeBuilder alloc] init];
   [build appendInt:_uid];
   [build appendByte:_gender];
   [build appendByte:_age];
   [build appendByte:_height];
   [build appendByte:_weight];
   [build appendByte:_type];
   int alias_from = 9;
//   if ([device isMili1]) {
      [build appendByte:device.feature & 255];
      [build appendByte:device.appearance & 255];
      alias_from = 11;
//   }
   [build appendString: _nick MaxLength:19 - alias_from];
   uint8_t crc = [build getCRC8];
   crc = (crc ^ device.correction) & 255;
   [build appendByte:crc];
   return [build getData];
}

-(id)initFromData:(NSData*)data {
   self = [super init];
   if (self == nil || data.length < 9) {
      uint8_t* _data = (uint8_t*)data.bytes;
      _uid = _data[3] << 24 | (_data[2] & 0xFF) << 16 | (_data[1] & 0xFF) << 8 | (_data[0] & 0xFF);
      _gender = _data[4];
      _age = _data[5];
      _height = _data[6];
      _weight = _data[7];
      _type = _data[data.length - 1];
      if (data.length == 9) {
         _nick = @"";
      } else {
         char nick_data[255] = {0};
         [data getBytes:&nick_data range:NSMakeRange(8, data.length - 9)];
         _nick = [NSString stringWithUTF8String:nick_data];
      }
   }
   return self;
}

-(NSString*)description {
   return [NSString stringWithFormat:@"uuid = %d gender %@ age = %d height = %d weight = %d",
           _uid, _gender == 0 ? @"man" : @"woman",
           _age, _height, _weight];
}

@end

@implementation MiFreeAcitivityData

@synthesize category    = _category;
@synthesize steps       = _steps;
@synthesize intensity   = _intensity;

@end

@implementation MiFreeAcitivityDataDay {
   NSMutableArray*   _info;
   NSMutableData*    _data;
   int               _length;
}

@synthesize date = _date;
@synthesize info = _info;

-(id)initFromDate:(GregorianCalendar*)date Length:(int)length{
   self = [super init];
   if (self) {
      _date = date;
      _data = nil;
      _info = [[NSMutableArray alloc] init];
      _length = length;
   }
   return self;
}

-(void)appendInfo:(MiFreeAcitivityData*)info {
   [_info addObject:info];
}

-(BOOL)appendData:(NSData*)data {
   if (_data == nil) {
      _data = [[NSMutableData alloc] init];
   }
   [_data appendData:data];
   return [_data length] == _length;
}

-(void)parseData {
   if (_data == nil) return;
   NSUInteger length = [_data length];
   uint8_t* data = (uint8_t*)[_data bytes];
   for (uint32_t index = 0; index < length; index += 3) {
      MiFreeAcitivityData* result = [[MiFreeAcitivityData alloc] init];
      result.category  = data[index];
      result.intensity = data[index + 1];
      result.steps     = data[index + 2];
      [self appendInfo: result];
   }
}

@end

@implementation MiFreeDevice {
   CBPeripheral*           _peripheral;
   CBCharacteristic*       _control;
   CBCharacteristic*       _activity_data;
   CBCharacteristic*       _test_char;
   CBCharacteristic*       _vibrate;
   CBCharacteristic*       _user_info;
   CBCharacteristic*       _date_time;
   MiFreeAcitivityDataDay* _day_data;
   NSString*               _device_id;
   int                     _profile_version;
   int                     _fw_version;
   int                     _hw_version;
   int                     _appearance;
   int                     _feature;
   int                     _fw2_version;
   uint8_t                 _correction;
   GregorianCalendar*      _date;
}
@synthesize name              = _name;
@synthesize mac               = _mac;
@synthesize profile_version   = _profile_version;
@synthesize fw_version        = _fw_version;
@synthesize hw_version        = _hw_version;
@synthesize appearance        = _appearance;
@synthesize feature           = _feature;
@synthesize fw2_version       = _fw2_version;
@synthesize correction        = _correction;
@synthesize date              = _date;

-(id)init {
   self = [super init];
   if (self) {
      _peripheral       = nil;
      _name             = nil;
      _mac              = nil;
      _activity_data    = nil;
      _control          = nil;
      _test_char        = nil;
      _user_info        = nil;
      _date_time        = nil;
      _device_id        = nil;
      _profile_version  = -1;
      _fw_version       = -1;
      _hw_version       = -1;
      _appearance       = -1;
      _feature          = -1;
      _fw2_version      = -1;
      _correction       = 0;
   }
   return self;
}

-(void)setDayData:(MiFreeAcitivityDataDay*)day_data {
   _day_data = day_data;
}

-(MiFreeAcitivityDataDay*)getDayData {
   return _day_data;
}

-(void)setName:(NSString *)name {
   _name = name;
}

-(void)setMac:(NSString *)mac {
   _mac = mac;
}

-(CBPeripheral*) getHandle {
   return _peripheral;
}

-(void)setHandle:(CBPeripheral*) handle {
   _peripheral = handle;
}

-(CBCharacteristic*)getControl {
   return _control;
}

-(void)setControl:(CBCharacteristic*)control {
   _control = control;
}

-(CBCharacteristic*)getActivity {
   return _activity_data;
}

-(void)setActivity:(CBCharacteristic*)activity {
   _activity_data = activity;
}

-(CBCharacteristic*)getTest {
   return _test_char;
}

-(void)setTest:(CBCharacteristic*)characteristic {
   _test_char = characteristic;
}

-(CBCharacteristic*)getVibrate {
   return _vibrate;
}

-(void)setVibrate:(CBCharacteristic*)characteristic {
   _vibrate = characteristic;
}

-(CBCharacteristic*)getUserInfo {
   return _user_info;
}

-(void)setUserInfo:(CBCharacteristic*)characteristic {
   _user_info = characteristic;
}

-(CBCharacteristic*)getDateTime {
   return _date_time;
}

-(void)setDateTime:(CBCharacteristic*)characteristic {
   _date_time = characteristic;
}

-(BOOL)isReady {
   return
         _peripheral != nil &&
         _control != nil &&
         _activity_data != nil &&
         _test_char != nil &&
         _vibrate != nil &&
         _user_info != nil &&
         _date_time != nil;
}

-(bool)isChecksumCorrect:(NSData*)data {
   MiFreeBuilder* builder = [[MiFreeBuilder alloc] init];
   const unsigned char* _data = (const unsigned char*)data.bytes;
   [builder appendByte:_data[0]];
   [builder appendByte:_data[1]];
   [builder appendByte:_data[2]];
   [builder appendByte:_data[3]];
   [builder appendByte:_data[4]];
   [builder appendByte:_data[5]];
   [builder appendByte:_data[6]];
   unsigned char crc8 = [builder getCRC8];
   return (_data[7] & 255) == ((crc8 ^ _data[3]) & 255);
}

-(int)getInt:(NSData*)data From:(int)from Len:(int)len {
   const unsigned char* _data = (const unsigned char*)data.bytes;
   int ret = 0;
   for (int i = 0; i < len; ++i) {
      ret |= (_data[from + i] & 255) << i * 8;
   }
   return ret;
}

-(bool)fillDeviceInfo:(NSData*)data {
   if ((data.length != 20 && data.length != 16) || ![self isChecksumCorrect:data]) {
      return false;
   }
   const unsigned char* _data = (const unsigned char*)data.bytes;
   _device_id = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X",
                 _data[0], _data[1], _data[2], _data[3],
                 _data[4], _data[5], _data[6], _data[7]];
   _profile_version = [self getInt:data From:8 Len:4];
   _fw_version = [self getInt:data From:12 Len:4];
   _hw_version = _data[6] & 255;
   _appearance = _data[5] & 255;
   _feature =    _data[4] & 255;
   _correction = _data[3];
   if (data.length == 20) {
      _fw2_version = [self getInt:data From:16 Len:4];
   } else {
      _fw2_version = -1;
   }
   return true;
}

-(BOOL)isMili1 {
   return _hw_version == 2;
}

-(BOOL)isMili1A {
   return (_feature == 5 && _appearance == 0) || (_feature == 0 && _hw_version == 208);
}

-(BOOL)isAmazFit {
   return _hw_version == 6;
}

-(BOOL)isMili1S {
   return (_feature == 4 && _appearance == 0) || _hw_version == 4;
}

-(BOOL)isMiliPro {
   return _hw_version == 8 || (_feature == 8 && _appearance == 0);
}

-(void)setDate:(GregorianCalendar*)date {
   _date = date;
}

-(GregorianCalendar*)getDate {
   return _date;
}

@end

@implementation MiFree {
   id<MiFreeDelegate>   _delegate;
   CBCentralManager*    _manager;
   MiFreeDevice*        _device;
   MiFreeUserInfo*      _userInfo;
   BOOL                 _autoconnect;
   BOOL                 _bluetooth_enabled;
}

-(id)initWithDelegate:(id<MiFreeDelegate>) delegate AutoConnect:(BOOL)autoconnect {
   self = [super init];
   if (self == nil) {
      return self;
   }
   _autoconnect = autoconnect;
   _delegate = delegate;
   _bluetooth_enabled = NO;
   _device = nil;
   _manager = [[CBCentralManager alloc] initWithDelegate:(id)self queue:nil];
   return self;
}

-(void)setUserInfo:(MiFreeUserInfo*)userInfo {
   _userInfo = userInfo;
}

-(NSString*)parseMacAddress:(NSData*)data {
   unsigned long length = [data length];
   const unsigned char* _data = [data bytes];
   if (length > 6) {
      char raw_mac[255] = {0};
      for(int index = 6; index > 0; --index) {
         if (raw_mac[0]) {
            sprintf(raw_mac, "%s:%02X",raw_mac,  _data[length - index]);
         } else {
            sprintf(raw_mac, "%02X", _data[length - index]);
         }
      }
      return [NSString stringWithUTF8String:raw_mac];
   }
   return nil;
}

-(BOOL)onFoundPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData {
   if (NO == _bluetooth_enabled)
      return FALSE;
   NSLog(@"%@", peripheral);
   BOOL can_execute_callback = _delegate && [_delegate respondsToSelector:@selector(foundDevice:)];
   NSString* name = [peripheral name];
   NSString* mac = nil;
   if (advertisementData) {
      id data = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
      mac = [self parseMacAddress:data];
   }
   MiFreeDevice* device = [[MiFreeDevice alloc] init];
   [device setName:name];
   [device setMac:mac];
   [device setHandle:peripheral];
   if (can_execute_callback && [_delegate foundDevice:device]) {
      [self connectToDevice:device];
      return TRUE;
   }
   return FALSE;
}

-(void)searchDevices {
   if (_bluetooth_enabled) {
      NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
      CBUUID *uuid = [CBUUID UUIDWithString:@"FEE0"];
      NSArray* array = [NSArray arrayWithObject:uuid];
      [_manager scanForPeripheralsWithServices:array options:options];
      NSArray* peripherals = [_manager retrieveConnectedPeripheralsWithServices:array];
      if ([peripherals count] != 0) {
         for (CBPeripheral* peripheral in peripherals) {
            if ([self onFoundPeripheral:peripheral advertisementData:nil]) {
               break;
            }
         }
      }
   }
}

-(void)connectToDevice:(MiFreeDevice *)device {
   [self disconnectFromDevice];
   _device = device;
   [_manager connectPeripheral:[_device getHandle] options:nil];
   [_manager stopScan];
}

-(void)disconnectFromDeviceImpl:(NSError*)error {
   if (_device) {
      [_manager cancelPeripheralConnection:[_device getHandle]];
      [_delegate disconnectedFromDevice:_device Error:error];
      _device = nil;
   }
}

-(void)disconnectFromDevice {
   [self disconnectFromDeviceImpl:nil];
}

-(void)getCurrentActivity {
   if (_device == nil) return;
   [[_device getHandle] readValueForCharacteristic:[_device getActivity]];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
   NSLog(@"%@", central);
   switch (central.state) {
      case CBCentralManagerStatePoweredOn:
      {
         _bluetooth_enabled = YES;
         if (_autoconnect) {
            [self searchDevices];
         }
         [_delegate bluetoothEnabled];
      }
         break;
      case CBCentralManagerStatePoweredOff:
      {
         _bluetooth_enabled = NO;
         [_delegate bluetoothDisabled];
         [self disconnectFromDevice];
      }
      default:
         break;
   }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
   [self onFoundPeripheral:peripheral advertisementData:advertisementData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
   [peripheral setDelegate:(id)self];
   [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
   if (error) {
      NSLog(@"Error writing characteristic value: %@",
            [error localizedDescription]);
   }
   [self disconnectFromDeviceImpl:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
   if (error) {
      NSLog(@"Error writing characteristic value: %@",
            [error localizedDescription]);
   }
   [self disconnectFromDeviceImpl:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
   if (error) {
      NSLog(@"Error writing characteristic value: %@",
            [error localizedDescription]);
   }
   for (CBService* service in peripheral.services){
      NSLog(@"%@", service);
      [peripheral discoverCharacteristics:nil forService: service];
   }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
   if (error) {
      NSLog(@"Error writing characteristic %@ value: %@",
            peripheral, [error localizedDescription]);
   }
   if (service.characteristics == nil){ return; }
   NSArray<CBCharacteristic *>* characteristics = service.characteristics;
   for (CBCharacteristic* characteristic in characteristics) {
      NSString* UUID = characteristic.UUID.UUIDString;
      NSLog(@"Characters %@", characteristic);
      if ([UUID isEqualToString:kMiFreeUUIDPairKey]) {
         unsigned char data_ [1] = {0x02};
         NSData* data = [NSData dataWithBytes:data_ length:1];
         [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
      } else if ([UUID isEqualToString:kMiFreeUUIDStepKey]) {
         [peripheral setNotifyValue:TRUE forCharacteristic:characteristic];
         [peripheral readValueForCharacteristic:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDChargedKey]) {
         [peripheral setNotifyValue:TRUE forCharacteristic:characteristic];
         [peripheral readValueForCharacteristic:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDSensorKey]) {
         [peripheral setNotifyValue:TRUE forCharacteristic:characteristic];
         [peripheral readValueForCharacteristic:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDActivityKey]) {
         [peripheral setNotifyValue:TRUE forCharacteristic:characteristic];
         [_device setActivity:characteristic];
         [peripheral discoverDescriptorsForCharacteristic:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDControlKey]) {
         [_device setControl:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDTestKey]){
         [_device setTest:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDUserInfoKey]) {
         [_device setUserInfo:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDVibarateKey]) {
         [_device setVibrate: characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDDeviceInfoKey]) {
         [[_device getHandle] readValueForCharacteristic:characteristic];
      } else if ([UUID isEqualToString:kMiFreeUUIDDateTimeKey]) {
         [_device setDateTime:characteristic];
         [[_device getHandle] readValueForCharacteristic:characteristic];
      }
   }
}

- (void)parseActiveDataMeta:(NSData*)data {
   uint8_t* _data = (uint8_t*)(data.bytes);
   int32_t type = _data[0];
   GregorianCalendar* date = [[GregorianCalendar alloc] initFromData:data Offset:1];
   int totalDataToRead = (_data[7] & 0xff) | ((_data[8] & 0xff) << 8);
   totalDataToRead *= (type == kMiFreeModeRegularDataLenMinute) ? 3 : 1;
   int dataUntilNextHeader = (_data[9] & 0xff) | ((_data[10] & 0xff) << 8);
   dataUntilNextHeader *= (type == kMiFreeModeRegularDataLenMinute) ? 3 : 1;
   int length = dataUntilNextHeader == 0 ? totalDataToRead:dataUntilNextHeader;
   MiFreeAcitivityDataDay* day_data = [[MiFreeAcitivityDataDay alloc] initFromDate:date Length:length];
   [_device setDayData:day_data];
}

- (BOOL)parseActiveData:(NSData*)data {
   return [[_device getDayData] appendData: data];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
   if (error) {
      NSLog(@"Error writing characteristic value: %@ %@",
            characteristic, [error localizedDescription]);
   }
   if (characteristic.value == nil) {
      return ;
   }
   NSLog(@"Reading value for characteristic %@", characteristic);
   NSString* UUID = [characteristic.UUID UUIDString];
   NSData* data = characteristic.value;
   if ([UUID isEqualToString:kMiFreeUUIDStepKey]) {
      unsigned short step = *(uint16_t*)[data bytes];
      [_delegate updateStep:(int)step];
   } else if ([UUID isEqualToString:kMiFreeUUIDChargedKey]) {
      unsigned char percent = *(uint8_t*)[data bytes];
      [_delegate updateCharge:(int)percent];
   } else if ([UUID isEqualToString:kMiFreeUUIDSensorKey]) {
      data = data;
   } else if ([UUID isEqualToString:kMiFreeUUIDActivityKey]) {
      if ([data length] == 0) {
         return;
      }
      if (data.length == kMiFreeActivityDataMetaLen) {
         [self parseActiveDataMeta:data];
      } else {
         if ([self parseActiveData:data]) {
            MiFreeAcitivityDataDay* result = [_device getDayData];
            [result parseData];
            [_delegate activityUpdate:result];
            [_device setDayData:nil];
         }
      }
   } else if ([UUID isEqualToString:kMiFreeUUIDPairKey]) {
      data = data;
   } else if ([UUID isEqualToString:kMiFreeUUIDDeviceInfoKey]) {
      if ([_device fillDeviceInfo:data]) {
         NSData* data = [_userInfo getData:_device];
         [peripheral writeValue:data forCharacteristic:[_device getUserInfo] type:CBCharacteristicWriteWithResponse];
      }
   } else if ([UUID isEqualToString:kMiFreeUUIDUserInfoKey]) {
      data = data;
   } else if ([UUID isEqualToString:kMiFreeUUIDDateTimeKey]) {
      if (data.length > 0) {
         GregorianCalendar* date = [[GregorianCalendar alloc] initFromData:data Offset:0];
         [_device setDate:date];
      }
   }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
   
   NSLog(@"Notification %@", characteristic);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
   
   if (error) {
      NSLog(@"Error writing characteristic %@ value: %@",
            characteristic, [error localizedDescription]);
   } else {
      NSLog(@"Write value for characteristic %@", characteristic);
   }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
   NSString* UUID = [characteristic.UUID UUIDString];
   if ([UUID isEqualToString:kMiFreeUUIDActivityKey]) {
      NSArray* descriptors = [characteristic descriptors];
      for (CBDescriptor* descriptor in descriptors){
         NSString* descriptor_uuid = [descriptor.UUID UUIDString];
         if ([descriptor_uuid isEqualToString:kMiFreeUUIDAcitityDescKey]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
         }
      }
   }
   
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
   NSLog(@"%@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error {
   NSLog(@"%@", error);
}

-(void)vibrate {
   if (_device == nil) return;
   if ([_device isReady] == false) return;
   MiFreeBuilder* build = [[MiFreeBuilder alloc] init];
   [build appendByte:0x04];
   NSData* data = [build getData];
   [[_device getHandle] writeValue:data forCharacteristic:[_device getVibrate] type:CBCharacteristicWriteWithoutResponse];
}

-(void)stopMotor {
   if (_device == nil) return;
   if ([_device isReady] == false) return;
   MiFreeBuilder* build = [[MiFreeBuilder alloc] init];
   [build appendByte:0x19];
   NSData* data = [build getData];
   [[_device getHandle] writeValue:data forCharacteristic:[_device getControl] type:CBCharacteristicWriteWithResponse];
}

-(void)test {
   if (_device == nil) return;
   if ([_device isReady] == false) return;
//   MiFreeBuilder* build = [[MiFreeBuilder alloc] init];
//   [build appendByte:0x2];
//   NSData* data = [build getData];
//   [[_device getHandle] writeValue:data forCharacteristic:[_device getTest] type:CBCharacteristicWriteWithResponse];
   [[_device getHandle] readValueForCharacteristic:[_device getDateTime]];
}

-(void)readStatistic {
   if (_device == nil) return;
   if ([_device isReady] == false) return;
   MiFreeBuilder* build = [[MiFreeBuilder alloc] init];
   [build appendByte:0x6];
   NSData* data = [build getData];
   [[_device getHandle] writeValue:data
                 forCharacteristic:[_device getControl]
                              type:CBCharacteristicWriteWithResponse];
}

@end

//
//  FirstViewController.m
//  mi-free-client
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController {
   MiFree* _manager;
}

@synthesize chargeLabel = _chargeLabel;
@synthesize stepLabel = _stepLabel;
@synthesize activityLabel = _activityLabel;

- (void)viewDidLoad {
   [super viewDidLoad];
   // Do any additional setup after loading the view, typically from a nib.
   [_stepLabel setText:@"Diconnected"];
   [_chargeLabel setText:@""];
   _manager = [[MiFree alloc] initWithDelegate:self AutoConnect:TRUE];
   MiFreeUserInfo* userInfo = [[MiFreeUserInfo alloc] init];
   userInfo.age = 29;
   userInfo.gender = MiFreeUserInfoMan;
   userInfo.height = 182;
   userInfo.weight = 56;
   userInfo.uid = 10061987;
   userInfo.nick = @"paul";
   [_manager setUserInfo:userInfo];
}

- (void)didReceiveMemoryWarning {
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark "MiFree delegate"

-(BOOL)foundDevice:(MiFreeDevice*) device {
   return TRUE;
}

-(void)updateStep:(int) step {
   [_stepLabel setText:[NSString stringWithFormat:@"%d", step]];
}

-(void)updateCharge:(int) percent {
   [_chargeLabel setText:[NSString stringWithFormat:@"%d", percent]];
}

-(void)bluetoothEnabled {
   [_stepLabel setText:@"Search device"];
   [_chargeLabel setText:@""];
}

-(void)bluetoothDisabled {
   [_stepLabel setText:@"Diconnected"];
   [_chargeLabel setText:@""];
}

-(void)connectedToDevice:(MiFreeDevice*)device {
   
}

-(void)activityUpdate:(MiFreeAcitivityDataDay*)activity {
   
}

-(void)disconnectedFromDevice:(MiFreeDevice*)device Error:(NSError*)error {
   [_stepLabel setText:@"Diconnected from device"];
   if (error == nil) {
      [_chargeLabel setText:@""];
   } else {
      [_chargeLabel setText:[error localizedDescription]];
   }
}

-(IBAction)refrashAD:(id)sender {
   [_manager readStatistic];
}

-(IBAction)vibrate:(id)sender {
   [_manager vibrate];
}

-(IBAction)stopMotor:(id)sender {
   [_manager stopMotor];
}

-(IBAction)test:(id)sender {
   [_manager test];
}

-(IBAction)refrash:(id)sender {
   [_manager searchDevices];
}

@end

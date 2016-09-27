//
//  FirstViewController.h
//  mi-free-client
//
//  Created by Paul Perekhozhikh on 11.09.16.
//  Copyright © 2016 Pavel Perekhozhikh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MiFree/MiFree.h>

@interface FirstViewController : UIViewController<MiFreeDelegate>

@property (nonatomic, retain) IBOutlet UILabel* stepLabel;

@property (nonatomic, retain) IBOutlet UILabel* chargeLabel;

@property (nonatomic, retain) IBOutlet UILabel* activityLabel;

// functions

-(BOOL)foundDevice:(MiFreeDevice*) device;

-(void)updateStep:(int) step;

-(void)updateCharge:(int) percent;

-(void)bluetoothEnabled;

-(void)bluetoothDisabled;

-(void)connectedToDevice:(MiFreeDevice*)device;

-(void)disconnectedFromDevice:(MiFreeDevice*)device Error:(NSError*)error;

-(void)activityUpdate:(MiFreeAcitivityDataDay*)activity;

-(IBAction)refrashAD:(id)sender;

-(IBAction)vibrate:(id)sender;

-(IBAction)stopMotor:(id)sender;

-(IBAction)test:(id)sender;

-(IBAction)refrash:(id)sender;

@end


//
//  ViewController.m
//  inTraffic
//
//  Created by Valentyn Kovalsky on 12/19/16.
//  Copyright © 2016 Valentyn Kovalsky. All rights reserved.
//

#import "ViewController.h"
#import "CoreMotion/CoreMotion.h"
#import <AFNetworking/AFNetworking.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label8;
@property (weak, nonatomic) IBOutlet UILabel *label6;
@property (weak, nonatomic) IBOutlet UILabel *label5;
@property (weak, nonatomic) IBOutlet UILabel *label4;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *label2;
- (IBAction)debugButtonTapped:(id)sender;

@property (nonatomic, strong) CMMotionActivityManager *activityManager;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) CLLocationCoordinate2D lastLocation;
@property (nonatomic, strong) NSDate *lastRequestDate;

@property (nonatomic, strong) AFHTTPRequestOperationManager *operationsManager;

@property (nonatomic, strong) NSDictionary *failedResponse;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![CMMotionActivityManager isActivityAvailable]) {
        return;
    }
    self.activityManager = [[CMMotionActivityManager alloc] init];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager startUpdatingLocation];
    
    self.operationsManager =  [[AFHTTPRequestOperationManager alloc] init];
    self.operationsManager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    if (self.activityManager) {
        [self.activityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMotionActivity * _Nullable activity) {
            self.label.text = [NSString stringWithFormat:@"automotive: %@", activity.automotive ? @"YES" : @"NO"];
            self.label2.text = [NSString stringWithFormat:@"staionary: %@", activity.stationary ? @"YES" : @"NO"];
            
            NSString *stringConfidence = activity.confidence == CMMotionActivityConfidenceLow ? @"Low" : (activity.confidence == CMMotionActivityConfidenceMedium ? @"Medium" : @"High");
            self.label3.text = [NSString stringWithFormat:@"confidence: %@", stringConfidence];

            
            //self.lastLocation = CLLocationCoordinate2DMake(50.448176, 30.522104);
            
            if(!self.lastRequestDate || [self.lastRequestDate timeIntervalSinceDate:[NSDate date]] <= -30) {
                NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&departure_time=now&key=AIzaSyBbXiWCMae7uVQORlSXMprCmbLYro6BY_w", self.lastLocation.latitude, self.lastLocation.longitude, self.lastLocation.latitude, self.lastLocation.longitude];
                
                [self.operationsManager GET:url parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
                    @try {
                        self.label5.text = responseObject[@"routes"][0][@"legs"][0][@"start_address"];
                        
                        NSString *streetType = responseObject[@"geocoded_waypoints"][0][@"types"][0];
                        self.label8.text = [NSString stringWithFormat:@"type: %@", streetType];
                        NSDictionary *durationInTraffic = responseObject[@"routes"][0][@"legs"][0][@"duration_in_traffic"];
                        if(durationInTraffic.allKeys.count == 2) {
                            self.label6.text = [NSString stringWithFormat:@"traffic_duration: %@, value:%@", durationInTraffic[@"text"], durationInTraffic[@"value"]];
                            
                            NSUInteger trafficValue = [durationInTraffic[@"value"] integerValue];
                            NSInteger green = 255 - trafficValue;
                            if(green < 0)
                                green = 0;
                            NSInteger red = trafficValue;
                            
                            self.view.backgroundColor = [UIColor colorWithRed:red/255.0f green:green/255.0f blue:0 alpha:0.6];
                            
                            if(activity.automotive && activity.confidence == CMMotionActivityConfidenceHigh && trafficValue >= 150  && [streetType isEqualToString:@"route"]) {
                                //self.view.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
                                
                                AudioServicesPlaySystemSound(1103);
                            }
                            else {
                                //self.view.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
                            }
                        }
                    } @catch (NSException *exception) {
                        self.lastRequestDate = nil;
                        self.label5.text = @"";
                        self.label6.text = @"";
                        self.label8.text = @"error parsing googleapis response";
                        self.view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
                        self.failedResponse = @{@"url":url, @"response":responseObject};
                    } @finally {
                        
                    }
                    
                } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
                    self.label6.text = error.localizedDescription;
                }];
                
                self.lastRequestDate = [NSDate date];
            }
            /*
             https://roads.googleapis.com/v1/snapToRoads?path=50.44850313,30.51679083
             &interpolate=true
             &key=AIzaSyDj8EGrz9BO2yBXkEDCAVwJgRVbUttQkzQ
             
             https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJVYtTXlfO1EARBpQmsf8iME8&key=AIzaSyDLQ7A5o1mccyZFtc7iZVy3GmWA9_oLAzA
             
             
             https://maps.googleapis.com/maps/api/directions/json?origin=50.44934838,30.51624239&destination=50.44934838,30.51624239&departure_time=now&key=AIzaSyBbXiWCMae7uVQORlSXMprCmbLYro6BY_w
             
             */
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager didFailWithError");
    
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"locationManager didUpdateLocations %@", locations);
    if(locations.count) {
        CLLocation *location = locations[0];
        self.label4.text = [NSString stringWithFormat:@"%0.6f/%0.6f, speed:%0.2f, course:%0.2f", location.coordinate.latitude, location.coordinate.longitude, location.speed, location.course];
        self.lastLocation = location.coordinate;
    }
}

- (IBAction)debugButtonTapped:(id)sender {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please setup email on the device" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if(!self.failedResponse) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nothing to send" message:@"There was no exception during parsing yet, send email when you see a blue screen" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;

    }
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:@"inTraffic exception during parsing"];
    [mc setMessageBody:[self.failedResponse description] isHTML:NO];
    [mc setToRecipients:@[@"valentinkovalski@gmail.com"]];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end

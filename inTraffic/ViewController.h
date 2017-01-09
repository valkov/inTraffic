//
//  ViewController.h
//  inTraffic
//
//  Created by Valentyn Kovalsky on 12/19/16.
//  Copyright © 2016 Valentyn Kovalsky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreLocation/CoreLocation.h"
#import <MessageUI/MessageUI.h> 

@interface ViewController : UIViewController<CLLocationManagerDelegate, MFMailComposeViewControllerDelegate>


@end


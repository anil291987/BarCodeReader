//
//  QRCodeViewController.h
//  iOS7Sampler
//
//  Created by shuichi on 9/25/13.
//  Copyright (c) 2013 Shuichi Tsutsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MatQRCodeGeneraterViewController : UIViewController
@property (nonatomic, strong) NSString *QRstring;
@property (weak, nonatomic) IBOutlet UITextView *txtText;

@end

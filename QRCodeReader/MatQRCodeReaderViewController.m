//
//  ViewController.m
//  QRCodeReader
//
//  Created by Gabriel Theodoropoulos on 27/11/13.
//  Copyright (c) 2013 Gabriel Theodoropoulos. All rights reserved.
//

#import "MatQRCodeReaderViewController.h"
#import "MatQRCodeGeneraterViewController.h"
#import <AddressBook/AddressBook.h>

@interface MatQRCodeReaderViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

-(BOOL)startReading;
-(void)stopReading;
-(void)loadBeepSound;

@end

@implementation MatQRCodeReaderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Initially make the captureSession object nil.
    _captureSession = nil;
    
    // Set the initial value of the flag to NO.
    _isReading = NO;
    
    // Begin loading the sound effect so to have it ready for playback when it's needed.
    [self loadBeepSound];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBAction method implementation

- (IBAction)startStopReading:(id)sender {
    if (!_isReading) {
        // This is the case where the app should read a QR code when the start button is tapped.
        if ([self startReading]) {
            // If the startReading methods returns YES and the capture session is successfully
            // running, then change the start button title and the status message.
            [_bbitemStart setTitle:@"Stop"];
            [_lblStatus setText:@"Scanning for QR Code..."];
        }
    }
    else{
        // In this case the app is currently reading a QR code and it should stop doing so.
        [self stopReading];
        // The bar button item's title should change again.
        [_bbitemStart setTitle:@"Start!"];
    }
    
    // Set to the flag the exact opposite value of the one that currently has.
    _isReading = !_isReading;
}


#pragma mark - Private method implementation

- (BOOL)startReading {
    NSError *error;
    
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

    if (!input) {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    
    // Start video capture.
    [_captureSession startRunning];
    
    return YES;
}


- (void)addvCardAddressBook:(CFDataRef)vCardData defaultSource:(ABRecordRef)defaultSource book:(ABAddressBookRef)book
{
    // The user has previously given access, add the contact
    CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
    for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++)
    {
        ABRecordRef person = CFArrayGetValueAtIndex(vCardPeople, index);
        ABAddressBookAddRecord(book, person, NULL);
        CFRelease(person);
    }
    //                CFRelease(vCardPeople);
    //                CFRelease(defaultSource);
    ABAddressBookSave(book, NULL);
    CFRelease(book);
}

- (void)showQRGenrator
{
    NSLog(@"test %@",_lblStatus.text);
    NSURL *openURL = [NSURL URLWithString:_lblStatus.text];
    if (openURL != nil)
    {
        if ([[UIApplication sharedApplication] canOpenURL:openURL] )
        {
            [[UIApplication sharedApplication] openURL:openURL];
        } else {
            UIAlertView *notPermitted=[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Your device doesn't support this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [notPermitted show];
        }
    }else{
        
        // This gets the vCard data from a file in the app bundle called vCard.vcf
             // This version simply uses a string. I'm assuming you'll get that from somewhere else.
        if ([_lblStatus.text rangeOfString:@"BEGIN:VCARD"].length > 0)
        {
            NSString *vCardString = _lblStatus.text;
            // This line converts the string to a CFData object using a simple cast, which doesn't work under ARC
            CFDataRef vCardData = (__bridge CFDataRef)[vCardString dataUsingEncoding:NSUTF8StringEncoding];
            // If you're using ARC, use this line instead:
            //CFDataRef vCardData = (__bridge CFDataRef)[vCardString dataUsingEncoding:NSUTF8StringEncoding];
            
            ABAddressBookRef book = ABAddressBookCreateWithOptions(nil, nil);
            ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
            
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
            {
                ABAddressBookRequestAccessWithCompletion(book, ^(bool granted, CFErrorRef error) {
                    // First time access has been granted, add the contact
                    [self addvCardAddressBook:vCardData defaultSource:defaultSource book:book];
                });
            }
            else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
            {
                [self addvCardAddressBook:vCardData defaultSource:defaultSource book:book];
            }
            else {
                // The user has previously denied access
                // Send an alert telling user to change privacy setting in settings app
            }
            UIAlertView *notPermitted=[[UIAlertView alloc] initWithTitle:@"Alert" message:@"vCard added sucessfully!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [notPermitted show];
        }else{
            MatQRCodeGeneraterViewController *objQRGen = [[MatQRCodeGeneraterViewController alloc]initWithNibName:@"MatQRCodeGeneraterViewController" bundle:nil];
            objQRGen.QRstring = _lblStatus.text;
            [self presentViewController:objQRGen animated:YES completion:nil];
        }
        NSLog(@"this is not URL");
    }
   

}

-(void)stopReading
{
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
    [self performSelector:@selector(showQRGenrator) withObject:nil afterDelay:1.0];
}


-(void)loadBeepSound{
    // Get the path to the beep.mp3 file and convert it to a NSURL object.
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL *beepURL = [NSURL URLWithString:beepFilePath];

    NSError *error;
    
    // Initialize the audio player object using the NSURL object previously set.
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        // If the audio player cannot be initialized then log a message.
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    }
    else{
        // If the audio player was successfully initialized then load it in memory.
        [_audioPlayer prepareToPlay];
    }
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            [_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];

            _isReading = NO;
            
            // If the audio player is not nil, then play the sound effect.
            if (_audioPlayer) {
                [_audioPlayer play];
            }
        }
    }
    
    
}

@end

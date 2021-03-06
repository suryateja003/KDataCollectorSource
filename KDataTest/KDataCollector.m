//
//  KDataCollector.m
//  KountDataCollector
//
//  Created by Keith Feldman on 1/12/16.
//  Copyright © 2016 Kount Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>
#import "KDataCollector_Internal.h"
#import "KFingerprintCollector.h"
#import "KSystemCollector.h"
#import "KLocationCollector.h"
#import "KDictionary.h"

NSString *const KDataCollectorErrorDomain = @"KountDataCollector";

// Collector POST Keys
NSString *const KDataCollectorPostKeyLocationLatitude = @"lat";
NSString *const KDataCollectorPostKeyLocationLongitude = @"lon";
NSString *const KDataCollectorPostKeyLocationDate = @"ltm";
NSString *const KDataCollectorPostKeySDKVersion = @"sv";
NSString *const KDataCollectorPostKeySDKType = @"st";
NSString *const KDataCollectorPostKeyMobileModel = @"mdl";
NSString *const KDataCollectorPostKeySoftErrors = @"err"; 
NSString *const KDataCollectorPostKeyMerchantID = @"m";
NSString *const KDataCollectorPostKeySessionID = @"s";
NSString *const KDataCollectorPostKeyOSVersion = @"os";
NSString *const KDataCollectorPostKeyDeviceCookie = @"dc";
NSString *const KDataCollectorPostKeyOldDeviceCookie = @"odc";
NSString *const KDataCollectorPostKeyCookieUID = @"UID";
NSString *const KDataCollectorPostKeyVendorUID = @"IOS_IDFV";
NSString *const KDataCollectorPostKeyTotalDisk = @"ddk";
NSString *const KDataCollectorPostKeyTotalMemory = @"dmm";
NSString *const KDataCollectorPostKeyElapsed = @"elapsed";
NSString *const KDataCollectorPostKeyLocalDateTimeEpoch =@"e";
NSString *const KDataCollectorPostKeyTimezoneAugust = @"ta";
NSString *const KDataCollectorPostKeyTimezoneFebruary = @"tf";
NSString *const KDataCollectorPostKeyTimezoneCurrent = @"t0";
NSString *const KDataCollectorPostKeyLanguageAndCountry = @"ln";
NSString *const KDataCollectorPostKeyScreenDimensions = @"sa";

//KIOS-9 :Enhance Timing Metrics
// Timing Metrics POST Keys
NSString *const KDataCollectorPostKeyLocationLatitudeElapsedTime = @"lat_et";
NSString *const KDataCollectorPostKeyLocationLongitudeElapsedTime = @"lon_et";
NSString *const KDataCollectorPostKeyLocationDateElapsedTime = @"ltm_et";
NSString *const KDataCollectorPostKeySDKVersionElapsedTime = @"sv_et";
NSString *const KDataCollectorPostKeySDKTypeElapsedTime = @"st_et";
NSString *const KDataCollectorPostKeyMobileModelElapsedTime = @"mdl_et";
NSString *const KDataCollectorPostKeyMerchantIDElapsedTime = @"m_et";
NSString *const KDataCollectorPostKeySessionIDElapsedTime = @"s_et";
NSString *const KDataCollectorPostKeyOSVersionElapsedTime = @"os_et";
NSString *const KDataCollectorPostKeyDeviceCookieElapsedTime = @"dc_et";
NSString *const KDataCollectorPostKeyOldDeviceCookieElapsedTime = @"odc_et";
NSString *const KDataCollectorPostKeyTotalDiskElapsedTime = @"ddk_et";
NSString *const KDataCollectorPostKeyTotalMemoryElapsedTime = @"dmm_et";
NSString *const KDataCollectorPostKeyLocalDateTimeEpochElapsedTime =@"e_et";
NSString *const KDataCollectorPostKeyTimezoneAugustElapsedTime = @"ta_et";
NSString *const KDataCollectorPostKeyTimezoneFebruaryElapsedTime = @"tf_et";
NSString *const KDataCollectorPostKeyTimezoneCurrentElapsedTime = @"t0_et";
NSString *const KDataCollectorPostKeyLanguageAndCountryElapsedTime = @"ln_et";
NSString *const KDataCollectorPostKeyScreenDimensionsElapsedTime = @"sa_et";
NSString *const KDataCollectorPostKeySystemCollectorElapsedTime = @"system_et";
NSString *const KDataCollectorPostKeyFingerprintCollectorElapsedTime = @"fingerprint_et";
NSString *const KDataCollectorPostKeyLocationCollectorElapsedTime = @"location_et";

//KIOS-20: ReverseGeoData from iOS Device SDK
NSString *const KDataCollectorPostKeyCity = @"city";
NSString *const KDataCollectorPostKeyState = @"region";
NSString *const KDataCollectorPostKeyCountry = @"country";
NSString *const KDataCollectorPostKeyISO = @"iso_country_code";
NSString *const KDataCollectorPostKeyPostalCode = @"postal_code";
NSString *const KDataCollectorPostKeyOrganization = @"org_name";
NSString *const KDataCollectorPostKeyStreet = @"street";
NSString *const KDataCollectorPostKeyReverseGeocodeElapsedTime = @"geocoding_et";

// Soft Error Keys
NSString *const KDataCollectorPostSoftErrorKeyPassivelySkipped = @"skipped_passively";
NSString *const KDataCollectorPostSoftErrorKeySkipped = @"skipped";
NSString *const KDataCollectorPostSoftErrorKeyUnexpected = @"unexpected";
NSString *const KDataCollectorPostSoftErrorKeyServiceUnavailable = @"not_available";
NSString *const KDataCollectorPostSoftErrorKeyPermissionDenied = @"permission_denied";
NSString *const KDataCollectorPostSoftErrorKeyTimeout = @"timeout";

//KIOS-20: ReverseGeoData from iOS Device SDK
NSString *const KDataCollectorPostSoftErrorKeyAddressFieldsUnavailable = @"some_address_fields_unavailable";
NSString *const KDataCollectorPostSoftErrorKeyAddressNotCollected = @"Address_not_collected";

// Collector Names
NSString *const KDataCollectorInternalNameLocation = @"collector_geo_loc";
NSString *const KDataCollectorInternalNameFingerprint = @"collector_device_cookie";
NSString *const KDataCollectorInternalNameSystem = @"LOCAL";

// Other Constants
NSString *const KDataCollectorPostMobileEndpoint = @"m.html";
NSString *const KDataCollectorPostEmptyBody = @"<head></head><body></body>";
NSString *const KDataCollectorVersion = @"4.1.5";

// Regular Expressions for Validation
NSString *const KDataCollectorRegExURL = @"^https://[\\w-]+(\\.[\\w-]+)+(/[^?]*)?$";
NSString *const KDataCollectorRegExMerchantID = @"^\\d{1,6}$";
NSString *const KDataCollectorRegExSessionID = @"^\[\\w-]{1,32}$";

// Environment
int const KEnvironmentQA = 999999;

@interface KDataCollector ()
@property CFTimeInterval endTimeForValidationFields;
@property (strong) NSOperationQueue *queue;
@end

#pragma mark 

@implementation KDataCollector

@synthesize merchantID = _merchantID;
@synthesize debug = _debug;
@synthesize locationCollectorConfig = _locationCollectorConfig;
@synthesize server = _server;
@synthesize timeoutInMS = _timeoutInMS;
@synthesize environment = _environment;

#pragma mark Singleton

// Get the shared instance of the Data Collector
+ (KDataCollector *)sharedCollector
{
    static KDataCollector *_sharedCollector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCollector = [[self alloc] init];
        _sharedCollector.locationCollectorConfig = KLocationCollectorConfigRequestPermission;
        _sharedCollector.merchantID = -1;
        _sharedCollector.timeoutInMS = 15000; // Default timeout of 15 seconds
        _sharedCollector.queue = [[NSOperationQueue alloc] init];
        // Only allow 1 operation to be performed at a time, making this a sequential queue
        _sharedCollector.queue.maxConcurrentOperationCount = 1;
        
    });
    return _sharedCollector;
}

#pragma mark Public Methods

- (void)setMerchantID:(NSInteger)merchantID 
{
    if (self.debug) {
        NSLog(@"Setting Merchant ID to %ld.", (long)merchantID);
    }
    _merchantID = merchantID;
}

- (NSInteger)merchantID
{
    return _merchantID;
}

- (void)setDebug:(BOOL)debug
{
    _debug = debug;
    if (self.debug) {
        NSLog(@"Enabling debug to console.");
    }
}

- (BOOL)debug
{
    return _debug;
}

- (void)setLocationCollectorConfig:(KLocationCollectorConfig)config;
{
    if (self.debug) {
        switch (config) {
            case KLocationCollectorConfigRequestPermission:
                NSLog(@"Location collection enabled (requesting permission if needed).");
                break;
            case KLocationCollectorConfigPassive:
                NSLog(@"Location collection enabled (without requesting permission).");
                break;
            case KLocationCollectorConfigSkip:
                NSLog(@"Skipping location collection.");
                break;
        }
    }
    _locationCollectorConfig = config;
}

- (KLocationCollectorConfig)locationCollectorConfig
{
    return _locationCollectorConfig;
}

- (void)setServer:(NSString *)server
{
    if (self.debug) {
        NSLog(@"Setting server to %@.", server);
    }
    _server = server;
}

- (NSString *)server
{
    return _server;
}


- (void)collectForSession:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock
{
    [self collectForSession:sessionID completion:completionBlock debugDelegate:nil];
}

- (void)setTimeoutInMS:(NSInteger)timeoutInMS
{
    if (self.debug) {
        NSLog(@"Setting Timeout to %ld.", (long)timeoutInMS);
    }
    _timeoutInMS = timeoutInMS;
}

- (NSInteger)timeoutInMS
{
    return _timeoutInMS;
}

- (void)setEnvironment:(KEnvironment)environment
{
        switch (environment) {
            case KEnvironmentTest:
                [self debugMessage:@"Setting Environment to Test" debugDelegate:nil];
                self.server = @"https://tst.kaptcha.com/";
                break;
            case KEnvironmentProduction:
                [self debugMessage:@"Setting Environment to Production" debugDelegate:nil];
                self.server = @"https://ssl.kaptcha.com/";
                break;
            case KEnvironmentQA:
                [self debugMessage:@"Setting Environment to QA" debugDelegate:nil];
                self.server = @"https://tst.kaptcha.com/";
                break;
            default:
                _environment = KEnvironmentUnknown;
                [self debugMessage:@"Invalid Environment" debugDelegate:nil];
                _server = @"";
                return;
                
        }
        _environment = environment;
}

- (KEnvironment)environment 
{
    return _environment;
}

#pragma mark Helpers

- (void)failWithErrorMessage:(NSString *)message code:(NSInteger)errorCode debugDelegate:(id)debugDelegate sessionID:(NSString *)sessionID completionBlock:(KDataCollectorCompletionBlock)completionBlock
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
    NSError *error = [NSError errorWithDomain:KDataCollectorErrorDomain code:errorCode userInfo:userInfo];
    [self callCompletionBlock:completionBlock sessionID:sessionID success:NO error:error debugDelegate:debugDelegate];
}

- (void)debugMessage:(NSString *)string debugDelegate:(id<KDataCollectorDebugDelegate>)debugDelegate 
{
    if (self.debug) {
        NSLog(@"%@", string);
    }
    if (debugDelegate && [debugDelegate respondsToSelector:@selector(collectorDebugMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [debugDelegate collectorDebugMessage:string];
        });
    }
}

- (NSString *)buildDateString
{
    NSString *systemDateString = [NSString stringWithFormat:@"%@ %@", [NSString stringWithUTF8String:__DATE__] , [NSString stringWithUTF8String:__TIME__] ];
    
    // Convert to date
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"LLL d yyyy HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:systemDateString];
    
    // Return a more readable date string
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    [dateFormat setTimeStyle:NSDateFormatterShortStyle];
    return [dateFormat stringFromDate:date];
}

#pragma mark Collector Creation Helpers (for unit testing)


- (KLocationCollector *)createLocationCollector
{
    return [[KLocationCollector alloc] initWithConfig:self.locationCollectorConfig withTimeoutInMS:(int)self.timeoutInMS];
}

#pragma mark Collecting & Threading

- (void)collectForSession:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id<KDataCollectorDebugDelegate>)debugDelegate
{
    [self debugMessage:[NSString stringWithFormat:@"(%@) Adding block.", sessionID] debugDelegate:debugDelegate];

    // Add this session request to the serial operation queue via a block
    [self.queue addOperationWithBlock:^{
        [self debugMessage:[NSString stringWithFormat:@"(%@) Starting collection", sessionID] debugDelegate:debugDelegate];
        // Keep track of the time the collection dates for metrics
        //KIOS-9 :Enhance Timing Metrics
        CFTimeInterval startTime = CACurrentMediaTime();
        // Validate the various required fields before diving into collection
        if (![self validateFields:sessionID completion:completionBlock debugDelegate:debugDelegate]) {
            return;
        }
       
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __block NSMutableDictionary *dataForSubmission = [NSMutableDictionary dictionary];
        __block NSMutableDictionary *softErrorsForSubmission = [NSMutableDictionary dictionary];
        __block NSMutableArray *errors = [NSMutableArray array];
        // Lock for manipulating variables inside blocks from other threads
        __block NSLock *dataLock = [[NSLock alloc] init]; 
        
        // Set up the collectors
        NSMutableArray *collectors = [NSMutableArray array];
        [collectors addObject:[[KSystemCollector alloc] init]];

        if (self.locationCollectorConfig == KLocationCollectorConfigSkip) {
            [softErrorsForSubmission setObject:KDataCollectorPostSoftErrorKeySkipped forKey:KDataCollectorInternalNameLocation];
        } 
        else {
            [collectors addObject:[self createLocationCollector]];
        }
        [collectors addObject:[[KFingerprintCollector alloc] init]];

        // We need to keep track of the collects left, because if the dispatch_group_wait times out, we need to peel the rest out of the group
        // otherwise a semaphore mismatch exception occurs
        __block NSInteger collectorsLeft = collectors.count;
        
        // Call each of the collectors
        for (KCollectorTaskBase *collector in collectors) {
            dispatch_group_enter(group);
            dispatch_async(queue, ^{
                [collector collectForSession:sessionID completion:^(BOOL success, NSError *error, NSDictionary *collectedData, NSDictionary *softErrors) {
                    [dataLock lock];
                    // Short circuit in case the group timed-out
                    if (collectorsLeft > 0) {
                        if (collectedData) {
                            [dataForSubmission addEntriesFromDictionary:collectedData];
                        }
                        if (softErrors) {
                            [softErrorsForSubmission addEntriesFromDictionary:softErrors];
                        }
                        if (error) {
                            [errors addObject:error];
                        }
                        collectorsLeft--;
                        dispatch_group_leave(group);
                    }
                    [dataLock unlock];
                } debugDelegate:debugDelegate];
            });
        }
        
        // Wait for the collectors to finish up to the timeout threshold
        if (0 != dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (self.timeoutInMS + 100) * NSEC_PER_MSEC))) {
            // If some collectors have failed to return after the timeout, we need to make sure that the group semaphores are balanced otherwise a crash will occur
            [dataLock lock];
            for (int i = 0; i < collectorsLeft; i++) {
#ifdef DEBUG
                [self debugMessage:[NSString stringWithFormat:@"(%@) !! Decrementing collectorsLeft count because of dispatch_group_wait timeout.", sessionID] debugDelegate:debugDelegate];
#endif
                collectorsLeft--;
                dispatch_group_leave(group);
            }
            [dataLock unlock];
            // Check for timed out collectors
            for (KCollectorTaskBase *collector in collectors) {
                [dataLock lock];
                if (!collector.done) {
                    collector.debugDelegate = nil;
                    [softErrorsForSubmission setObject:@"timeout" forKey:collector.internalName];
                    [self debugMessage:[NSString stringWithFormat:@"(%@) Collector timed out: %@.", sessionID, collector.name] debugDelegate:debugDelegate];
                }
                [dataLock unlock];
            }
        }
        
        [dataLock lock];
        if (errors.count) {
            [self callCompletionBlock:completionBlock sessionID:sessionID success:NO error:[errors objectAtIndex:0] debugDelegate:debugDelegate];
        }
        else if (dataForSubmission.count) {
                //KIOS-9 :Enhance Timing Metrics
                CFTimeInterval executionTime = CACurrentMediaTime() - startTime;
                long milliseconds = (long)(executionTime * 1000.0);
                [dataForSubmission setObject:[NSString stringWithFormat:@"%ld", milliseconds] forKey:@"elapsed"];
                [self debugMessage:[NSString stringWithFormat:@"(%@) Collection time: %ld ms.", sessionID, milliseconds] debugDelegate:debugDelegate];
                [self postDataToServer:self.server session:sessionID data:dataForSubmission softErrors:softErrorsForSubmission debugDelegate:debugDelegate completion:completionBlock];
            }
        
        else {
            [self failWithErrorMessage:@"Required collectors did not finish." code:KDataCollectorErrorCodeTimeout debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
        }
        [dataLock unlock];
    }];

}

// Helper method for calling the completion block so that information can be sent to the console as well as executing the completion block on the main thread
- (void)callCompletionBlock:(KDataCollectorCompletionBlock)completionBlock sessionID:(NSString *)sessionID success:(BOOL)success error:(NSError *)error debugDelegate:debugDelegate
{
    if (success) {
        [self debugMessage:[NSString stringWithFormat:@"(%@) Collector completed successfully.", sessionID] debugDelegate:debugDelegate];
    }
    else {
        if (error) {
            [self debugMessage:[NSString stringWithFormat:@"(%@) Collector failed w/ error (%ld): %@.", sessionID, (long)error.code, error.localizedDescription] debugDelegate:debugDelegate];
        }
        else {
            [self debugMessage:[NSString stringWithFormat:@"(%@) Collector failed.", sessionID] debugDelegate:debugDelegate];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completionBlock) {
            completionBlock(sessionID, success, error);
        }
#ifdef DEBUG
        else {
            [self debugMessage:[NSString stringWithFormat:@"(%@) !! Completion block handler no longer exists.", sessionID] debugDelegate:debugDelegate];
        }
#endif
    });
}

// Extracted call for unit testing / mocking purposes
- (BOOL)synchronousSend:(NSError **)error response:(NSURLResponse **)response mobileRequest:(NSMutableURLRequest *)mobileRequest
{
    [NSURLConnection sendSynchronousRequest:mobileRequest returningResponse:&(*response) error:&(*error)];
    if (*error) {
        return NO;
    }
    return YES;
}

- (void)postDataToServer:(NSString *)serverName session:(NSString *)sessionID data:(NSMutableDictionary *)data softErrors:(NSMutableDictionary *)softErrors debugDelegate:(id)debugDelegate completion:(KDataCollectorCompletionBlock)completionBlock
{
    // Add SDK information
    [data setObject:KDataCollectorVersion forKey:KDataCollectorPostKeySDKVersion];
    [data setObject:@"I" forKey:KDataCollectorPostKeySDKType];
    
    _deviceDataForAnalytics = data;
        
    NSString *postBodyString = [self formatDataForServer:data softErrors:softErrors sessionID:sessionID];
    [self debugMessage:[NSString stringWithFormat:@"(%@) Posting data:\n%@", sessionID, postBodyString] debugDelegate:debugDelegate];

    if (![serverName hasSuffix:@"/"]) {
        serverName = [serverName stringByAppendingString:@"/"];
    }

    NSURL *mobileUrl = [NSURL URLWithString:[serverName stringByAppendingString:KDataCollectorPostMobileEndpoint]];
    NSMutableURLRequest *mobileRequest = [NSMutableURLRequest requestWithURL:mobileUrl];
    [mobileRequest setHTTPMethod:@"POST"];
    [mobileRequest setHTTPBody:[postBodyString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    // DMD-437: Begin
    // Declared with __block storage type, variable's storage is to be managed differently
    __block NSURLResponse *response = nil;
    __block NSError *error = nil;
    
    if (![self synchronousSend:&error response:&response mobileRequest:mobileRequest]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Creating a Timer with time interval 5 seconds and it repeats the execution of timer's block 12 times
            [NSTimer scheduledTimerWithTimeInterval:5.0 repeats:YES block:^(NSTimer * _Nonnull timerBlock) {
                static NSInteger count = 1;
                error = nil;
                response = nil;
                count++;
                if ([self synchronousSend:&error response:&response mobileRequest:mobileRequest]) {
                    [self debugMessage:[NSString stringWithFormat:@"(%@) Sent data to %@%@.", sessionID, serverName, KDataCollectorPostMobileEndpoint] debugDelegate:debugDelegate];
                    [self callCompletionBlock:completionBlock sessionID:sessionID success:YES error:nil debugDelegate:debugDelegate];
                    [timerBlock invalidate];
                }
                else if (count > 12) {
                    [self debugMessage:[NSString stringWithFormat:@"(%@) Failed to send data to %@%@.", sessionID, serverName, KDataCollectorPostMobileEndpoint] debugDelegate:debugDelegate];
                    [self failWithErrorMessage:error.localizedDescription code:KDataCollectorErrorCodeNSError debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
                    [timerBlock invalidate];
                }
            }];
        });
            
    }
    // DMD-437: End
    else {
        
        [self debugMessage:[NSString stringWithFormat:@"(%@) Sent data to %@%@.", sessionID, serverName, KDataCollectorPostMobileEndpoint] debugDelegate:debugDelegate];
        [self callCompletionBlock:completionBlock sessionID:sessionID success:YES error:nil debugDelegate:debugDelegate];
    }
}

// Format the data collected and the soft errors for posting to the server
- (NSString *)formatDataForServer:(NSDictionary *)dataForSubmission softErrors:(NSDictionary *)softErrors sessionID:(NSString *)sessionID 
{
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@=%ld&%@=%@", KDataCollectorPostKeyMerchantID, (long)self.merchantID, KDataCollectorPostKeySessionID, sessionID];
    // Sort the keys so that the collected data is consistent in appearance for debugging/eyeball purposes
    NSArray *dataKeys = [dataForSubmission.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in dataKeys) {
        NSString *keyString = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *valueString = [[dataForSubmission objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [urlString appendFormat:@"&%@=%@", keyString, valueString];
    }
    // Convert the soft error dictionary to JSON format
    if (softErrors.count) {
        NSString *jsonString = [KDictionary jsonStringWithDict:softErrors];
        if (jsonString) {
            [urlString appendFormat:@"&%@=%@", KDataCollectorPostKeySoftErrors, [jsonString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
#ifdef DEBUG
        else {
            NSLog(@"%@", [NSString stringWithFormat:@"(%@) Problem encountered when creating JSON data for soft errors", sessionID]);
        }
#endif
    }

    return urlString;
}

#pragma mark Validation

- (BOOL)validateFields:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id)debugDelegate
{
    // Validate required fields
    if (![self validMerchantID:sessionID completion:completionBlock debugDelegate:debugDelegate]) {
        return NO;
    }
    if (![self validURL:sessionID completion:completionBlock debugDelegate:debugDelegate]) {
        return NO;
    }
    if (![self validSessionID:sessionID completion:completionBlock debugDelegate:debugDelegate]) {
        return NO;
    }
    // Collection won't get started when phone is not connected to network. We can comment the below code to test the same.
    if (![self validNetwork:sessionID completion:completionBlock debugDelegate:debugDelegate]) {
        return NO;
    }
    return YES;
}

- (BOOL)validMerchantID:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id)debugDelegate
{
    if (![self matchRegEx:KDataCollectorRegExMerchantID withString:[NSString stringWithFormat:@"%ld", (long)self.merchantID]]) {
        [self failWithErrorMessage:@"Merchant ID formatted incorrectly." code:KDataCollectorErrorCodeBadParameter debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
        return NO;
    }
    return YES;
}

- (BOOL)validURL:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id)debugDelegate
{
    if (![self matchRegEx:KDataCollectorRegExURL withString:self.server]) {
        [self failWithErrorMessage:@"URL formatted incorrectly." code:KDataCollectorErrorCodeBadParameter debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
        return NO;
    }
    return YES;
}

- (BOOL)validSessionID:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id)debugDelegate
{
    if (![self matchRegEx:KDataCollectorRegExSessionID withString:sessionID]) 
    {
        [self failWithErrorMessage:@"Session ID formatted incorrectly." code:KDataCollectorErrorCodeBadParameter debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
        return NO;
    }
    return YES;
}

// Extracted call for unit testing / mocking purposes
- (BOOL)getNetworkFlags:(SCNetworkReachabilityFlags *)flags
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    
    BOOL retrievedFlags = SCNetworkReachabilityGetFlags(reachability, &(*flags));
    CFRelease(reachability);
    return retrievedFlags;
}

- (BOOL)validNetwork:(NSString *)sessionID completion:(KDataCollectorCompletionBlock)completionBlock debugDelegate:(id)debugDelegate 
{
    SCNetworkReachabilityFlags flags;
    BOOL successfullyRetrievedFlags;
    successfullyRetrievedFlags = [self getNetworkFlags:&flags];
    
    if (successfullyRetrievedFlags) {
        BOOL networkAvailable = NO;
        BOOL reachable = flags & kSCNetworkFlagsReachable;
        BOOL connectionRequired = flags & kSCNetworkFlagsConnectionRequired;
        if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
            networkAvailable = YES;
        }
        else if (reachable && !connectionRequired) {
            networkAvailable = YES;
        }
        if (networkAvailable) {
            return YES;
        }
    }
    
    [self failWithErrorMessage:@"Network not available." code:KDataCollectorErrorCodeNoNetwork debugDelegate:debugDelegate sessionID:sessionID completionBlock:completionBlock];
    return NO;
} 

- (BOOL)matchRegEx:(NSString*)regexString withString:(NSString*)testString 
{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexString] evaluateWithObject:testString];
}

@end

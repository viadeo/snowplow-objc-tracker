//
//  SPUtils.m
//  Snowplow
//
//  Copyright (c) 2013-2015 Snowplow Analytics Ltd. All rights reserved.
//
//  This program is licensed to you under the Apache License Version 2.0,
//  and you may not use this file except in compliance with the Apache License
//  Version 2.0. You may obtain a copy of the Apache License Version 2.0 at
//  http://www.apache.org/licenses/LICENSE-2.0.
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the Apache License Version 2.0 is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
//  express or implied. See the Apache License Version 2.0 for the specific
//  language governing permissions and limitations there under.
//
//  Authors: Jonathan Almeida, Joshua Beemster
//  Copyright: Copyright (c) 2013-2015 Snowplow Analytics Ltd
//  License: Apache License Version 2.0
//

#import "SPUtils.h"

#if TARGET_OS_IPHONE

#import "OpenIDFA.h"
#import <UIKit/UIScreen.h>
#import <UIKit/UIDevice.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Reachability.h"

#else

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#include <sys/sysctl.h>

#endif

@implementation SPUtils

+ (NSString *) getTimezone {
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    return [timeZone name];
}

+ (NSString *) getLanguage {
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}

+ (NSString *) getPlatform {
#if TARGET_OS_IPHONE
    return @"mob";
#else
    return @"pc";
#endif
}

+ (NSString *) getEventId {
    // Generates type 4 UUID
    return [[NSUUID UUID] UUIDString].lowercaseString;
}

+ (NSString *) getOpenIdfa {
    NSString * idfa = nil;
#if TARGET_OS_IPHONE
    idfa = [OpenIDFA sameDayOpenIDFA];
#endif
    return idfa;
}

+ (NSString *) getAppleIdfa {
    NSString* idfa = nil;
#if TARGET_OS_IPHONE
#ifndef SNOWPLOW_NO_IFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        idfa = [uuid UUIDString];
    }
#endif
#endif
    return idfa;
}

+ (NSString *) getAppleIdfv {
    NSString * idfv = nil;
#if TARGET_OS_IPHONE
    idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    return idfv;
}

+ (NSString *) getCarrierName {
    NSString * carrierName = nil;
#if TARGET_OS_IPHONE
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    carrierName = [carrier carrierName];
#endif
    return carrierName;
}

+ (NSString *) getNetworkType {
    NSString * type = nil;
#if TARGET_OS_IPHONE
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == ReachableViaWiFi) {
        type = @"wifi";
    }
    else if (status == ReachableViaWWAN) {
        type = @"mobile";
    }
#endif
    return type;
}

+ (NSString *) getNetworkTechnology {
    NSString * netTech = nil;
#if TARGET_OS_IPHONE
    CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
    netTech = [netInfo currentRadioAccessTechnology];
#endif
    return netTech;
}

+ (int) getTransactionId {
    return arc4random() % (999999 - 100000+1) + 100000;
}

+ (double) getTimestamp {
    NSDate *time = [[NSDate alloc] init];
    return [time timeIntervalSince1970] * 1000;
}

+ (NSString *) getResolution {
#if TARGET_OS_IPHONE
    CGRect mainScreen = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
#else
    CGRect mainScreen = [[NSScreen mainScreen] frame];
    CGFloat screenScale = [[NSScreen mainScreen] backingScaleFactor];
#endif
    CGFloat screenWidth = mainScreen.size.width * screenScale;
    CGFloat screenHeight = mainScreen.size.height * screenScale;
    NSString *res = [NSString stringWithFormat:@"%.0fx%.0f", screenWidth, screenHeight];
    return res;
}

+ (NSString *) getViewPort {
    // This probably doesn't change as well
    return [self getResolution];
}

+ (NSString *) getDeviceVendor {
    return @"Apple Inc.";
}

+ (NSString *) getDeviceModel {
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] model];
#else
    size_t size;
    char *model = nil;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    NSString *hwString = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    return hwString;
#endif
}

+ (NSString *) getOSVersion {
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] systemVersion];
#else
    SInt32 osxMajorVersion;
    SInt32 osxMinorVersion;
    SInt32 osxPatchFixVersion;
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if ([info respondsToSelector:@selector(operatingSystemVersion)]) {
        NSOperatingSystemVersion systemVersion = [info operatingSystemVersion];
        osxMajorVersion = (int)systemVersion.majorVersion;
        osxMinorVersion = (int)systemVersion.minorVersion;
        osxPatchFixVersion = (int)systemVersion.patchVersion;
    }
    else {
        // TODO eliminate this block once minimum version is OS X 10+
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        Gestalt(gestaltSystemVersionMajor, &osxMajorVersion);
        Gestalt(gestaltSystemVersionMinor, &osxMinorVersion);
        Gestalt(gestaltSystemVersionBugFix, &osxPatchFixVersion);
#pragma clang diagnostic pop
    }
    NSString *versionString = [NSString stringWithFormat:@"%d.%d.%d", osxMajorVersion,
                               osxMinorVersion, osxPatchFixVersion];
    return versionString;
#endif
}

+ (NSString *) getOSType {
#if TARGET_OS_IPHONE
    return @"ios";
#else
    return @"osx";
#endif
}

+ (NSString *) getAppId {
    return [[NSBundle mainBundle] bundleIdentifier];
}


+ (NSString *)urlEncodeString:(NSString *)s {
    if (!s) {
        return @"";   
    }
    return (NSString *)CFBridgingRelease(
      CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) s, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
      CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

+ (NSString *)urlEncodeDictionary:(NSDictionary *)d {
    NSMutableArray *keyValuePairs = [NSMutableArray arrayWithCapacity:d.count];
    [d enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [keyValuePairs addObject:[NSString stringWithFormat:@"%@=%@", [self urlEncodeString:key], [self urlEncodeString:[value description]]]];
    }];
    return [keyValuePairs componentsJoinedByString:@"&"];
}

+ (BOOL) isOnline {
    BOOL online = YES;
#if TARGET_OS_IPHONE
    Reachability * reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    online = networkStatus != NotReachable;
#endif
    return online;
}

@end

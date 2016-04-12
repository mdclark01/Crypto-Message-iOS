//
//  MyRNEncryptor.m
//  Crypto Message
//
//  Created by Michael Clark on 4/8/15.
//
//

#import <Foundation/Foundation.h>
#import "MyRNEncryptor.h"

@implementation MyRNEncryptor

+ (NSData *)encryptData:(NSData *)data password:(NSString *)password error:(NSError **)error {
    
    return [self encryptData:data withSettings:kRNCryptorAES256Settings password:password error:error];
}

+ (NSString *)stringFromData:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

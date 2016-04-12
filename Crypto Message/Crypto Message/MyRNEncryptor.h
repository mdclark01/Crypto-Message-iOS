//
//  MyRNEncryptor.h
//  Crypto Message
//
//  Created by Michael Clark on 4/8/15.
//
//

#import "RNEncryptor.h"

@interface MyRNEncryptor : RNEncryptor

+ (NSData *)encryptData:(NSData *)data password:(NSString *)password error:(NSError **)error;
+ (NSString *)stringFromData:(NSData *)data;

@end


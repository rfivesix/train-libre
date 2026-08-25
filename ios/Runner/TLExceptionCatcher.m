// ios/Runner/TLExceptionCatcher.m

#import "TLExceptionCatcher.h"

@implementation TLExceptionCatcher

+ (NSException *)catchException:(NS_NOESCAPE void (^)(void))block {
  @try {
    block();
    return nil;
  } @catch (NSException *exception) {
    return exception;
  }
}

@end

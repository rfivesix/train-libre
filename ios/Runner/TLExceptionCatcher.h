// ios/Runner/TLExceptionCatcher.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Bridges `@try/@catch` into Swift.
///
/// Swift cannot catch an `NSException`, and AVFoundation raises them: an
/// `AVCaptureSession` that is torn down at the wrong moment answers
/// `stopRunning` with a raised exception rather than an error, which took the
/// whole app down from a background queue.
@interface TLExceptionCatcher : NSObject

/// Runs `block`, returning the exception it raised, or nil when it completed.
+ (nullable NSException *)catchException:(NS_NOESCAPE void (^)(void))block;

@end

NS_ASSUME_NONNULL_END

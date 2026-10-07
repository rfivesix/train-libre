// ios/Runner/LocalModelRunner.h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalModelRunner : NSObject

+ (BOOL)isAvailable;

+ (nullable NSString *)runInferenceWithModelPath:(NSString *)modelPath
                                     mmprojPath:(nullable NSString *)mmprojPath
                                         prompt:(NSString *)prompt
                                   imagesBase64:(NSArray<NSString *> *)imagesBase64
                                          error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END

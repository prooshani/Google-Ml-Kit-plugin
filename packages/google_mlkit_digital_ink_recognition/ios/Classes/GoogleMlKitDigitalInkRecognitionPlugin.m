#import "GoogleMlKitDigitalInkRecognitionPlugin.h"
#import "GenericModelManager.h"
#import <MLKitCommon/MLKitCommon.h>
#import <MLKitDigitalInkRecognition/MLKitDigitalInkRecognition.h>
#import <google_mlkit_commons/GoogleMlKitCommonsPlugin.h>

#define channelName @"google_mlkit_digital_ink_recognizer"
#define startDigitalInkRecognizer @"vision#startDigitalInkRecognizer"
#define closeDigitalInkRecognizer @"vision#closeDigitalInkRecognizer"
#define manageInkModels @"vision#manageInkModels"

@implementation GoogleMlKitDigitalInkRecognitionPlugin {
    MLKDigitalInkRecognizer *recognizer;
    GenericModelManager *genericModelManager;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:channelName
                                     binaryMessenger:[registrar messenger]];
    GoogleMlKitDigitalInkRecognitionPlugin* instance = [[GoogleMlKitDigitalInkRecognitionPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:startDigitalInkRecognizer]) {
        [self handleDetection:call result:result];
    } else if ([call.method isEqualToString:manageInkModels]) {
        [self manageModel:call result:result];
    } else if ([call.method isEqualToString:closeDigitalInkRecognizer]) {
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleDetection:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSArray *pointsList = call.arguments[@"points"];
    NSString *modelTag = call.arguments[@"model"];
    
    MLKDigitalInkRecognitionModelIdentifier *identifier =
    [MLKDigitalInkRecognitionModelIdentifier modelIdentifierForLanguageTag:modelTag];
    MLKDigitalInkRecognitionModel *model = [[MLKDigitalInkRecognitionModel alloc]
                                            initWithModelIdentifier:identifier];
    
    MLKModelManager *modelManager = [MLKModelManager modelManager];
    
    BOOL isModelDownloaded = [modelManager isModelDownloaded:model];
    
    if (!isModelDownloaded) {
        FlutterError *error = [FlutterError errorWithCode:@"Error Model has not been downloaded yet"
                                                  message:@"Model has not been downloaded yet"
                                                  details:@"Model has not been downloaded yet"];
        result(error);
        return;
    }
    
    MLKDigitalInkRecognizerOptions *options = [[MLKDigitalInkRecognizerOptions alloc] initWithModel:model];
    recognizer = [MLKDigitalInkRecognizer digitalInkRecognizerWithOptions:options];
    
    NSMutableArray *points = [NSMutableArray array];
    for (NSDictionary *pointMap in pointsList) {
        NSNumber *x = pointMap[@"x"];
        NSNumber *y = pointMap[@"y"];
        MLKStrokePoint *strokePoint = [[MLKStrokePoint alloc] initWithX:x.floatValue y:y.floatValue];
        [points addObject:strokePoint];
    }
    
    NSMutableArray *strokes = [NSMutableArray array];
    [strokes addObject:[[MLKStroke alloc] initWithPoints:points]];
    
    MLKInk *ink = [[MLKInk alloc] initWithStrokes:strokes];
    
    [recognizer recognizeInk:ink
                  completion:^(MLKDigitalInkRecognitionResult * _Nullable recognitionResult, NSError * _Nullable error) {
        if (error) {
            result(getFlutterError(error));
            return;
        } else if (!recognitionResult) {
            result(NULL);
            return;
        }
        NSMutableArray *candidates = [NSMutableArray new];
        for(MLKDigitalInkRecognitionCandidate *candidate in recognitionResult.candidates) {
            NSDictionary *dictionary = @{@"text": candidate.text,
                                         @"score": @(candidate.score.doubleValue)};
            [candidates addObject:dictionary];
        }
        result(candidates);
    }];
}

- (void)manageModel:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *modelTag = call.arguments[@"model"];
    MLKDigitalInkRecognitionModelIdentifier *identifier = [MLKDigitalInkRecognitionModelIdentifier modelIdentifierForLanguageTag:modelTag];
    MLKDigitalInkRecognitionModel *model = [[MLKDigitalInkRecognitionModel alloc] initWithModelIdentifier:identifier];
    genericModelManager = [[GenericModelManager alloc] init];
    [genericModelManager manageModel:model call:call result:result];
}

@end

#import "GoogleMlKitLanguageIdPlugin.h"
#import <MLKitLanguageID/MLKitLanguageID.h>
#import <google_mlkit_commons/GoogleMlKitCommonsPlugin.h>

#define channelName @"google_mlkit_language_identifier"
#define startLanguageIdentifier @"nlp#startLanguageIdentifier"
#define closeLanguageIdentifier @"nlp#closeLanguageIdentifier"

@implementation GoogleMlKitLanguageIdPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:channelName
                                     binaryMessenger:[registrar messenger]];
    GoogleMlKitLanguageIdPlugin* instance = [[GoogleMlKitLanguageIdPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:startLanguageIdentifier]) {
        [self handleDetection:call result:result];
    } else if ([call.method isEqualToString:closeLanguageIdentifier]) {
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleDetection:(FlutterMethodCall *)call result:(FlutterResult)result {
    BOOL possibleLanguages = [call.arguments[@"possibleLanguages"] boolValue];
    NSString *text = call.arguments[@"text"];
    NSNumber *confidence = call.arguments[@"confidence"];
    MLKLanguageIdentification *languageId = [self getLanguageIdentifier:confidence.floatValue];
    
    if(possibleLanguages) {
        [self identifyPossibleLanguagesInText:text languageId:languageId result:result];
    } else {
        [self identifyLanguageInText:text languageId:languageId result:result];
    }
}

// Identifies the possible languages for a given text.
// For each identified langauge a confidence value is returned as well.
// Read more here: https://developers.google.com/ml-kit/language/identification/ios
- (void)identifyPossibleLanguagesInText:(NSString *)text
                             languageId:(MLKLanguageIdentification *)languageId
                                 result:(FlutterResult)result {
    [languageId identifyPossibleLanguagesForText:text
                                      completion:^(NSArray * _Nonnull identifiedLanguages,
                                                   NSError * _Nullable error) {
        if (error != nil) {
            result(getFlutterError(error));
            return;
        }
        NSMutableArray *resultArray = [NSMutableArray array];
        for (MLKIdentifiedLanguage *language in identifiedLanguages) {
            NSDictionary *data = @{
                @"language" : language.languageTag,
                @"confidence" : [NSNumber numberWithFloat: language.confidence],
            };
            [resultArray addObject:data];
        }
        result(resultArray);
    }];
}

// Identify the language for a given text.
// Read more here: https://developers.google.com/ml-kit/language/identification/ios
- (void)identifyLanguageInText:(NSString *)text
                    languageId:(MLKLanguageIdentification *)languageId
                        result:(FlutterResult)result {
    [languageId identifyLanguageForText:text
                             completion:^(NSString * _Nonnull languageTag,
                                          NSError * _Nullable error) {
        if (error != nil) {
            result(getFlutterError(error));
            return;
        }
        result(languageTag);
    }];
}

- (MLKLanguageIdentification*)getLanguageIdentifier:(float) confidence {
    MLKLanguageIdentificationOptions *options = [[MLKLanguageIdentificationOptions alloc] initWithConfidenceThreshold:confidence];
    MLKLanguageIdentification *languageId = [MLKLanguageIdentification languageIdentificationWithOptions:options];
    return languageId;
}

@end

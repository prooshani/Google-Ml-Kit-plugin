#import "GoogleMlKitSmartReplyPlugin.h"
#import <MLKitSmartReply/MLKitSmartReply.h>
#import <google_mlkit_commons/GoogleMlKitCommonsPlugin.h>

#define channelName @"google_mlkit_smart_reply"
#define startSmartReply @"nlp#startSmartReply"
#define closeSmartReply @"nlp#closeSmartReply"

@implementation GoogleMlKitSmartReplyPlugin {
    MLKSmartReply *smartReply;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:channelName
                                     binaryMessenger:[registrar messenger]];
    GoogleMlKitSmartReplyPlugin* instance = [[GoogleMlKitSmartReplyPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([call.method isEqualToString:startSmartReply]) {
        [self handleStartSmartReply:call result:result];
    } else if ([call.method isEqualToString:closeSmartReply]) {
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleStartSmartReply:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSMutableArray *conversation = [NSMutableArray array];
    NSArray *json = call.arguments[@"conversation"];
    for (NSDictionary *object in json) {
        NSString *text = object[@"message"];
        NSNumber *timestamp = object[@"timestamp"];
        NSString *userId = object[@"userId"];
        BOOL isLocalUser = [userId isEqualToString: @"local"];
        
        MLKTextMessage *message = [[MLKTextMessage alloc]
                                   initWithText: text
                                   timestamp:timestamp.doubleValue
                                   userID:userId
                                   isLocalUser:isLocalUser];
        [conversation addObject:message];
    }
    
    smartReply = [MLKSmartReply smartReply];
    [smartReply suggestRepliesForMessages:conversation
                               completion:^(MLKSmartReplySuggestionResult * _Nullable smartReplySuggestionResult,
                                            NSError * _Nullable error) {
        if (error) {
            result(getFlutterError(error));
            return;
        } else if (!smartReplySuggestionResult) {
            result(NULL);
            return;
        }
        
        NSMutableDictionary *suggestionResult = [NSMutableDictionary dictionary];
        suggestionResult[@"status"] = @(smartReplySuggestionResult.status);
        if (smartReplySuggestionResult.status == MLKSmartReplyResultStatusSuccess) {
            NSMutableArray *suggestions = [NSMutableArray array];
            for (MLKSmartReplySuggestion *suggestion in smartReplySuggestionResult.suggestions) {
                [suggestions addObject:suggestion.text];
            }
            suggestionResult[@"suggestions"] = suggestions;
        }
        result(suggestionResult);
    }];
}

@end

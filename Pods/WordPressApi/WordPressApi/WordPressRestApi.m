//
//  WordPressRestApi.m
//  WordPressApiExample
//
//  Created by Jorge Bernal on 2/20/13.
//  Copyright (c) 2013 Automattic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

#import "WordPressRestApi.h"
#import "WordPressRestApiJSONRequestOperation.h"
#import "WordPressRestApiJSONRequestOperationManager.h"
#import "WPComOAuthController.h"

NSString *const WordPressRestApiEndpointURL = @"https://public-api.wordpress.com/rest/v1/";
NSString *const WordPressRestApiErrorDomain = @"WordPressRestApiError";
NSString *const WordPressRestApiErrorCodeKey = @"WordPressRestApiErrorCodeKey";

@implementation WordPressRestApi {
    NSString *_token;
    NSString *_siteId;
    AFHTTPRequestOperationManager *_operationManager;
}

static NSString *WordPressRestApiClient = nil;
static NSString *WordPressRestApiSecret = nil;
static NSString *WordPressRestApiRedirectUrl = nil;

+ (void)signInWithOauthWithSuccess:(void (^)(NSString *authToken, NSString *siteId))success failure:(void (^)(NSError *error))failure {
    [[WPComOAuthController sharedController] setCompletionBlock:^(NSString *token, NSString *blogId, NSString *blogUrl, NSString *scope, NSError *error) {
        if (error) {
            failure(error);
        } else {
            success(token, blogId);
        }
    }];
    [[WPComOAuthController sharedController] present];
}

+ (void)signInWithJetpackUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *authToken))success failure:(void (^)(NSError *error))failure {
    NSAssert(NO, @"Not implemented yet");
}

- (id<WordPressBaseApi>)initWithOauthToken:(NSString *)authToken siteId:(NSString *)siteId {
    self = [super init];
    
	if (self) {
		NSURL* baseURL = [NSURL URLWithString:WordPressRestApiEndpointURL];
		
        _token = authToken;
        _siteId = siteId;
		
        _operationManager = [[WordPressRestApiJSONRequestOperationManager alloc] initWithBaseURL:baseURL
																						   token:_token];
    }
	
    return self;
}

+ (BOOL)handleOpenURL:(NSURL *)url {
    return [[WPComOAuthController sharedController] handleOpenURL:url];
}

+ (void)setWordPressComClient:(NSString *)clientId {
    WordPressRestApiClient = clientId;
    [[WPComOAuthController sharedController] setClient:clientId];
}

+ (void)setWordPressComSecret:(NSString *)secret {
    WordPressRestApiSecret = secret;
    [[WPComOAuthController sharedController] setSecret:secret];
}

+ (void)setWordPressComRedirectUrl:(NSString *)redirectUrl {
    WordPressRestApiRedirectUrl = redirectUrl;
    [[WPComOAuthController sharedController] setRedirectUrl:redirectUrl];
}

#pragma mark - WordPressBaseApi methods

- (void)publishPostWithText:(NSString *)content title:(NSString *)title success:(void (^)(NSUInteger postId, NSURL *permalink))success failure:(void (^)(NSError *error))failure {
    NSDictionary *parameters = @{
                                 @"title": title,
                                 @"content": content
                                 };
    [_operationManager POST:[self sitePath:@"posts/new"]
				 parameters:parameters
					success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		NSUInteger postId = [[responseObject objectForKey:@"ID"] unsignedIntegerValue];
		NSURL *permalink = [NSURL URLWithString:[responseObject objectForKey:@"URL"]];
		success(postId, permalink);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)publishPostWithImage:(UIImage *)image description:(NSString *)content title:(NSString *)title success:(void (^)(NSUInteger postId, NSURL *permalink))success failure:(void (^)(NSError *error))failure {
    if (image) {
        [self publishPostWithGallery:@[image] description:content title:title success:success failure:failure];
    } else {
        [self publishPostWithText:content title:title success:success failure:failure];
    }
}

- (void)publishPostWithGallery:(NSArray *)images description:(NSString *)content title:(NSString *)title success:(void (^)(NSUInteger postId, NSURL *permalink))success failure:(void (^)(NSError *error))failure {
    if (![images count]) {
        [self publishPostWithText:content title:title success:success failure:failure];
    }

	void(^contructionBlock)(id<AFMultipartFormData>) = ^(id<AFMultipartFormData> formData)
	{
		[images enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSData *imageData = UIImageJPEGRepresentation(obj, 1.f);
			[formData appendPartWithFileData:imageData name:@"media[]"
									fileName:[NSString stringWithFormat:@"image-%tu.jpg", idx]
									mimeType:@"image/jpeg"];
		}];
	};
	
	void(^successBlock)(AFHTTPRequestOperation* operation, id responseObject) = ^(AFHTTPRequestOperation *operation,
																				  id responseObject)
	{
		NSUInteger postId = [[responseObject objectForKey:@"ID"] unsignedIntegerValue];
		NSURL *permalink = [NSURL URLWithString:[responseObject objectForKey:@"URL"]];
		success(postId, permalink);
	};
	
	void(^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation,
																			   NSError *error)
	{
        failure(error);
    };
	
    NSDictionary *parameters = @{
                                 @"title": title,
                                 @"content": content
                                 };
	[_operationManager POST:[self sitePath:@"posts/new"]
				 parameters:parameters
  constructingBodyWithBlock:contructionBlock
					success:successBlock
					failure:failureBlock];
}

- (void)getPosts:(NSUInteger)count success:(void (^)(NSArray *posts))success failure:(void (^)(NSError *error))failure {
    [_operationManager GET:[self sitePath:@"posts"]
				parameters:nil
				   success:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		success([responseObject objectForKey:@"posts"]);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

#pragma mark - API Helpers

- (NSString *)sitePath:(NSString *)path {
    return [NSString stringWithFormat:@"sites/%@/%@", _siteId, path];
}

@end

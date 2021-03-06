#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <WordPressApi/WordPressApi.h>

#import "WordPressComApi.h"

@class Blog;

@interface WPAccount : NSManagedObject

///-----------------
/// @name Properties
///-----------------

@property (nonatomic, copy) NSString *xmlrpc;
@property (nonatomic, copy) NSString *username;
@property (nonatomic) BOOL isWpcom;
@property (nonatomic, strong) NSSet *blogs;
@property (nonatomic, strong) NSSet *jetpackBlogs;
@property (nonatomic, readonly) NSArray *visibleBlogs;

/**
 The account's password
 
 Note that the password is stored using the keychain, not core data
 */
@property (nonatomic, copy) NSString *password;

/**
 The OAuth2 auth token for WordPress.com accounts
 */
@property (nonatomic, copy) NSString *authToken;


///------------------
/// @name API Helpers
///------------------

/**
 A WordPressComApi object if the account is a WordPress.com account. Otherwise, it returns `nil`
 */
@property (nonatomic, readonly) WordPressComApi *restApi;

/**
 A WordPressXMLRPCApi object configured for the XML-RPC endpoint
 */
@property (nonatomic, readonly) WordPressXMLRPCApi *xmlrpcApi;

@end

@interface WPAccount (CoreDataGeneratedAccessors)

- (void)addBlogsObject:(Blog *)value;
- (void)removeBlogsObject:(Blog *)value;
- (void)addBlogs:(NSSet *)values;
- (void)removeBlogs:(NSSet *)values;

- (void)addJetpackBlogsObject:(Blog *)value;
- (void)removeJetpackBlogsObject:(Blog *)value;
- (void)addJetpackBlogs:(NSSet *)values;
- (void)removeJetpackBlogs:(NSSet *)values;

@end

#import "GAPlugin.h"
#import "AppDelegate.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation GAPlugin

- (void) initGA:(CDVInvokedUrlCommand*)command
{
    NSString* callbackId = command.callbackId;
    NSString* accountID = [command.arguments objectAtIndex:0];
    NSInteger dispatchPeriod = [[command.arguments objectAtIndex:1] intValue];

    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = dispatchPeriod;
    //Anonymize IP
    [[GAI sharedInstance].defaultTracker set:kGAIAnonymizeIp value:@"1"];
    // Optional: set debug to YES for extra debugging information.
    //[GAI sharedInstance].debug = YES;
    // Create tracker instance.
    [[GAI sharedInstance] trackerWithTrackingId:accountID];
    inited = YES;

    [self successWithMessage:[NSString stringWithFormat:@"initGA: accountID = %@; Interval = %ld seconds",accountID, (long)dispatchPeriod] toID:callbackId];
}

- (void)addCustomDimensionsToTracker: (id<GAITracker>)tracker
{
    if (_customDimensions) {
        for (NSString* key in _customDimensions) {
            NSString* value = [_customDimensions objectForKey:key];
            
            /* NSLog(@"Setting tracker dimension slot %@: <%@>", key, value); */
            [tracker set:[GAIFields customDimensionForIndex:[key intValue]]
                   value:value];
        }
    }
}

- (void) setVariable:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* key = [command.arguments objectAtIndex:0];
    NSString* value = [command.arguments objectAtIndex:1];
    
    if ( ! _customDimensions) {
        _customDimensions = [[NSMutableDictionary alloc] init];
    }
    
    _customDimensions[key] = value;
    [self addCustomDimensionsToTracker:[[GAI sharedInstance] defaultTracker]];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) exitGA:(CDVInvokedUrlCommand*)command
{
    if (inited) {
        [[GAI sharedInstance] dispatch];
    }

    [self successWithMessage:@"exitGA" toID:command.callbackId];
}

- (void) trackEvent:(CDVInvokedUrlCommand*)command
{
    @try  {
        NSString* category = [command.arguments objectAtIndex:0];
        NSString* eventAction = [command.arguments objectAtIndex:1];
        NSString* eventLabel = [command.arguments objectAtIndex:2];
        id        eventValueObject = [command.arguments objectAtIndex:3];
        NSNumber* eventValue = nil;
        
        if (eventValueObject != [NSNull null]) {
            eventValue = [NSNumber numberWithInteger:[eventValueObject integerValue]];
        }
        
        if (inited) {
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            
            [self addCustomDimensionsToTracker:tracker];
            
            [tracker send:[[GAIDictionaryBuilder
                            createEventWithCategory: category //required
                            action: eventAction //required
                            label: eventLabel
                            value: eventValueObject] build]];
            
            [self successWithMessage:[NSString stringWithFormat:@"trackEvent: category = %@; action = %@; label = %@; value = %d", category, eventAction, eventLabel, [eventValue intValue]] toID:command.callbackId];
            
        } else {
            [self failWithMessage:@"trackEvent failed - not initialized" toID:command.callbackId withError:nil];
        }
        
    } @catch (NSException* exception) {
        [self failWithMessage:[NSString stringWithFormat:@"trackEvent failed - exception name: %@, reason: %@", exception.name, exception.reason] toID:command.callbackId withError:nil];
    }
}

- (void) trackPage:(CDVInvokedUrlCommand*)command
{
    NSString* pageURL = [command.arguments objectAtIndex:0];

    if (inited) {
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

        [tracker set:kGAIScreenName value:pageURL];
        [tracker send:[[GAIDictionaryBuilder createAppView]  build]];

        [self successWithMessage:[NSString stringWithFormat:@"trackPage: url = %@", pageURL] toID:command.callbackId];
    } else {
        [self failWithMessage:@"trackPage failed - not initialized" toID:command.callbackId withError:nil];
    }
}

- (void) successWithMessage:(NSString *)message toID:(NSString *)callbackID
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void) failWithMessage:(NSString *)message toID:(NSString *)callbackID withError:(NSError *)error
{
    NSString        *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];

    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void) trackTransaction: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if ( ! inited) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tracker not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *transactionId = nil;
    NSString *affiliation = nil;
    NSNumber *revenue = nil;
    NSNumber *tax = nil;
    NSNumber *shipping = nil;
    NSString *currencyCode = nil;
    
    @try {
    
        if ([command.arguments count] > 0)
            transactionId = [command.arguments objectAtIndex:0];
        
        if ([command.arguments count] > 1)
            affiliation = [command.arguments objectAtIndex:1];
        
        if ([command.arguments count] > 2)
            revenue = [command.arguments objectAtIndex:2];
        
        if ([command.arguments count] > 3)
            tax = [command.arguments objectAtIndex:3];
        
        if ([command.arguments count] > 4)
            shipping = [command.arguments objectAtIndex:4];
        
        if ([command.arguments count] > 5) {
            //currencyCode = [command.arguments objectAtIndex:5];
            NSLocale *locale = [NSLocale currentLocale];
            currencyCode = [locale objectForKey:NSLocaleCurrencyCode]; 
        }
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        
        [tracker send:[[GAIDictionaryBuilder createTransactionWithId:transactionId             // (NSString) Transaction ID
                                                         affiliation:affiliation         // (NSString) Affiliation
                                                             revenue:revenue                  // (NSNumber) Order revenue (including tax and shipping)
                                                                 tax:tax                  // (NSNumber) Tax
                                                            shipping:shipping                      // (NSNumber) Shipping
                                                        currencyCode:currencyCode] build]];        // (NSString) Currency code
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    }
    @catch (NSException *exception) {
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    @finally {

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}



- (void) trackTransactionItem: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if ( ! inited) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tracker not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *transactionId = nil;
    NSString *name = nil;
    NSString *sku = nil;
    NSString *category = nil;
    NSNumber *price = nil;
    NSNumber *quantity = nil;
    NSString *currencyCode = nil;
    
    
    @try {
        if ([command.arguments count] > 0)
            transactionId = [command.arguments objectAtIndex:0];
        
        if ([command.arguments count] > 1)
            name = [command.arguments objectAtIndex:1];
        
        if ([command.arguments count] > 2)
            sku = [command.arguments objectAtIndex:2];
        
        if ([command.arguments count] > 3)
            category = [command.arguments objectAtIndex:3];
        
        if ([command.arguments count] > 4)
            price = [command.arguments objectAtIndex:4];
        
        if ([command.arguments count] > 5)
            quantity = [command.arguments objectAtIndex:5];
        
        if ([command.arguments count] > 6) {
            //currencyCode = [command.arguments objectAtIndex:6];
            NSLocale *locale = [NSLocale currentLocale];
            currencyCode = [locale objectForKey:NSLocaleCurrencyCode]; 
        }
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        
        [tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:transactionId         // (NSString) Transaction ID
                                                                    name:name  // (NSString) Product Name
                                                                     sku:sku           // (NSString) Product SKU
                                                                category:category  // (NSString) Product category
                                                                   price:price               // (NSNumber)  Product price
                                                                quantity:quantity                 // (NSNumber)  Product quantity
                                                            currencyCode:currencyCode] build]];    // (NSString) Currency code
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    @catch (NSException *exception) {
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    @finally {
       [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

//track transaction and item in just one method
- (void) trackTransactionAndItem: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if ( ! inited) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tracker not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *transactionId = nil;
    NSString *affiliation = nil;
    NSNumber *revenue = nil;
    NSNumber *tax = nil;
    NSNumber *shipping = nil;
    NSString *currencyCode = nil;
    NSString *name = nil;
    NSString *sku = nil;
    NSString *category = nil;
    NSNumber *price = nil;
    NSNumber *quantity = nil;
    
    //Args: transactionId, affiliation, revenue, tax, shipping, name ,sku, category, price, quantity, currencyCode
    @try {
    
        if ([command.arguments count] > 0)
            transactionId = [command.arguments objectAtIndex:0];
        
        if ([command.arguments count] > 1)
            affiliation = [command.arguments objectAtIndex:1];
        
        if ([command.arguments count] > 2)
            revenue = [command.arguments objectAtIndex:2];
        
        if ([command.arguments count] > 3)
            tax = [command.arguments objectAtIndex:3];
        
        if ([command.arguments count] > 4)
            shipping = [command.arguments objectAtIndex:4];

        if ([command.arguments count] > 5)
            name = [command.arguments objectAtIndex:5];

        if ([command.arguments count] > 6)
            sku = [command.arguments objectAtIndex:6];

        if ([command.arguments count] > 7)
            category = [command.arguments objectAtIndex:7];

        if ([command.arguments count] > 8)
            price = [command.arguments objectAtIndex:8];

        if ([command.arguments count] > 9)
            quantity = [command.arguments objectAtIndex:9];
        
        if ([command.arguments count] > 10) {
            //currencyCode = [command.arguments objectAtIndex:10];
            NSLocale *locale = [NSLocale currentLocale];
            currencyCode = [locale objectForKey:NSLocaleCurrencyCode]; 
        }
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        
        
        [tracker send:[[GAIDictionaryBuilder createTransactionWithId:transactionId             // (NSString) Transaction ID
                                                         affiliation:affiliation         // (NSString) Affiliation
                                                             revenue:revenue                  // (NSNumber) Order revenue (including tax and shipping)
                                                                 tax:tax                  // (NSNumber) Tax
                                                            shipping:shipping                      // (NSNumber) Shipping
                                                        currencyCode:currencyCode] build]];        // (NSString) Currency code
        //use the same tracker object to set the item
        [tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:transactionId         // (NSString) Transaction ID
                                                                    name:name  // (NSString) Product Name
                                                                     sku:sku           // (NSString) Product SKU
                                                                category:category  // (NSString) Product category
                                                                   price:price               // (NSNumber)  Product price
                                                                quantity:quantity                 // (NSNumber)  Product quantity
                                                            currencyCode:currencyCode] build]];    // (NSString) Currency code

        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    }
    @catch (NSException *exception) {
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    @finally {

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)dealloc
{
    [[GAI sharedInstance] dispatch];
}

@end
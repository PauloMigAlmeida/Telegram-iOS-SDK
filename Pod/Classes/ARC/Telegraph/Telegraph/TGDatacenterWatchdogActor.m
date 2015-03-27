/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGDatacenterWatchdogActor.h"

#import "ActionStage.h"

#import "MTContext.h"
#import "MTProto.h"
#import "MTTimer.h"
#import "MTRequestMessageService.h"
#import "MTRequest.h"
#import "MTDatacenterAddressSet.h"
#import "MTDatacenterAddress.h"

#import "TGTelegramNetworking.h"

#import "TLMetaScheme.h"
#import "TGCommon.h"

@interface TGDatacenterWatchdogActor ()
{
    MTTimer *_startupTimer;
    MTTimer *_addOneMoreDatacenterTimer;
    
    NSMutableSet *_processedDatacenters;
    
    id _mainMtProtoRequestId;
    
    MTProto *_currentMtProto;
    MTRequestMessageService *_currentRequestService;
}

@end

@implementation TGDatacenterWatchdogActor

+ (void)load
{
    [ASActor registerActorClass:self];
}

+ (NSString *)genericPath
{
    return @"/tg/datacenterWatchdog";
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self != nil)
    {
    }
    return self;
}

- (void)dealloc
{
    [_startupTimer invalidate];
    _startupTimer = nil;
    
    [_addOneMoreDatacenterTimer invalidate];
    _addOneMoreDatacenterTimer = nil;
    
    [_currentMtProto removeMessageService:_currentRequestService];
    [_currentMtProto stop];
}

- (void)execute:(NSDictionary *)__unused options
{
    __weak TGDatacenterWatchdogActor *weakSelf = self;
    _startupTimer = [[MTTimer alloc] initWithTimeout:8.0 repeat:false completion:^
    {
        __strong TGDatacenterWatchdogActor *strongSelf = weakSelf;
        [strongSelf begin];
    } queue:[ActionStageInstance() globalStageDispatchQueue]];
    [_startupTimer start];
}

- (void)begin
{
    MTContext *context = [[TGTelegramNetworking instance] context];
    if (context == nil)
        [ActionStageInstance() actionFailed:self.path reason:-1];
    else
    {
        [self tryMainMtProto];
    }
}

- (void)tryMainMtProto
{
    MTRequest *request = [[MTRequest alloc] init];
    request.body = [[TLRPChelp_getConfig$help_getConfig alloc] init];
    
    __weak TGDatacenterWatchdogActor *weakSelf = self;
    [request setCompleted:^(TLConfig *result, __unused NSTimeInterval timestamp, id error)
    {
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            __strong TGDatacenterWatchdogActor *strongSelf = weakSelf;
            if (error == nil)
            {
                [strongSelf processConfig:result fromDatacenterId:[[TGTelegramNetworking instance] masterDatacenterId]];
            }
        }];
    }];
    
    _addOneMoreDatacenterTimer = [[MTTimer alloc] initWithTimeout:10.0 repeat:true completion:^
    {
        __strong TGDatacenterWatchdogActor *strongSelf = weakSelf;
        [strongSelf switchToNextDatacenter];
    } queue:[ActionStageInstance() globalStageDispatchQueue]];
    [_addOneMoreDatacenterTimer start];
    
    _mainMtProtoRequestId = request.internalId;
    [[TGTelegramNetworking instance] addRequest:request];
}

- (void)switchToNextDatacenter
{
    MTContext *context = [[TGTelegramNetworking instance] context];
    
    [_currentMtProto removeMessageService:_currentRequestService];
    [_currentMtProto stop];
    _currentMtProto = nil;
    _currentRequestService = nil;
    
    if (_mainMtProtoRequestId != nil)
    {
        [[TGTelegramNetworking instance] cancelRpc:_mainMtProtoRequestId];
        _mainMtProtoRequestId = nil;
    }
    
    bool foundDatacenter = false;
    NSInteger datacenterId = 0;
    for (NSNumber *nDatacenterId in [context knownDatacenterIds])
    {
        if (![_processedDatacenters containsObject:nDatacenterId])
        {
            if (_processedDatacenters == nil)
                _processedDatacenters = [[NSMutableSet alloc] init];
            [_processedDatacenters addObject:nDatacenterId];
            
            foundDatacenter = true;
            datacenterId = [nDatacenterId integerValue];
            
            break;
        }
    }
    
    if (!foundDatacenter)
    {
        [_processedDatacenters removeAllObjects];
        
        NSNumber *nDatacenterId = [context knownDatacenterIds].firstObject;
        if (nDatacenterId != nil)
        {
            [_processedDatacenters addObject:nDatacenterId];
            foundDatacenter = true;
            datacenterId = [nDatacenterId integerValue];
        }
    }
    
    if (foundDatacenter)
        [self requestNetworkConfigFromDatacenter:datacenterId];
}

- (void)requestNetworkConfigFromDatacenter:(NSInteger)datacenterId
{
    TGLog(@"[TGDatacenterWatchdogActor#%p requesting network config from %d]", self, (int)datacenterId);
    
    MTContext *context = [[TGTelegramNetworking instance] context];
    
    MTProto *mtProto = [[MTProto alloc] initWithContext:context datacenterId:datacenterId];
    MTRequestMessageService *requestService = [[MTRequestMessageService alloc] initWithContext:context];
    [mtProto addMessageService:requestService];
    
    _currentMtProto = mtProto;
    _currentRequestService = requestService;
    
    MTRequest *request = [[MTRequest alloc] init];
    request.body = [[TLRPChelp_getConfig$help_getConfig alloc] init];
    
    __weak TGDatacenterWatchdogActor *weakSelf = self;
    [request setCompleted:^(TLConfig *result, __unused NSTimeInterval timestamp, id error)
    {
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            __strong TGDatacenterWatchdogActor *strongSelf = weakSelf;
            if (error == nil)
            {
                [strongSelf processConfig:result fromDatacenterId:datacenterId];
            }
        }];
    }];
    
    [requestService addRequest:request];
}

- (void)processConfig:(TLConfig *)config fromDatacenterId:(NSInteger)__unused datacenterId
{
    MTContext *context = [[TGTelegramNetworking instance] context];
    
    [context performBatchUpdates:^
    {        
        NSMutableDictionary *addressListByDatacenterId = [[NSMutableDictionary alloc] init];
        
        for (TLDcOption *dcOption in config.dc_options)
        {
            MTDatacenterAddress *configAddress = [[MTDatacenterAddress alloc] initWithIp:dcOption.ip_address port:(uint16_t)dcOption.port];
            
            NSMutableArray *array = addressListByDatacenterId[@(dcOption.n_id)];
            if (array == nil)
            {
                array = [[NSMutableArray alloc] init];
                addressListByDatacenterId[@(dcOption.n_id)] = array;
            }
            
            if (![array containsObject:configAddress])
                [array addObject:configAddress];
        }
        
        [addressListByDatacenterId enumerateKeysAndObjectsUsingBlock:^(NSNumber *nDatacenterId, NSArray *addressList, __unused BOOL *stop)
        {
            MTDatacenterAddressSet *addressSet = [[MTDatacenterAddressSet alloc] initWithAddressList:addressList];

            MTDatacenterAddressSet *currentAddressSet = [context addressSetForDatacenterWithId:[nDatacenterId integerValue]];
            
            if (currentAddressSet == nil || ![addressSet isEqual:currentAddressSet])
            {
                TGLog(@"[TGDatacenterWatchdogActor#%p updating datacenter %d address set to %@]", self, [nDatacenterId intValue], addressSet);
                [context updateAddressSetForDatacenterWithId:[nDatacenterId integerValue] addressSet:addressSet];
            }
        }];
        
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            TGLog(@"[TGDatacenterWatchdogActor#%p processed %d datacenter addresses from datacenter %d]", self, (int)config.dc_options.count, (int)datacenterId);
            
            [self _completed];
        }];
    }];
}

- (void)_completed
{
    _mainMtProtoRequestId = nil;
    
    NSTimeInterval nextCheckDelay = 60.0 * 60.0;
    
    [_addOneMoreDatacenterTimer invalidate];
    _addOneMoreDatacenterTimer = nil;
    
    [_processedDatacenters removeAllObjects];
    
    __weak TGDatacenterWatchdogActor *weakSelf = self;
    
    [_startupTimer invalidate];
    _startupTimer = [[MTTimer alloc] initWithTimeout:nextCheckDelay repeat:false completion:^
    {
        __strong TGDatacenterWatchdogActor *strongSelf = weakSelf;
        [strongSelf begin];
    } queue:[ActionStageInstance() globalStageDispatchQueue]];
    [_startupTimer start];
}

@end

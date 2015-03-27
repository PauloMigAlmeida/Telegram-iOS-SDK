#import "TLRPCgeochats_sendMedia.h"

#import "../NSInputStream+TL.h"
#import "../NSOutputStream+TL.h"
#import "TGCommon.h"
#import "TLInputGeoChat.h"
#import "TLInputMedia.h"
#import "TLgeochats_StatedMessage.h"

@implementation TLRPCgeochats_sendMedia


- (Class)responseClass
{
    return [TLgeochats_StatedMessage class];
}

- (int)impliedResponseSignature
{
    return (int)0x17b1578b;
}

- (int)layerVersion
{
    return 4;
}

- (int32_t)TLconstructorSignature
{
    TGLog(@"constructorSignature is not implemented for base type");
    return 0;
}

- (int32_t)TLconstructorName
{
    TGLog(@"constructorName is not implemented for base type");
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    TGLog(@"TLbuildFromMetaObject is not implemented for base type");
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
    TGLog(@"TLfillFieldsWithValues is not implemented for base type");
}


@end

@implementation TLRPCgeochats_sendMedia$geochats_sendMedia : TLRPCgeochats_sendMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xb8f0deff;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xd11c54c8;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLRPCgeochats_sendMedia$geochats_sendMedia *object = [[TLRPCgeochats_sendMedia$geochats_sendMedia alloc] init];
    object.peer = metaObject->getObject((int32_t)0x9344c37d);
    object.media = metaObject->getObject((int32_t)0x598de2e7);
    object.random_id = metaObject->getInt64((int32_t)0xca5a160a);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.peer;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x9344c37d, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.media;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x598de2e7, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt64;
        value.primitive.int64Value = self.random_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xca5a160a, value));
    }
}


@end


#import "TLDocumentAttribute.h"

#import "../NSInputStream+TL.h"
#import "../NSOutputStream+TL.h"
#import "TGCommon.h"


@implementation TLDocumentAttribute


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

@implementation TLDocumentAttribute$documentAttributeImageSize : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x6c37c15c;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x9b6d8cdd;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLDocumentAttribute$documentAttributeImageSize *object = [[TLDocumentAttribute$documentAttributeImageSize alloc] init];
    object.w = metaObject->getInt32((int32_t)0x98407fc3);
    object.h = metaObject->getInt32((int32_t)0x27243f49);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.w;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x98407fc3, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.h;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x27243f49, value));
    }
}


@end

@implementation TLDocumentAttribute$documentAttributeAnimated : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x11b58939;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xb1b0af2c;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    TLDocumentAttribute$documentAttributeAnimated *object = [[TLDocumentAttribute$documentAttributeAnimated alloc] init];
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}


@end

@implementation TLDocumentAttribute$documentAttributeSticker : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xfb0a5727;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x95bd6986;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)__unused metaObject
{
    TLDocumentAttribute$documentAttributeSticker *object = [[TLDocumentAttribute$documentAttributeSticker alloc] init];
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}


@end

@implementation TLDocumentAttribute$documentAttributeVideo : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x5910cccb;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xbd5974ef;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLDocumentAttribute$documentAttributeVideo *object = [[TLDocumentAttribute$documentAttributeVideo alloc] init];
    object.duration = metaObject->getInt32((int32_t)0xac00f752);
    object.w = metaObject->getInt32((int32_t)0x98407fc3);
    object.h = metaObject->getInt32((int32_t)0x27243f49);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.duration;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xac00f752, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.w;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x98407fc3, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.h;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x27243f49, value));
    }
}


@end

@implementation TLDocumentAttribute$documentAttributeAudio : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x51448e5;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x862f2721;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLDocumentAttribute$documentAttributeAudio *object = [[TLDocumentAttribute$documentAttributeAudio alloc] init];
    object.duration = metaObject->getInt32((int32_t)0xac00f752);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.duration;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xac00f752, value));
    }
}


@end

@implementation TLDocumentAttribute$documentAttributeFilename : TLDocumentAttribute


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x15590068;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xcddece5f;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::shared_ptr<TLMetaObject>)metaObject
{
    TLDocumentAttribute$documentAttributeFilename *object = [[TLDocumentAttribute$documentAttributeFilename alloc] init];
    object.file_name = metaObject->getString((int32_t)0x3fa248c4);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeString;
        value.nativeObject = self.file_name;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x3fa248c4, value));
    }
}


@end


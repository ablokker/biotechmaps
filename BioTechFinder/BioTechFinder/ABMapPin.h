//
//  ABMapPin.h
//  BioTechFinder
//
//  Created by Alex Blokker on 2/20/16.
//  Copyright © 2016 Blokkmani. All rights reserved.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABMapPin : NSObject <MKAnnotation>
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy, nullable) NSString *title;
@property (nonatomic, readonly, copy, nullable) NSString *subtitle;
- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description;
@end

NS_ASSUME_NONNULL_END

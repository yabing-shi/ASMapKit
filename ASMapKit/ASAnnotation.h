//
//  ASAnnotationView.h
//  ASMapKit
//
//  Created by shiyabing on 2017/10/20.
//  Copyright © 2017年 shiyabing. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface ASAnnotation : NSObject<MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic, strong) UIImage *image;//

@end

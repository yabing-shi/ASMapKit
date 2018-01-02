//
//  ASMapViewController.m
//  ASMapKit
//
//  Created by shiyabing on 2017/10/20.
//  Copyright © 2017年 shiyabing. All rights reserved.
//

#import "ASMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "ASAnnotation.h"

@interface ASMapViewController ()<MKMapViewDelegate>{
    CLLocationManager *_locationManager;
    MKMapView *_mapView;
}
@property (nonatomic,strong) CLGeocoder *geocoder;
//用于发送请求给服务器，获取规划好后的路线。
@property(strong,nonatomic)MKDirections *directs;

@end

@implementation ASMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _geocoder = [[CLGeocoder alloc]init];

    
    [self initGUI];
}

#pragma mark 添加地图控件
-(void)initGUI{
    CGRect rect=[UIScreen mainScreen].bounds;
    _mapView=[[MKMapView alloc]initWithFrame:rect];
    [self.view addSubview:_mapView];
    //设置代理
    _mapView.delegate=self;
    
    //为地图增加点击方法
    UITapGestureRecognizer *mapTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mTapPress:)];
    [_mapView addGestureRecognizer:mapTapGesture];
    
    //请求定位服务
    _locationManager=[[CLLocationManager alloc]init];
    if(![CLLocationManager locationServicesEnabled]||[CLLocationManager authorizationStatus]!=kCLAuthorizationStatusAuthorizedWhenInUse){
        [_locationManager requestWhenInUseAuthorization];
    }
    
    //用户位置追踪(用户位置追踪用于标记用户当前位置，此时会调用定位服务)
    _mapView.userTrackingMode=MKUserTrackingModeFollow;
    
    //设置地图类型
    _mapView.mapType = MKMapTypeStandard;
    
    //添加大头针
//    [self addAnnotation];
    [self turnByTurn];
}

#pragma mark 添加大头针
-(void)addAnnotation{
    CLLocationCoordinate2D location1 = CLLocationCoordinate2DMake(39.95, 116.35);
    ASAnnotation *annotation1 = [[ASAnnotation alloc]init];
    annotation1.title = @"CMJ Studio";
    annotation1.subtitle = @"Kenshin Cui's Studios";
    annotation1.coordinate = location1;
    [_mapView addAnnotation:annotation1];
    
    CLLocationCoordinate2D location2 = CLLocationCoordinate2DMake(39.87, 116.35);
    ASAnnotation *annotation2 = [[ASAnnotation alloc]init];
    annotation2.title = @"Kenshin&Kaoru";
    annotation2.subtitle = @"Kenshin Cui's Home";
    annotation2.coordinate = location2;
    [_mapView addAnnotation:annotation2];
}

#pragma mark - 地图控件代理方法
#pragma mark 更新用户位置，只要用户改变则调用此方法（包括第一次定位到用户位置）
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    NSLog(@"%@",userLocation);
    //设置地图显示范围(如果不进行区域设置会自动显示区域范围并指定当前用户位置为地图中心点)
    MKCoordinateSpan span=MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region=MKCoordinateRegionMake(userLocation.location.coordinate, span);
    [_mapView setRegion:region animated:true];
}

#pragma mark - 地图控件代理方法
#pragma mark 显示大头针时调用，注意方法中的annotation参数是即将显示的大头针对象
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    //由于当前位置的标注也是一个大头针，所以此时需要判断，此代理方法返回nil使用默认大头针视图
    if ([annotation isKindOfClass:[ASAnnotation class]]) {
        static NSString *key1=@"AnnotationKey1";
        MKAnnotationView *annotationView=[_mapView dequeueReusableAnnotationViewWithIdentifier:key1];
        //如果缓存池中不存在则新建
        if (!annotationView) {
            annotationView=[[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:key1];
            annotationView.canShowCallout=true;//允许交互点击
            annotationView.calloutOffset=CGPointMake(0, 1);//定义详情视图偏移量
            annotationView.leftCalloutAccessoryView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"location.png"]];//定义详情左侧视图
        }
        
        //修改大头针视图
        //重新设置此类大头针视图的大头针模型(因为有可能是从缓存池中取出来的，位置是放到缓存池时的位置)
        annotationView.annotation = annotation;
        annotationView.image=((ASAnnotation *)annotation).image;//设置大头针视图的图片
        
        return annotationView;
    }else {
        return nil;
    }
}

#pragma mark 取消选中时触发
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    [self removeCustomAnnotation];
}

#pragma mark 移除所用自定义大头针
-(void)removeCustomAnnotation{
    [_mapView.annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ASAnnotation class]]) {
            [_mapView removeAnnotation:obj];
        }
    }];
}

//点击地图事件
- (void)mTapPress:(UIGestureRecognizer*)gestureRecognizer {
    
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];//这里touchPoint是点击的某点在地图控件中的位置
    CLLocationCoordinate2D touchMapCoordinate =
    [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];//这里touchMapCoordinate就是该点的经纬度了
    
    NSLog(@"touching %f,%f",touchMapCoordinate.latitude,touchMapCoordinate.longitude);
    CLLocation *location = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark=[placemarks firstObject];

        ASAnnotation *annotationPoint = [[ASAnnotation alloc] init];
        annotationPoint.title = [NSString stringWithFormat:@"%@ %@",placemark.locality, placemark.subLocality];
        annotationPoint.subtitle = placemark.name;
        annotationPoint.coordinate = touchMapCoordinate;
        annotationPoint.image = [UIImage imageNamed:@"location.png"];
        [_mapView addAnnotation:annotationPoint];
        
    }];
}

-(void)turnByTurn{
    //根据“北京市”地理编码
    [_geocoder geocodeAddressString:@"北京市" completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *clPlacemark1=[placemarks firstObject];//获取第一个地标
        MKPlacemark *mkPlacemark1=[[MKPlacemark alloc]initWithPlacemark:clPlacemark1];
        [_mapView setRegion:MKCoordinateRegionMake(mkPlacemark1.coordinate, MKCoordinateSpanMake(mkPlacemark1.coordinate.latitude, mkPlacemark1.coordinate.longitude))];
        //注意地理编码一次只能定位到一个位置，不能同时定位，所在放到第一个位置定位完成回调函数中再次定位
        [_geocoder geocodeAddressString:@"廊坊市" completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *clPlacemark2=[placemarks firstObject];//获取第一个地标
            MKPlacemark *mkPlacemark2=[[MKPlacemark alloc]initWithPlacemark:clPlacemark2];
            NSDictionary *options=@{MKLaunchOptionsMapTypeKey:@(MKMapTypeStandard),MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving};
//            MKMapItem *mapItem1=[MKMapItem mapItemForCurrentLocation];//当前位置
            MKMapItem *mapItem1=[[MKMapItem alloc]initWithPlacemark:mkPlacemark1];
            MKMapItem *mapItem2=[[MKMapItem alloc]initWithPlacemark:mkPlacemark2];
//            [MKMapItem openMapsWithItems:@[mapItem1,mapItem2] launchOptions:options];//打开系统自带地图导航
            [self requesrWithItem:mapItem1 andItem2:mapItem2];//请求路径信息
        }];
    }];
}

-(void)requesrWithItem:(MKMapItem *)item1 andItem2:(MKMapItem *)item2
{
    
    //  接收传入的参数，向苹果服务器发送请求
    //  创建请求体，设置请求体的总店和起点
    MKDirectionsRequest *requst = [[MKDirectionsRequest alloc]init];
    requst.source = item1;
    requst.destination = item2;
    
    // 发送请求
    self.directs = [[MKDirections alloc]initWithRequest:requst];
    // 服务器计算好路径后给我们返回了数据
    [self.directs calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse * _Nullable response, NSError * _Nullable error) {
        
        //  获取所有规划的路径
        NSArray *routes = response.routes;
        //  获取规划路径中的的最后一条路径，如果只返回一条路径就能取到那一条
        MKRoute *route = routes.lastObject;
        //  定义数组保存路线中的每一步
        NSArray *stepArr = route.steps;
        //  遍历路线中的每一步
        for (MKRouteStep *step in stepArr) {
            //   打印路线的信息
            NSLog(@"%f %@",step.distance,step.instructions);
            //   绘制遮盖打印到地图上，绘制方法的实现在下面
            [_mapView addOverlay:step.polyline];
        }
    }];
}

// 返回指定的遮盖模型所对应的遮盖视图, renderer-渲染
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay{
    // 判断类型是不是MKOverlay类型
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        //  针对线段，系统有提供好的遮盖样式
        MKPolylineRenderer *render = [[MKPolylineRenderer alloc]initWithOverlay:overlay];
        //  配置渲染的宽度和渲染的颜色
        render.lineWidth = 5;
        render.strokeColor = [UIColor redColor];
        //  返回配置好的渲染
        return render;
    }
    //  否则返回nil
    return nil;
}


@end

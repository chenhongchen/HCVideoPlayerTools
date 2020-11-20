//
//  AppDelegate+VP.h
//  HCVideoPlayer
//
//  Created by chc on 2018/1/3.
//  Copyright © 2018年 chc. All rights reserved.
//

@interface UIResponder (VP)
+ (void)setPortraitOrientation;
+ (void)setOrientation:(UIInterfaceOrientation)orientation;
+ (void)setAllowRotation:(BOOL)allowRotation forRootPresentVc:(UIViewController *)rootPresentVc;
/// 播放时是否使用app的-application:supportedInterfaceOrientationsForWindow:方法（NO为使用app的，YES为使用该框架的）
+ (void)setUseAppRotationMethod:(BOOL)isUse;
@end

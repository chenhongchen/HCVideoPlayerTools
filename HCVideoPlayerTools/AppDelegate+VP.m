//
//  AppDelegate+VP.m
//  HCVideoPlayer
//
//  Created by chc on 2018/1/3.
//  Copyright © 2018年 chc. All rights reserved.
//

#import "AppDelegate+VP.h"
#import <objc/runtime.h>

BOOL g_allowRotation;
UIInterfaceOrientationMask g_allowRotationOrientationMask;
UIInterfaceOrientationMask g_orginOrientationMask;
BOOL g_hasConfigRootVc;
@implementation UIResponder (VP)

+ (void)initialize
{
    if (self != objc_getClass([@"AppDelegate" UTF8String])) {
        return;
    }
    
    SEL method = @selector(application:supportedInterfaceOrientationsForWindow:);
    if (!class_addMethod([self class], method, (IMP)application_supportedInterfaceOrientationsForWindow, "I@:@c")) { // 创建失败则表示已存在该方法，则采用交换方法的方式
        Class class = objc_getClass([@"AppDelegate" UTF8String]);
        SEL method = @selector(application:supportedInterfaceOrientationsForWindow:);
        SEL newMethod = @selector(applicationNew:supportedInterfaceOrientationsForWindow:);
        Method originalMethod = class_getInstanceMethod(class, method);
        Method swizzledMethod = class_getInstanceMethod(class, newMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (UIInterfaceOrientationMask)applicationNew:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (g_allowRotation) {
        return g_allowRotationOrientationMask;
    }
    g_orginOrientationMask = [self applicationNew:application supportedInterfaceOrientationsForWindow:window];
    return g_orginOrientationMask;
}

u_long application_supportedInterfaceOrientationsForWindow(id self, SEL cmd, UIApplication *application, UIWindow *window)
{
    if (g_allowRotation) {
        return g_allowRotationOrientationMask;
    }
    g_orginOrientationMask =  [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:window];
    return g_orginOrientationMask;
}

+ (void)setPortraitOrientation
{
    [self setOrientation:UIInterfaceOrientationPortrait];
}

+ (void)setOrientation:(UIInterfaceOrientation)orientation
{
    //    if(ScreenWidth > ScreenHeight) {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val = orientation;
    // 从2开始是因为0 1 两个参数已经被selector和target占用
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
    //    }
}

#pragma mark - 配置根控制器旋转
+ (void)configRootVCOrientation
{
    if (g_hasConfigRootVc) {
        return;
    }
    Class class = [[self vp_rootWindow].rootViewController class];
    SEL method = @selector(preferredInterfaceOrientationForPresentation);
    if (!class_addMethod(class, method, (IMP)preferredInterfaceOrientationForPresentation, "I@:")) {
        SEL method = @selector(preferredInterfaceOrientationForPresentation);
        SEL newMethod = @selector(preferredInterfaceOrientationForPresentationNew);
        Method originalMethod = class_getInstanceMethod(class, method);
        Method swizzledMethod = class_getInstanceMethod(self, newMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    g_hasConfigRootVc = YES;
}

+ (void)configOrientationForRootPresentVc:(UIViewController *)rootPresentVc
{
    if (rootPresentVc == nil) {
        return;
    }
    if (rootPresentVc == [self vp_rootWindow].rootViewController) {
        return;
    }
    Class class = [rootPresentVc class];
    SEL method = @selector(preferredInterfaceOrientationForPresentation);
    if (!class_addMethod(class, method, (IMP)preferredInterfaceOrientationForPresentation, "I@:")) {
        SEL method = @selector(preferredInterfaceOrientationForPresentation);
        SEL newMethod = @selector(preferredInterfaceOrientationForPresentationNew);
        Method originalMethod = class_getInstanceMethod(class, method);
        Method swizzledMethod = class_getInstanceMethod(self, newMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentationNew {
    return UIInterfaceOrientationPortrait;
}

u_long preferredInterfaceOrientationForPresentation(id self, SEL cmd)
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - 外部方法
+ (void)setAllowRotation:(BOOL)allowRotation forRootPresentVc:(UIViewController *)rootPresentVc
{
    g_allowRotation = allowRotation;
    g_allowRotationOrientationMask = UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    if (allowRotation) {
        [self configRootVCOrientation];
        [self configOrientationForRootPresentVc:rootPresentVc];
    }
}

+ (void)setUseAppRotationMethod:(BOOL)isUse
{
    [self setUseAppRotationMethod:isUse allowRotationOrientationMask:UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight];
}

+ (void)setUseAppRotationMethod:(BOOL)isUse allowRotationOrientationMask:(UIInterfaceOrientationMask)allowRotationOrientationMask
{
    g_allowRotation = isUse;
    if (isUse == true) {
        g_allowRotationOrientationMask = allowRotationOrientationMask;
    }
    else {
        UIInterfaceOrientation curOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (g_orginOrientationMask == UIInterfaceOrientationMaskPortrait) {
            [self setOrientation:UIInterfaceOrientationPortrait];
        }
        if (g_orginOrientationMask == UIInterfaceOrientationMaskLandscapeLeft) {
            [self setOrientation:UIInterfaceOrientationLandscapeLeft];
        }
        else if(g_orginOrientationMask == UIInterfaceOrientationMaskLandscapeRight) {
            [self setOrientation:UIInterfaceOrientationLandscapeRight];
        }
        else if (g_orginOrientationMask == UIInterfaceOrientationMaskPortraitUpsideDown){
            [self setOrientation:UIInterfaceOrientationPortraitUpsideDown];
        }
        else if(g_orginOrientationMask == UIInterfaceOrientationMaskLandscape) {
            if (curOrientation == UIInterfaceOrientationUnknown || curOrientation == UIInterfaceOrientationPortrait || curOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
                [self setOrientation:UIInterfaceOrientationLandscapeLeft];
            }
        }
        else if (g_orginOrientationMask == UIInterfaceOrientationMaskAll) {
        }
        else if (g_orginOrientationMask == UIInterfaceOrientationMaskAllButUpsideDown) {
            if (curOrientation == UIInterfaceOrientationUnknown || curOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
                [self setOrientation:UIInterfaceOrientationPortrait];
            }
        }
    }
}

+ (UIWindow *)vp_rootWindow
{
    if (@available(iOS 13.0, *))
    {
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive)
            {
                return windowScene.windows.firstObject;
                break;
            }
        }
    }
    else
    {
        return [UIApplication sharedApplication].keyWindow;
    }
    return nil;
}

@end

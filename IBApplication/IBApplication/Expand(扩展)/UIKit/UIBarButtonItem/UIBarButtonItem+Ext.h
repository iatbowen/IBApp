//
//  UIBarButtonItem+Ext.h
//  IBApplication
//
//  Created by Bowen on 2018/6/23.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (Ext)

/**
 *  设置图片按钮,normal:常规图片，highlighted:高亮图片
 */
- (id)initWithNormalIcon:(NSString *)normal highlightedIcon:(NSString *)highlighted target:(id)target action:(SEL)action;
+ (id)itemWithNormalIcon:(NSString *)normal highlightedIcon:(NSString *)highlighted target:(id)target action:(SEL)action;

/**
 *  设置文字按钮, 不带背景图片，默认文字颜色：NormalColor 高亮颜色：HighlightedColor
 */
- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (id)itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;

/**
 *  设置文字按钮, backgroundImage:背景图片，normal：常规颜色 Highlighted：高亮颜色
 */
- (id)initWithTitle:(NSString *)title backgroundImage:(UIImage *)backImage target:(id)target action:(SEL)action;
+ (id)itemWithTitle:(NSString *)title backgroundImage:(UIImage *)backImage target:(id)target action:(SEL)action;

/**
 *  设置文字按钮，不带背景图片， normal：常规颜色 Highlighted：高亮颜色
 */
+ (id)itemWithTitle:(NSString *)title normalColor:(UIColor *)normal highlightedColor:(UIColor *)highlighted target:(id)target action:(SEL)action;
- (id)initWithTitle:(NSString *)title normalColor:(UIColor *)normal highlightedColor:(UIColor *)highlighted target:(id)target action:(SEL)action;

/**
 *  设置文字按钮，backgroundImage:背景图片 normal：常规颜色 Highlighted：高亮颜色
 */
+ (id)itemWithTitle:(NSString *)title backgroundImage:(UIImage *)backImage normalColor:(UIColor *)normal highlightedColor:(UIColor *)highlighted target:(id)target action:(SEL)action;
- (id)initWithTitle:(NSString *)title backgroundImage:(UIImage *)backImage normalColor:(UIColor *)normal highlightedColor:(UIColor *)highlighted target:(id)target action:(SEL)action;



@end

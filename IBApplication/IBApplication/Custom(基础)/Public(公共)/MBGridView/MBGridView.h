//
//   MBGridView.h
//  IBApplication
//
//  Created by Bowen on 2020/3/19.
//  Copyright © 2020 BowenCoder. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
*  用于做九宫格布局，会将内部所有的 subview 根据指定的列数和行高，把每个 item（也即 subview） 拉伸到相同的大小。
*
*  支持在 item 和 item 之间显示分隔线，分隔线支持虚线。
*
*  @warning 注意分隔线是占位的，把 item 隔开，而不是盖在某个 item 上。
*/
@interface MBGridView : UIView

/// 指定要显示的列数，默认为 0
@property(nonatomic, assign) IBInspectable NSInteger columnCount;

/// 指定每一行的高度，默认为 0
@property(nonatomic, assign) IBInspectable CGFloat rowHeight;

/// 指定 item 之间的分隔线宽度，默认为 0
@property(nonatomic, assign) IBInspectable CGFloat separatorWidth;

/// 指定 item 之间的分隔线颜色，默认为 lightGrayColor
@property(nonatomic, strong) IBInspectable UIColor *separatorColor;

/// item 之间的分隔线是否要用虚线显示，默认为 NO
@property(nonatomic, assign) IBInspectable BOOL separatorDashed;

/// 候选的初始化方法，亦可通过 initWithFrame:、init 来初始化。
- (instancetype)initWithColumn:(NSInteger)column rowHeight:(CGFloat)rowHeight;

@end

NS_ASSUME_NONNULL_END

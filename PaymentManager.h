//
//  PaymentUtil.h
//  com.wuheyou.test
//
//  Created by  on 15/9/15.
//  Copyright (c) 2015年 wuheyou. All rights reserved.
//
/**
*  支付接口,支持ios6 以上
*
*  @sample
 #import "PaymentManager.h"
 
 [[PaymentManager sharePayment] paymentOfGId:id stateBlack:^(WHYPaymentTransactionState state) {
         switch (state) {
         case WHYPaymentTransactionStatePurchasing:
         
         break;
         case WHYPaymentTransactionStatePurchased:
         
         break;
         case WHYPaymentTransactionStateFailed:
         
         break;
         case WHYPaymentTransactionStateRestored:
         
         break;
         case WHYPaymentTransactionStateDeferred:
         
         break;
         default:
         break;
         }
         
         }];
*
*
*/
#import <StoreKit/StoreKit.h>
#import <Foundation/Foundation.h>
#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
typedef NS_ENUM(NSInteger, WHYPaymentTransactionState) {
    WHYPaymentTransactionStatePurchasing,    // 商品添加进列表 Transaction is being added to the server queue.
    WHYPaymentTransactionStatePurchased,     // 成功 Transaction is in queue, user has been charged.  Client should complete the transaction.
    WHYPaymentTransactionStateFailed,        // 失败 Transaction was cancelled or failed before being added to the server queue.
    WHYPaymentTransactionStateRestored,      // 恢复 Transaction was restored from user's purchase history.  Client should complete the transaction.
    WHYPaymentTransactionStateDeferred   // 等待外部动作 没出现过 The transaction is in the queue, but its final status is pending external action.
};
typedef void(^stateBlack)(WHYPaymentTransactionState state);

@interface PaymentManager : NSObject<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property(nonatomic)WHYPaymentTransactionState state;
@property(nonatomic,strong)NSString *gid;
@property(nonatomic,copy)stateBlack stateblock;
+(instancetype)sharePayment;
-(void)paymentOfGId:(NSString*)gid stateBlack:(stateBlack)stateblock;
@end

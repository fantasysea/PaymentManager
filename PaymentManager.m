//
//  PaymentUtil.m
//  com.wuheyou.test
//
//  Created by  on 15/9/15.
//  Copyright (c) 2015年 wuheyou. All rights reserved.
//

#import "PaymentManager.h"

@implementation PaymentManager
+(instancetype)sharePayment{
    static PaymentManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[PaymentManager alloc] init];
    });
    return _sharedManager;
}
-(void)paymentOfGId:(NSString*)gid stateBlack:(stateBlack)stateblock{
    
    if (!gid) {
        NSLog(@"id 不能为nil");
        return;
    }
    if (!stateblock) {
        NSLog(@"block 不能为nil");
        return;
    }
    self.gid = gid;
    self.stateblock = stateblock;
    
    [self purchaseFunc:gid];
}

#pragma mark - 支付流程
/**
 支付流程
 
 通过id（唯一字符串，在itunes）发起获取商品的详情
 NSSet *nsset = [NSSet setWithArray:product];
 SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
 ｜
 ｜
 ｜
 vv
 获取详情后ios会以匹配到的数据用array返回
 NSArray *product = response.products;
 ｜
 ｜
 ｜
 vv
 通过开始的申请的id筛选出购买的商品对象
 if([pro.productIdentifier isEqualToString:self.productID.text]){
 p = pro;
 }
 ｜
 ｜
 ｜
 vv
 通过商品对象组装成购买对象然后发起购买申请
 SKPayment *payment = [SKPayment paymentWithProduct:p];
 NSLog(@"发送购买请求");
 [[SKPaymentQueue defaultQueue] addPayment:payment];
 ｜
 ｜
 ｜
 vv
 购买的时候ios会自动弹窗发起购买，输入账号等等
 ｜
 ｜
 ｜
 vv
 购买流程走完后会调用delegete，返回购买的结果
 ｜
 ｜
 ｜
 vv
 对不同对结果进行处理，成功需要进行服务器验证
 - (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
 for(SKPaymentTransaction *tran in transaction){
 
 switch (tran.transactionState) {
 
 case SKPaymentTransactionStatePurchased:
 NSLog(@"购买完成 %@", tran.payment.productIdentifier);
 
 case SKPaymentTransactionStatePurchasing:
 
 
 case SKPaymentTransactionStateRestored:
 
 case SKPaymentTransactionStateFailed:
 NSLog(@"交易失败");
 
 ｜
 ｜
 ｜
 vv
 验证成功才算购买成功
 NSURL *url = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
 
 **/
- (void)purchaseFunc:(NSString*)gid {
    if([SKPaymentQueue canMakePayments]){
        [self requestProductData:gid];
    }else{
        NSLog(@"不允许程序内付费");
    }
}

//请求商品
- (void)requestProductData:(NSString *)gid{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    NSLog(@"-------------请求对应的产品信息----------------");
    NSArray *product = [[NSArray alloc] initWithObjects:gid, nil];
    NSSet *nsset = [NSSet setWithArray:product];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
    
}

//收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    
    NSLog(@"--------------收到产品反馈消息---------------------");
    NSArray *product = response.products;
    if([product count] == 0){
        NSLog(@"--------------没有商品------------------");
        return;
    }
    
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    
    SKProduct *p = nil;
    for (SKProduct *pro in product) {
        NSLog(@"%@", [pro description]);
        NSLog(@"%@", [pro localizedTitle]);
        NSLog(@"%@", [pro localizedDescription]);
        NSLog(@"%@", [pro price]);
        NSLog(@"%@", [pro productIdentifier]);
        
        if([pro.productIdentifier isEqualToString:self.gid]){
            p = pro;
        }
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    
    NSLog(@"发送购买请求");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"------------------错误-----------------:%@", error);
    self.stateblock(WHYPaymentTransactionStateFailed);
}

- (void)requestDidFinish:(SKRequest *)request{
    NSLog(@"------------反馈信息结束-----------------");
    
}


//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
    for(SKPaymentTransaction *tran in transaction){
        
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"购买完成 %@", tran.payment.productIdentifier);
                
                // 更新界面或者数据，把用户购买得商品交给用户
                // ...
                // 验证购买凭据
                [self verifyPruchase:tran];
                
                // 将交易从交易队列中删除
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                self.stateblock(WHYPaymentTransactionStatePurchasing);
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"恢复成功 %@", tran.payment.productIdentifier);
                self.stateblock(WHYPaymentTransactionStateRestored);
                // 更新界面或者数据，把用户购买得商品交给用户,主要是针对已经购买过该商品，然后就会一直拥有的商品。
                // ...
                
                // 将交易从交易队列中删除
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                self.stateblock(WHYPaymentTransactionStateFailed);
                // 将交易从交易队列中删除
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"等待外部动作");
                
                break;
            default:
                break;
        }
    }
}

//交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"交易结束");
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark 验证购买凭据
- (void)verifyPruchase:(SKPaymentTransaction *)transaction
{
    // 验证凭据，获取到苹果返回的交易凭据
    
    NSString *encodeStr;
    if (!IS_IOS7) {
        NSData *receiptData = transaction.transactionReceipt;
//        encodeStr  = [[NSString alloc] initWithData:receiptData encoding:NSUTF8StringEncoding];
//        NSLog(@"encodeStr is %@",receiptData);
        encodeStr = [self encode:(uint8_t *)receiptData.bytes length:receiptData.length];
        NSLog(@"encodeStr is %@",receiptData);
    }else{
        // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        // 从沙盒中获取到购买凭据
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        //获得的返回数据类型不一样，要分开处理来获取到 encodeStr
        encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        
    }

    // 发送网络POST请求，对购买凭据进行验证
    NSURL *url = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    // 国内访问苹果服务器比较慢，timeoutInterval需要长一点
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
    
    request.HTTPMethod = @"POST";
    
    // 在网络中传输数据，大多情况下是传输的字符串而不是二进制数据
    // 传输的是BASE64编码的字符串
    /**
     BASE64 常用的编码方案，通常用于数据传输，以及加密算法的基础算法，传输过程中能够保证数据传输的稳定性
     BASE64是可以编码和解码的
     */
    
    // 在app上做验证, 仅用于测试 下面这段获取NSData 也可以
//     NSError *jsonError = nil;
//    NSDictionary *info = [NSDictionary dictionaryWithObject:encodeStr forKey:@"receipt-data"];
//    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&jsonError];
    
    
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"payload is %@",payload);
    request.HTTPBody = payloadData;
    
    // 提交验证请求，并获得官方的验证JSON结果
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    // 官方验证结果为空
    if (result == nil) {
        NSLog(@"验证失败");
        return;
    }
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
    
    NSLog(@"%@", dict);
    
    if (dict != nil) {
        // 比对字典中以下信息基本上可以保证数据安全
        // bundle_id&application_version&product_id&transaction_id
        NSLog(@"验证成功");
        self.stateblock(WHYPaymentTransactionStatePurchased);
    }
}
- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@end

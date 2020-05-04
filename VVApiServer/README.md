#  VVAPIServer

//socket成功连接到才会服务器调用
 -(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;

//接受到新的socket连接才会调用
 - (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;

//读取数据，有数据就会调用
 - (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag;

//直到读到这个长度的数据，才会触发代理
 - (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag; 

//直到读到data这个边界，才会触发代理 
 - (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;

//有socket断开连接调用
 - (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;

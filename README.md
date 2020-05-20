### 起源
在开发中常常遇到以下几个问题。
1. 对接完产品需求和技术文档，客户端不能立即进入开发调试状态，时常等待后端接口，可能导致进入加班状态或则拖延开发周期。
2. 开发中网络不稳定，或者服务器重启次数过多
3. 开发过程中想调用服务器某个接口，返回某个字段的特殊值或者整个结构改变进行调试。
4. 写本地的Unit Test

正是由于上面的问题，我一直想自己写一个本地服务器且又能兼容远程服务器的组件。在iOS中网上已经有开源的[CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer),在前人的基础上进行二次修改出来了[VVApiServer](https://github.com/chinaxxren/VVApiServer)。
### 原理

![](https://user-gold-cdn.xitu.io/2020/5/9/171f8aae6c565792?w=1582&h=432&f=png&s=95521)
> 拦截匹配Path的客户端发起的请求，转化为都是请求VVApiServer的本地请求。VVApiServer得到请求的host和vv_api_delay两个参数，决定是否由VVApiServer发起第二次真实请求。等返回结果再处理或则直接返回本地自定义结果。

### 使用介绍
1. VVApiServer通过请求参数来控制访问方式
> 当请求参数中加入`vv_api_delay`表示对此请求进行拦截返回自定结果。如果不加则和以前一样。

* `vv_api_delay`如果值为`-1`则表示拦截不是当前VVApiServer请求，可返回自定义结果响应。
* `vv_api_delay`如果值为`0`则表示请求当前VVApiServer，访问自定义结果。
* `vv_api_delay`如果值为`大于零`则表示访问当前VVApiServer根据`vv_api_delay`的值相应延时，返回自定结果。

2. VVApiServer通过Path匹配自定义返回结果，本地和远程都一样。

> 本地和远程都是通过相同的Path匹配，返回自定义结果，以此省去不要的切换。

######  // 自定义json字符串结果
``` oc
    [httpServer get:@"/test" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSDictionary *dict = @{@"result": @"test", @"msg": @"success", @"code": @(0)};
        [response respondWithString:[dict toJSONString]];
    }];
```    
######  // 自定义视频文件结果
``` oc
    [httpServer get:@"/video/sync.mp4" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
        [response respondWithFile:jsonPath async:NO];
    }];
 ```   
###### // 自定义Json文件结果，动态修改本地Json返回最新结果值
``` oc
    [httpServer get:@"/local/news" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"news" ofType:@"json"];
        NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil];
        [response respondWithString:jsonString];
    }];
```
######  // 当服务端没有返回调用本地自定义结果，有则返回服务器结果。用于服务器接口尚未开发完成，先返回本地自定义结果，进行正常客户端。
``` oc
    [httpServer post:@"/getWangYiNews" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        if (response.responseObject) {
            [response respondWithString:[response.responseObject toJSONString]];
        } else {
            NSDictionary *dict = @{@"result": @"getWangYiNews", @"msg": @"success", @"code": @(0)};
            [response respondWithString:[dict toJSONString]];
        }
    }];
 ```   
###### // 支持自定义错误返回。
``` oc
    [httpServer get:@"/httperror" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response setStatusCode:405];
        [response setHeader:@"Content-Type" value:@"text/html"];
        [response respondWithString:@"<h1>404 File Not Found</h1>"];
    }];
  ```  
######  // 支持多种的Path模式匹配方式
``` oc
    [httpServer post:@"/users/:name/:action" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/users/%@/%@",
                                                               [request param:@"name"],
                                                               [request param:@"action"]]];
    }];
    
    [httpServer get:@"{^/page/(\\d+)$}" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        [response respondWithString:[NSString stringWithFormat:@"/page/%@",
                                                               [[request param:@"captures"] objectAtIndex:0]]];
    }];

    [httpServer get:@"/files/*.*" withHandler:^(VVApiRequest *request, VVApiResponse *response) {
        NSArray *wildcards = [request param:@"wildcards"];
        [response respondWithString:[NSString stringWithFormat:@"/files/%@.%@",
                                                               wildcards[0],
                                                               wildcards[1]]];
    }];
    
```
### 代码例子

[VVApiServer](https://github.com/chinaxxren/VVApiServer)

### 未完功能

不支持websocket。
不支持远程下载（开发中）

### 感谢
[CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer)

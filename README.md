# VVApiServer

* 在开发中，当服务器端不能访问、按需求提供Api接口访问结果的时候，我们可以通过VVApiServer在本地生成需要访问Api接口的结果，当远程服务器能正常访问后，无缝的切换到远程服务器方式。

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

### 未完功能
* 不支持websocket。
* 不支持远程下载（开发中）

### 感谢
[CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer)

# DACA架构客户端框架规范

本文以前端H5应用为例，使用Javascript语言给出示例，假定函数的命名空间为Daca。
如果使用其它编程语言实现DACA架构客户端，应实现类似功能或函数。

## 调用服务接口

为调用DACA服务接口，客户端应用框架应支持以下函数：

### 生成接口URL - makeUrl

	Daca.makeUrl(action, params)

生成对后端接口服务调用的url. 示例：

	var params = {id: 100};
	var url = Daca.makeUrl("Ordr.set", params);
	// url="http://myserver/myapp/api/Ordr.set?id=100"

### 调用接口 - callSvr

异步调用接口：

	Daca.callSvr(ac, params?, fn?, postParams?, userOptions?) -> deferredObject
	或省略params:
	Daca.callSvr(ac, fn?, postParams?, userOptions?) -> deferredObject

同步调用接口：

	Daca.callSvrSync(ac, params?, fn?, postParams?, userOptions?) -> retData
	或省略params:
	Daca.callSvrSync(ac, fn?, postParams?, userOptions?) -> retData

- ac: String. 接口名(action), 也可以是URL。
- params: Object. 接口请求参数，一般指URL参数（或称HTTP GET参数）
- fn: Function(retData). 回调函数, retData参考该接口原型中的返回值定义。
- postParams: Object. 接口请求数据，一般指HTTP POST内容。如果有该参数, 则自动使用HTTP POST请求，而默认使用HTTP GET请求。
- userOptions: Object. 定制参数。

常用userOptions: 

- 指定{async:0}来做同步请求, 一般直接用callSvrSync调用来替代.
- 指定{noex:1}用于忽略错误处理。
- 指定{noLoadingImg:1}用于忽略loading图标.

异步调用建议返回deferred对象，可通过它操作返回数据。示例：

	var dfd = Daca.callSvr(ac, fn1);
	dfd.then(fn2);

	function fn1(data) {}
	function fn2(data) {}

在接口调用成功后，会依次回调fn1, fn2.

注意：默认回调函数只会在接口调用成功时回调，而调用出错交给框架来统一处理，如框架应负责弹出错误提示框，或当返回“未登录错”时自动跳转登录页。

除非在userOptions中指定{noex:1}，这时一旦调用出错，框架应回调`fn(false)`（参数retData=false）, 并可通过 this.lastError 取到返回的原始数据。

示例：

	Daca.callSvr("logout");
	Daca.callSvr("logout", api_logout);
	function api_logout(data) {}

	Daca.callSvr("login", {wantAll:1}, api_login);
	function api_login(data) {}

	Daca.callSvr("info/hotline.php", {q: '大众'}, api_hotline);
	function api_hotline(data) {}

	Daca.callSvr("User.get", function (data) {
		if (data === false) { // 仅当设置noex且服务端返回错误时可返回false
			// var originalData = this.lastError;
			return;
		}
		foo(data);
	}, null, {noex:1});

注意：

- 请求时，应自动添加应用标识参数。（参考`应用标识/appName`）

### 压缩表处理

将服务端对象查询返回的压缩表格式(也称为RowSet/rs)转成对象数组。

	rs2Array(rs) -> [ %obj ]
	rs2Hash(rs, key) -> {key => %obj}
	rs2MultiHash(rs) -> {key => [%obj] }

参数

- rs: {@h, @d}, h和d分别表示标题行和数据行。

示例：

	var rs = {
		h: ["id", "name"], 
		d: [ [100, "Tom"], [101, "Jane"], [102, "Tom"] ] 
	};
	var arr = rs2Array(rs); 
	var hash = rs2Hash(rs, "id"); 
	var hash2 = rs2MultiHash(rs, "name"); 

	// 结果为
	arr = [
		{id: 100, name: "Tom"},
		{id: 101, name: "Jane"} 
		{id: 102, name: "Tom"} 
	];

	hash = {
		100: {id: 100, name: "Tom"},
		101: {id: 101, name: "Jane"} 
		102: {id: 102, name: "Tom"} 
	};

	hash2 = {
		"Tom": [ {id: 100, name: "Tom"}, {id: 102, name: "Tom"} ]
		"Jane": [ {id: 101, name: "Jane"} ]
	};
	
示例：rs2Hash
## 批请求

客户端可实现批请求，在一次请求中包含多条接口调用。
并且支持后面的调用引用前面调用的返回值，并且支持事务，一起成功提交或失败回滚。

前端实现示例：

	var batch = new Daca.batchCall();
	// var batch = new Daca.batchCall({useTrans: 1}); // 指定使用事务

	// 调用一
	var param = {res: "id,name,phone"};
	Daca.callSvr("User.get", param, function(data) {} )

	// 调用二，其中参数userId使用了前向引用，必须在ref参数中指明。
	var postParam = {page: "home", ver: "android", userId: "{$1.id}"};
	Daca.callSvr("ActionLog.add", function(data) {}, postParam, {ref: ["userId"]} );

	batch.commit(); // 发起批请求
	// batch.cancel(); // 取消批请求

对批请求的实现应对使用callSvr函数透明，即在调用new batchCall到batchCall.commit/cancel之间的callSvr调用可自动加入批请求。

客户端框架还可支持这种更简单的方式：

	Daca.useBatchCall(); // 在本次消息循环中执行的所有callSvr都加入批处理。
	// Daca.useBatchCall({useTrans:1}); // 启用事务的写法。
	// Daca.useBatchCall({useTrans:1}, 20); // 表示20ms内所有callSvr都加入批处理, 且启用事务。
	Daca.callSvr(...);
	Daca.callSvr(...);

上面示例的调用二中参数userId引用了调用一的返回结果，通过在callSvr后指定参数userOptions.ref标明。userId的值"{$1.id}"表示取第一次调用值的id属性。
注意：引用表达式应以"{}"包起来，"$n"中n可以为正数或负数（但不能为0），表示对第n次或前n次调用结果的引用，以下为可能的格式：

	"{$1}"
	"id={$1.id}"
	"{$-1.d[0][0]}"
	"id in ({$1}, {$2})"
	"diff={$-2 - $-1}"

花括号中的内容将用计算后的结果替换。如果表达式非法，将使用"null"值替代。

## 对象列表与详情设计模式

根据服务器通用对象接口，客户端框架可提供列表页与详情页的支持。

- 列表页应支持通用的对象列表分页、刷新、查询过滤、排序、删除、选中对象后关联详情页等需求；
- 详情页一般支持添加、更新、显示对象多功能和一，同时可做列表查询条件设置。

## 其它

**[测试模式提醒]**

如果服务运行于测试模式，或中间切换到测试模式，应予以提醒。（参考`X-Daca-Test-Mode`）

**[自动热更新]**

假如某前端H5应用（或以H5应用为内核的手机原生应用）操作期间，后端接口服务刚好升级过，应用程序再请求时，可以依据版本号变更发现升级行为，从而自动刷新到新版本。
（参考`X-Daca-Server-Rev`）


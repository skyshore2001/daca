% BQP - 业务查询协议

业务查询协议，简称BQP(Business Query Protocol)，定义业务接口设计规范及如何形式化描述业务接口，客户端怎样请求服务端业务逻辑，以及服务端如何返回业务数据。

在定义业务接口时，应使用形式化方式描述接口。
这些描述也可以作为元数据（metadata）由服务端返回客户端。

# 基本原则

## 通讯协议

客户端通过HTTP协议与服务端交互，调用服务端接口。
接口请求一般使用HTTP GET或POST方法，通过URL或POST内容传递参数，参数使用urlencoded编码方式，即`p1=value1&p2=value2`的形式；
接口返回内容使用JSON格式。以上传输中，参数或属性值使用UTF-8编码。

每个接口均应在接口文档中规范描述，比如接口描述：

	fn(p1, p2) -> {field1, field2}

其中`fn`为接口名，`p1`, `p2`是两个参数，`->`后面部分是调用成功时的返回值，使用扩展的[蚕茧表示法](https://github.com/skyshore2001/cocoon-notation)描述，详见下文。
如果没有箭头后面部分，表示没有返回值，默认返回字符串"OK".

以下假定接口调用地址为"/api.php"，该调用可以用HTTP GET请求(通过URL传参)实现如下: 

	GET /api.php/fn?p1=value1&p2=value2

或用POST请求实现:

	POST /api.php/fn
	Content-Type: application/x-www-form-urlencoded

	p2=value2&p1=value1

如果在实现时，服务端很难支持在URL最后包含调用名，也可以使用如下形式的等价访问：

	GET /api.php?ac=fn&p1=value1&p2=value2

协议规定，请求地址中的最后一段为接口名(如`api.php/fn`中的`fn`)，或用URL参数`ac`或`_ac`标识接口名, 但必须使用URL参数传递。其它参数未加说明的, 可以选择通过URL或POST传参. 

接口名使用驼峰式命名规则，一般有两种形式，1）函数调用型，以小写字母开头，如`getOrder`；2）对象调用型，对象名首字母为大写，后跟调用名，中间以"."分隔，如`Order.get`。

注意在用HTTP POST时默认HTTP头Content-Type需要按上例中正确设置, 少数例外情况应特别指出，比如上传文件接口upload设计为使用HTTP头"Content-type: multipart/form-data"，应在接口文档中明确说明。

有时在描述接口时使用两个括号，如：

	fn(p1)(p2,p3) -> {field1, field2}
	
它表示后一个括号中的参数表示必须通过POST传参, 而前一个括号的参数必须用URL传参数, 像这样:

	POST /api.php?ac=fn&p1=value1
	Content-Type: application/x-www-form-urlencoded

	p2=value2&p3=value3

协议规定：

- 只要服务端正确收到请求并处理，均返回HTTP Code 200，返回内容使用JSON格式，为一个至少含有2元素的数组。
 - 在请求成功时返回内容格式为 `[0, data]`，其中`data`的类型由接口描述定义。
 - 在请求失败时返回内容格式为 `[非0错误码, 错误信息]`.
 - 从返回数组的第3个元素起, 为调试信息, 仅用于问题诊断, 一般不应显示出来给最终用户。
- 所有交互内容采用UTF-8编码。

服务端在返回JSON格式数据时应如下设置HTTP头属性：

	Content-Type: text/plain; charset=UTF-8

注意：不采用"application/json"类型是考虑客户端可以更自由的处理返回结果（比如jQuery等库会自动将json类型的返回值转成对象）。

服务端应避免客户端对返回结果缓冲，一般应在HTTP响应中加上

		Cache-Control: no-cache

以下面的接口描述为例：

	（根据id取车型信息：）
	getModel(id) -> {id, name, dscr}

在实现时应明确：

- 接口名称是`getModel`，参数为`id`，对应的HTTP请求URL为 `GET /api.php/getModel?id=100`，该调用可描述为`getModel(id=100)`.

- 服务端处理成功时返回类型为`{id, name, dscr}`，关于返回类型表述方式详见下节描述。完整的返回内容为

		HTTP/1.1 200 OK

		[0, {id: 100, name: "myname", dscr:"mydscr"}]

	以上返回可直接描述为返回`{id: 100, name: "myname", dscr:"mydscr"}`。

- 服务端处理失败时返回信息如

		HTTP/1.1 200 OK

		[1, "未认证"]

	错误码及错误信息在应用中应明确定义，且前后端共享一致，如（以后端php实现为例）：

		// 错误码定义

		const E_OK=0;
		const E_PARAM=1;
		const E_AUTH=2;
		const E_DB=3;
		const E_SERVER=4;
		const E_FORBIDDEN=5;

		$ERRINFO = [
			E_PARAM => "参数不正确",
			E_AUTH => "未认证",
			E_DB => "数据库错误",
			E_SERVER => "服务器错误",
			E_FORBIDDEN => "禁止操作"
		];

## 关于空值

假如有参数`a=1&b=&c=hello`, 其中参数"b"值为空串。
一般情况下，参数"b"没有意义，即与`a=1&c=hello`意义相同。

在某些场合，如对象保存操作`{object}.set`，在POST内容中如果出现"b=", 则表示将该字段置null，相当于"b=null". 在这些场合下将单独说明。

## 使用PATH_INFO模式的URL

在后端编程语言支持的情况下，尽量通过设定路由规则，让URL更可读。例如，接口调用

	https://server/product/api.php?ac=login&phone=137&pwd=1234

等价于

	https://server/product/api.php/login?phone=137&pwd=1234

由于后者可读性更强，尽量提供后一种访问方式。
对于对象操作型接口，URL像这样：

	http://server/product/api.php?ac=Ordr.query&res=id,dscr

它等价于以下更好的方式：

	http://server/product/api.php/Ordr.query?res=id,dscr

即"Ordr/query"转化为"ac=Ordr.query".

## 应用标识

每个客户端应用应该有唯一应用标识（如果没有，缺省为"user"，表示客户端应用），以URL参数"_app"指定。
在每次接口请求时，客户端框架应自动添加该参数。

应用标识对应一个应用类型，如应用标识"user", "user2", "user-keyacct"对应同一应用类型"user". 即应用标识的第一个词（不含结尾数字）作为应用类型。

应用类型决定了HTTP会话中的cookie项的名字（由服务端实现）：

	cookie名={应用类型}id

或对于[测试模式][]下, 

	cookie名=t{应用类型}id

例如，应用标识为"emp"(表示员工端), 当第一次接口请求时：

	GET /api.php/fn?_app=emp

服务端应通过HTTP头指定会话标识，如：

	SetCookie: empid=xxxxxx

对于相同应用类型的应用，它们可以共享会话（如一个应用已登录，同一浏览器中其它同类型应用可免登录）。
在设计多个客户端的应用标识时，应根据这一特点决定是否使用相同应用类型。

规范定义以下应用类型，具体应用可在此基础上增加：

- user: 客户端应用
- emp: 员工端应用，如处理客户订单等。
- admin: 超级管理端应用。

## 测试模式

URL参数"_test"值为非0时表示测试模式。特别地，当_test值为2时，表示回归测试模式（用于自动化测试）。

应用可以支持测试模式(TEST_MODE)，在该模式下：

- 如果在线上，后端必须连接非生产数据库。
- 前端必须明显标明当前处理测试模式下，一般在进入时弹框提醒。
- 部分接口仅在测试模式下才有权限调用，如用于回归测试的接口。

## 调试等级

URL参数"_debug"定义调试等级, 默认为0. 如果为1-9的数字, 将添加调试信息到结果数组中.

调试等级仅在测试模式下有效。

当设置_debug=9时，应可输出所有SQL语句。

## 数据传输安全

服务端应支持HTTPS服务。对于传输敏感数据的接口，客户端应使用HTTPS协议与服务器通信，如涉及用户隐私信息（用户密码，电话，地址，卡号等）。

注意：服务器很可能采用自签证书，且证书中CN名称(CommonName字段)与网站实际名称可能不符.
这种情况下一般的SSL库在连接时会验证服务端证书并报错，客户端应设置连接选择忽略这些错误。例如，使用CURL库做接口请求时，可设置：

	# for https, ignore cert errors (e.g. for self-signed cert)
	curl_setopt($h, CURLOPT_SSL_VERIFYPEER, false);
	curl_setopt($h, CURLOPT_SSL_VERIFYHOST, 0);

# 形式化接口描述

接口描述应让人明确接口原型，参数（或返回属性）类型和含义，以及权限说明，如：
	
	根据id取车型信息
	getModel(id) -> {id, name, dscr}

	id:: Integer. 车款编号.
	name:: Integer. 车款名称.
	dscr:: Integer. 车款描述.

参数或返回值中的属性应明确数据类型，包括基本类型，复杂类型以及序列化类型。其中参数因为通过urlencoded格式传输，一般是基本类型或序列化类型（复杂字符串），而返回值由于采用JSON格式，一般是复杂类型。

本规范主要依据[蚕茧表示法](https://github.com/skyshore2001/cocoon-notation)来描述类型并做了一些扩展，详见下文论述。

参数应明确其类型及含义，如果参数含义明确则可省略；如果参数是基本类型且可根据参数名称推导出（依据"蚕茧法"）是整数、日期、字符串等，也可以省略参数类型描述。

上例中没有权限说明，这表明权限是 AUTH_GUEST (参考[接口权限][]节)

又比如一个含有复杂类型和序列化类型的例子：

	取订单
	Ordr.get(id) -> {id, status, storePos, @orderLog}
	
	权限：AUTH_USER

	返回：
	storePos:: Coord. 商户坐标.
	orderLog:: [{id, tm, ac, dscr}]. 订单日志。

	ac:: 操作类型: CR-创建,PA-已付款,CA-已取消,RE-已完成.

上例中，`id`, `status`等字段因含义明确可不做介绍，`storePos`是一个序列化类型（以字符串表示的复杂类型），表示`Coord`类型，特别标明。而`orderLog`是一个复杂结构，应以“蚕茧法”分解到基本类型属性，其中`id`, `tm`等属性因含义明确省略了介绍。

## 可选参数

如果API的参数表示为:

	fn(p1, p2?, p3?=1) -> {attr1, attr2?}

它表示：

- p1是必选参数
- p2,p3是可选参数，p3的缺省值是1，p2缺省值是0或空串""或null(取决于基本类型是数值型，字符串还是对象等)
- 返回一个对象，其中，attr1是必出现的属性，而attr2可能没有（接口说明中应描述何时没有）。

## 基本类型

基本类型指数值、字符串等不可再细分的类型。

在设计时，本规范依据“蚕茧表示法”思想，遵循以下命名规范，以便通过名称暗示类型。类型也可以通过后缀标识符标明，或在描述属性时标明。规则如下：

- Integer: 后缀标识符为"&", 或以"Id", "Cnt"等结尾, 如 customerId, age&
- Double: 后缀标识符为"#", 如 avgValue#
- Currency: 后缀标识符为"@", 或以"Price", "Total", "Qty", "Amount"结尾, 如 unitPrice, price2@。
- Datetime/Date/Time: 分别以"Tm"/"Dt"/"Time"结尾，如 tm 可表示日期时间如"2010-1-1 9:00"，comeDt 只表示日期如"2010-1-1"，而 comeTime只表示时间如"9:00"
- Boolean/TinyInt(1-byte): 以Flag结尾, 或以is开头.
- String: 未显示指明的一般都作为字符串类型。

## 复杂类型

复杂类型主要指对象、数组、字典这些常用结构，本规范主要使用"蚕茧表示法"描述，并扩展了如table等常用类型，举例列举如下：

*{id, name}*

一个简单对象，有两个字段id和name。例：`{id: 100, name: "name1"}`

*[id...] or [id]*

一个简单数组，元素为id。例：`[100, 200, 400]`, 每项为一个id

*[id, name]*

一个简单数组，例：`[100, "liang"]`，第一项为id,  第二项为name

*[ [id, name] ] 或 varr(id, name)*

简单二维数组，又称varr, 如 `[ [100, "liang"], [101, "wang"] ]`.

*[{id, name}] 或 objarr(id, name)*

一个数组，每项为一个对象，又称objarr。例：`[{id: 100, name: "name1"}, {id: 101, name: "name2"}]`

*tbl(id, name)*

table对象。其详细格式为 `{h: [header1, header2, ...], d:[row1, row2, ...]}`，例如

	{
	  h: ["id", "name"],
	  d: [[100, "myname1"], [200, "myname2"]]
	}

table对象支持分页机制(paging)，返回字段中包含"nextkey"等。
详情请参考下一章节"分页机制".

注意：

- 在使用JSON传输数据时，字段可以不区分类型，即使是整形也**可能**用引号括起来当作字符串传输，客户端在对JSON数据反序列化时应自行考虑类型转换。根据蚕茧表示法，属性的基本数据类型一般由属性名暗示，或在接口描述中显式约定。
- 不论哪种类型，都可能返回null。客户端必须能够处理null，将其转为相应类型正确的值。

## 序列化类型

序列化类型其实是一个字符串，但该字符串以特殊的结构来传输复杂类型，这称为序列化。
在本协议中，常用的序列化方式有：

- 逗号分隔的简单字符串序列(数组序列化)，如

		"经度,纬度"

	或带上类型描述：

		"经度/Double,纬度/Double"

	它可表示 `121.233543,31.345457`；
	特别地，本例中的这种类型又称为Coord类型，描述地理坐标，即

		Coord: "经度/Double,纬度/Double".

- List表，以逗号分隔行，以冒号分隔列的表，如定义：

		List(id, name?)

	或指定每列的类型，如

		List(id/Integer, name?/String)

	参数后加"?"表示是可选参数, 该项可以为空。
	它可以表示这样的数据：

		10:liang,11:wang
	
	因为name字段可省略，它也可以表示：

		10,11

	这种格式一般用于前后端间传递简单的表，尤其是一组数字。
	注意：由于使用分隔符","和":"，每个字段内不能有这两个特殊符号(例如假如有日期字段，中间不可以有":", 如"2015/11/20 1030"或"20151120 1030")。

	在传输数据时，也允许带表头信息，这时用首字符"@"标明表头行，如
	
		@id:name,10:liang,11:wang
		
- JSON序列化。将一个复杂结构以JSON格式序列化后的字符串，如定义：

		Json({id, name})
	
	括号内使用蚕茧法表示复杂数据结构。它可以表示这样格式的字符串：

		"{\"id\": 100, \"name\": \"liang\"}"
	
	又比如，要将一个普通的表用一个字段传递，可以描述为：

		Json(tbl(id, name))

- Table普通表。以换行符分隔行，以Tab字符分隔列，将整个表序列化为一个字符串作为一个字段传输，如

		Table(id,name,dscr?)
	
	可以表示数据

		"10 \t liang \n 11 \t wang \n" （注：为易于理解中间加了空格，实际传输时没有额外空格）
	
	与List结构相比，由于分隔符"\t"和"\n"不常用在字段内容中，故不易产生冲突。

## 接口权限

要访问每个接口，必须拥有相应的权限。或者，在权限不同时，调用同一接口返回的内容也可能不同。接口描述应包括权限描述。

通用权限定义如下：（具体应用可在此基础上增加）

- AUTH_GUEST: 任何人可用, 无权限限制。如不用登录即可查看商户, 天气等. 
- AUTH_USER: 用户登录后可用. 可做下单, 查看订单等操作. 
- AUTH_EMP: 员工操作，如查看和操作订单等。
- AUTH_TEST_MODE: 测试模式下可用。
- AUTH_MOCK_MODE: 模拟模式下可用。
- AUTH_ADMIN: 可操作一切对象. 但没有自动完成功能. 一般由程序内部使用, 或在专供超级管理员使用的超级管理端中应用。
- AUTH_PARTNER: 用于系统集成的权限验证。不用登录（相当于AUTH_GUEST），但调用每个接口时必须提供_pwd/_sign参数之一供验证，参考[合作伙伴接口设计][]章节。

如果接口未明确指定权限，则认为是AUTH_GUEST.

# 业务接口设计规范

业务接口包括函数调用型接口和对象调用型接口。

函数型接口名称一般为动词或动词开头，如queryOrder, getOrder等。对象型接口的格式为`{对象名}.{动作}`, 如 "Order.get", "Order.query"等。
对象型接口应支持以下标准动作：add, set, query, get, del。详细原型请参阅通用表操作一节。

参数id作为对象主键字段。一般建议在定义数据模型时：

- 一个数据库表对应一类对象或子对象。
- 每个表都有名为id的主键字段，作为对象的主键。

## 通用对象操作接口

以下接口完成对象的增删改查(CRUD)动作. 服务端实现时，应根据当前用户所拥有权限进行限制. 

在实现时，一般一个对象对应一张数据库主表，若干子表以及若干关联表。

	{object}.add()(POST fields...) -> id

	{object}.set(id)(POST fields...)

	{object}.get(id, res?) -> {fields...}

	{object}.del(id)

	{object}.query(res?, cond?, distinct?=0, _pagesz?=20, _pagekey?, _fmt?) -> tbl(field1,field2,...)

	{object}.query(wantArray=1, @subobj?, res?, ...) -> [{field1,field2,...}]


fields
: 每个字段及其值.

id
: Integer. 整型主键，不可修改.

注意:

- 对于add/set方法, 使用HTTP POST请求; fields表示表中每个字段的key-value值, 通过POST字段传递(使用URL编码). set方法中的id字段通过URL传递.
- 对于set操作, 如果要将某字段置空, 可以用空串或"null" (小写). 如"picId="或"picId=null"; 除了用在set操作的POST内容中，其它情况下字段设置为空串相当于没有设置该字段。
- 对于set操作，如果要将某字符串类型字段置空串(不建议使用)，可以用"empty", 如"sn=empty"。但如果对数值等其它类型设置，会导致其值为0或0.0。

### 对象查询

查询操作的参数可参照SQL语句来理解：

res
: String. 指定返回字段, 多个字段以逗号分隔，例如, res="field1,field2".

cond
: String. 指定查询条件，格式可参照SQL语句的"WHERE"子句。例如：cond="field1>100 AND field2='hello'", 注意使用UTF8+URL编码, 字符串值应加上单引号.

orderby
: String. 指定排序条件，格式可参照SQL语句的"ORDER BY"子句，例如：orderby="id desc"，也可以多个排序："tm desc,status" (按时间倒排，再按状态正排)

distinct
: Boolean. 如果为1, 生成"SELECT DISTINCT ..."查询.

尽管类似SQL语句，但对参数值有一些安全限制：

- res, orderby只能是字段（或虚拟字段）列表，不能出现函数、子查询等。
- cond可以由多个条件通过and或or组合而成，而每个条件的左边是字段名，右边是常量。不允许对字段运算，不允许子查询（不可以有select等关键字）。

用参数`cond`指定查询条件, 如：

	cond="type='A' and name like '%hello%'" 

URL编码后为

	cond=type%3d%27A%27+and+name+like+%27%25hello%25%27

以下情况都不允许：

	left(type, 1)='A'  -- 条件左边只能是字段，不允许计算或函数
	type=type2  -- 字段与字段比较不允许
	type in (select type from table2) -- 子表不允许

query返回有两种形式, 缺省返回table类型便于支持分页, 但不支持查询子对象(subobj参数). 如果指定参数`wantArray=1`, 可以返回子对象, 但则不支持分页. 例如, 
query缺省返回:

	{
		"h": ["id", "name"],
		"d": [[1, "liang"], [2, "wang"]]
	}

如果指定wantArray=1则返回:

	{
		[{"id": 1, "name": "liang"}, {"id": 2, "name": "wang"}]
	}

*[分页参数]*

_pagesz:: Integer. 指定页大小, 默认一次返回20条数据。
_pagekey:: String. 指定从哪条数据开始，应根据上次调用时返回数据的"nextkey"字段来填写。

注意：
- 分页只适用于query, 且wantArray=0的情况。

详细请参考章节[分页机制][].

### 对象列表导出

在对象查询接口中添加参数"_fmt"，可以输出指定格式，一般用于列表导出。参数：

_fmt
: Enum(csv,txt). 导出Query的内容为指定格式。其中，csv为逗号分隔UTF8编码文本；txt为制表分隔的UTF8文本。注意，由于默认会有分页，要想导出所有数据，一般可指定_pagesz=9999。

在实现时，注意设置正确的HTTP头，如csv文件：

	Content-Type: application/csv; charset=UTF-8
	Content-Disposition: attachment;filename=1.csv

导出txt文件设置HTTP头的例子：

	Content-Type: text/plain; charset=UTF-8
	Content-Disposition: attachment;filename=1.txt

### 对象操作示例

*[例: 添加商户]*

添加商户, 指定一些字段:

	Store.add()
		name=华莹汽车(张江店)
		addr=金科路88号
		tel=021-12345678

注: 

- Store是商户表名, 通过POST字段传递各字段内容. HTTP POST请求如下所示(实际发送时, 每个字段的值应使用UTF8+URL编码, 示例中未进行编码):

		POST /api.php?ac=Store.add
		Content-Type: application/x-www-form-urlencoded

		name=华莹汽车(张江店)&addr=金科路88号&tel=021-12345678

- id这种主键或只读字段无须设置. 即使设置也应被忽略. 

操作成功时返回id值:

	8

*[例: 获取商户]*

取刚添加的商户(id=8):

	Store.get(id=8)

操作成功时返回该行内容:

	{id: 8, name: "华莹汽车(张江店)", addr: "金科路88号", tel: "021-12345678", opentime: null, dscr: null}

可以像query方法一样用POST参数res指定返回值, 如

	Store.get(id=8)
		res=id,name as storeName,addr

操作成功时返回该行内容:

	{id: 8, storeName: "华莹汽车(张江店)", addr: "金科路88号"}

*[例: 查询商户]*

查询"华莹汽车"在"浦东"的门店, 即查询名称含有"华莹汽车"且地址中含有"浦东"的商户, 只返回id, name, addr字段:

	Store.query()
		res=id,name,addr
		cond=name like '%华莹%' and addr like '%浦东%'

操作成功时返回内容如下:

	{
		"h": [ "id", "name", "addr" ],
		"d": [
			[ 7, "华莹汽车(金桥店)", "上海市浦东区金桥路1100号"],
			[ 8, "华莹汽车(张江店)", "金科路88号" ]
		]
	}

*[导出商户]*

可以导出文本文件，这些文本又可以导入到WPS，MS excel等软件中继续处理。

	Store.query()
		res=id,name,addr
		_fmt=csv
		_pagesz=9999

可导出以逗号分隔的表格文本，使用较大的_pagesz以尽量返回所有数据。

*[例: 更新商户]*

为商户设置描述信息等:

	Store.set(id=8)
		opentime=8:00-18:00
		dscr=描述信息.

操作成功时无返回内容.

*[例: 删除商户]*

	Store.del(id=8)

操作成功时无返回内容.
	
## 分页机制

如果一个查询支持分页(paging), 则一般调用形式为

	Ordr.query(_pagekey?, _pagesz?=20) -> {nextkey, total?, @h, @d}

或

	Ordr.query(page, rows?=20) -> {nextkey, total, @h, @d}

*[参数]*

_pagesz
: Integer. 页大小，默认为20条数据。

_pagekey
: String (目前是数值). 一般某次查询不填写（如需要返回总记录数即total字段，则应填写为0），而下次查询时应根据上次调用时返回数据的"nextkey"字段来填写。

page/rows
: 这两个参数用于兼容某些支持分页的前端组件，如jquery-easyui。它们与_pagekey/_pagesz类似, 而区别在于: 每次均返回total字段; 强制采用"limit"分页算法(详细见下节，如果用_pagekey, 则会自动选择"部分查询"或"limit"分页算法)，这时返回的nextkey一定是page+1或空(当没有更多数据).

*[返回值]*

nextkey
: String. 一个字符串, 供取下一页时填写参数"_pagekey". 如果不存在该字段，则说明已经是最后一批数据。

total
: Integer. 返回总记录数，仅当_pagekey指定为0时返回。

h/d
: 实际数据表的头信息(header)和数据行(data)，符合table对象的格式，参考上一章节tbl(id,name)介绍。

*[示例]*

第一次查询

	Ordr.query()

返回

	{nextkey: 10800910, h: [id, ...], data: [...]}

其中的nextkey将供下次查询时填写_pagekey字段；

要在首次查询时返回总记录数，可以设置用_pagekey=0：

	Ordr.query(_pagekey=0)

这时返回

	{nextkey: 10800910, total: 51, h: [id, ...], data: [...]}

total字段表示总记录数。由于缺省页大小为20，所以可估计总共有51/20=3页。

第二次查询(下一页)

	Ordr.query(_pagekey=10800910)

返回

	{nextkey: 10800931, h: [...], d: [...]}

仍返回nextkey字段说明还可以继续查询，

再查询下一页

	Ordr.query(_pagekey=10800931)

返回

	{h: [...], d: [...]}

返回数据中不带"nextkey"属性，表示所有数据获取完毕。

## 分页机制实现

分页有两种实现方式：分段查询和传统分页。

分段查询性能高，更精确，不会丢失数据。但它仅适用于未指定排序字段（无orderby参数）或排序字段是id的情况（例如：orderby="id DESC"）。
系统将根据orderby参数自动选择分段查询或传统分页。

*[分段查询]*

分段查询的原理是利用主键id进行查询条件控制（自动修改WHERE语句），pagekey字段实际是上次数据的最后一个id.

首次查询：

	Ordr.query()

SQL样例如下：

	SELECT * FROM Ordr t0
	...
	ORDER BY t0.id
	LIMIT {pagesz}

再次查询

	Ordr.query(_pagekey=10800910)

SQL样例如下：

	SELECT * FROM Ordr t0
	...
	WHERE t0.id>10800910
	ORDER BY t0.id
	LIMIT {pagesz}

*[传统分页]*

传统分页只需要通过SQL语句的LIMIT关键字来实现。pagekey字段实际是页码。其原理是：

首次查询

	Ordr.query(orderby="comeTm DESC")

（以comeTm作为排序字段，无法应用分段查询机制，只能使用传统分页。）

SQL样例如下：

	SELECT * FROM Ordr t0
	...
	ORDER BY comeTm DESC, t0.id
	LIMIT 0,{pagesz}

再次查询

	Ordr.query(_pagekey=2)


SQL样例如下：

	SELECT * FROM Ordr t0
	...
	ORDER BY comeTm DESC, t0.id
	LIMIT ({pagekey}-1)*{pagesz}, {pagesz}

## 合作伙伴接口设计

如果外部合作伙伴系统希望调用接口进行操作，有两种设计方式。

一种是将它当作特殊的应用端，使用特别的应用标识（如partner）先登录，然后维持会话，继而调用其它接口，所有这些接口定义特别的权限，如AUTO_PARTNER_XX（参考[接口权限][]节）。

另一种是每次接口调用均需验证身份，使用的是统一的AUTH_PARTNER权限，一般合作接口很少的情况下常常使用这种设计方式。

协议规定，参数"partnerId", "_pwd/_sign"用于合作伙伴验证身份。实际使用时，可选用密码或MD5签名两种方式之一，一般MD5签名性能较HTTPS高。

- 使用密码("_pwd")验证时，应考虑强制使用HTTPS协议，禁止HTTP请求。
- 使用签名验证身份时，服务端依据[签名算法][]章节进行身份验证。

以导入订单接口为例：

	导入订单接口：
	importOrder(partnerId, _sign, p_startTm?, p_endTm?)(POST fields for Ordr table) -> orderId

	权限：AUTH_PARTNER，限XX合作方使用。
	
	参数：
	partnerId:: 合作伙伴编号。XX请填写2.
	_sign:: 合作伙伴身份验证。关于_sign如何生成请参考附录-签名算法。

### 签名算法

签名生成规则如下：

- 所有名字不以下划线开头的参数（包括URL中和POST中的参数）均为待签名参数。如_pwd/_test这些参数不参与签名。
- 对所有待签名参数按照字段名的ASCII 码从小到大排序（字典序，注意区分大小写）后，使用URL键值对的格式（即key1=value1&key2=value2…）拼接成字符串string1。
  注意：字段名和字段值都采用原始值，不进行URL 转义。
- 将string1和合作密码拼接得到string2, 即 `string2=string1 + pwd`
- 然后对string2做md5加密，即`_sign=md5(string2)`, 将值传给`_sign`参数.

*[示例]*

假如有以下参数：

	svcId=100
	amount=0

合伙方密码为`ABCD`, 则计算签名如下：

	string1 = "amount=0&svcId=100" （按参数名字母排序拼接）
	pwd = "ABCD"
	string2 = string1 + pwd = "amount=0&svcId=100ABCD"

	_sign = md5(string2) = "4c4ca8bf0f29a0e877ce1f1b0bf5054a"


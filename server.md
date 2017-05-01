# DACA架构服务端框架规范

DACA服务端提供基于HTTP的Web服务接口，实现BQP协议。

- 它提供函数调用型接口和对象调用型接口两类编程风格，并分别具有相应的权限检查方法。
- 它以数据模型为核心，提供通用对象操作接口，支持对通用接口的各种定制如只读字段、虚拟字段、子对象等，也支持为对象添加非标准接口。
- 它提供方便的参数获取、数据库调用、异常返回等函数。

## 通用函数

- 参数 param / mparam
- 数据库 dbconn / queryOne / queryAll / execOne
- 权限 checkAuth / hasPerm / AccessControl
- 错误处理 MyException
- 接口应用程序 ApiApp
- 日志处理 addLog / logIt

## 函数型接口

定义函数 `api_{接口名}`，可实现一个函数型接口，如“查询订单列表”的接口定义为：

	queryOrder() -> [{id, dscr, total}]

可实现为：
```php
function api_queryOrder()
{
	$data = [
		[ "id" => 100, "dscr" => "基本套餐", "total" => 128],
		[ "id" => 101, "dscr" => "高级套餐", "total" => 198],
	];

	// 成功返回，不关心最终协议格式。
	return $data;
}
```

接口实现只与接口原型定义相关，不关心URL映射等通讯协议层面的实现，框架应定义URL如何被映射到接口实现函数。

函数的返回值即是接口原型中描述的当成功调用时返回的数据结构。
框架应自动完成后续的添加返回码0、序列化传输（如转成JSON字符串）等过程。

如果函数没有返回值（即接口原型中未定义返回值），则框架应保证调用成功时返回字符串"OK"，JSON序列化后即`[0, "OK"]`。

如果使用不支持全局函数的编程语言（如java/C#等）实现，建议将接口实现函数放在名为"Global"的类中，如java实现示例：
```java
// Global类中的公有函数`api_xxx`为函数型接口实现类
public class Global
{
	public Object api_queryOrder()
	{
		JsArray data = new JsArray(
			new JsObject(
				"id", 100,
				"dscr", "基本套餐",
				"total", 128
			),
			new JsObject(
				"id", 101,
				"dscr", "高级套餐",
				"total", 198
			)
		);
		return data;
	}
}
```

其中，工具类"JsArray"和"JsObject"是可以支持通用类型（元素可以是数值、字符串、数组、对象等，一般用Object表示）、支持一行初始化数据，且可被序列化成JSON数组和对象的类。

函数型接口在实现时，通常由权限检查、参数检查、失败返回、成功返回几部分组成，大致示例如下：
```javascript
function api_queryOrder()
{
	// 权限检查，失败则自动返回错误数据
	checkAuth(AUTH_LOGIN); 

	// 获取参数，可自动检查日期类型
	$dt1 = param("date1/dt"); 

	// 失败返回，不关心失败数据处理细节
	if (...)  throw MyException(2, "XXX失败");

	// 一行查询数据库，不关心连接等细节
	$data = queryAll("SELECT ..."); 

	// 成功返回，不关心最终协议格式。
	return $data;
}
```

接口权限控制主要通过checkAuth与hasPerm两个函数实现，直接当权限检查失败，直接由框架返回错误信息；后者则返回bool值让应用来处理。

## 对象型接口

对象型接口要求实现时定义名为`{AC}_{对象名}`的类（称之为AC类），该类通过继承AccessControl基类，即可完成BQP协议中通用对象接口的全部功能，如对象增删改查、分页控制、灵活查询、统计分析、导出文件等。

示例：假如订单对象名为"Ordr"(不用"Order"以避免与同名数据库关键字冲突)，它对应“订单”这个数据模型，以下代码可将其全部操作暴露：
```php
class AC_Ordr extends AccessControl
{
}
```

通过简单地继承AccessControl类，使其拥有BQP协议中定义的通用对象接口，如：

	Ordr.add()(要添加的字段如dscr, total) -> id
	Ordr.get(id) -> {id, status, dscr, total, ...}
	Ordr.set(id)(要修改的字段...)
	Ordr.del(id)
	Ordr.query(res?, cond?, orderby?, pagesz?, pagekey?) -> table(id, status, dscr, ...)

对象型接口的权限检查主要通过登录身份与类名前缀相关联实现，例如按惯例，前缀"AC"表示允许所有角色访问。
框架应支持名为`onCreateAC`的回调函数，让编程者可以自定义什么角色访问什么名称的类，例如：
```php
function onCreateAC($tbl)
{
	$cls = null;
	if (hasPerm(AUTH_USER))
	{
		$cls = "AC1_$tbl";
		if (! class_exists($cls))
			$cls = "AC_$tbl";
	}
	else if (hasPerm(AUTH_EMP))
	{
		$cls = "AC2_$tbl";
	}
	return $cls;
}
```

上述代码表示如果是用户登录(权限定义为AUTH_USER)，则对象接口实现的类名为"AC1_{XXX}"（如果未定义该类则尝试"AC_{XXX}"类），如果是员工登录(权限定义为AUTH_EMP)，则应调用类"AC2_{XXX}"来实现接口。

如果返回null，则默认类名为`AC_{XXX}`。

下面是java实现对象访问权限控制与AC类名关联的参考，由类DacaEnvBase提供该回调函数：
```java
public class MyServiceEnv extends DacaEnvBase
{
	public String onCreateAC(String table)
	{
		if (hasPerm(AUTH_USER))
		{
			String cls = "AC1_" + table;
			try { 
				Class.forName("com.demo." + cls); 
			} catch (Exception ex) {
				cls = "AC_" + table;
			}
			return cls;
		}
		else if (hasPerm(AUTH_EMP))
		{
			return "AC2_" + table;
		}
		return null;
	}
}
```

AC类除提供通用对象接口的实现，还应支持多种权限控制，下面详述。

TODO

## 应用标识与会话

## 权限模型

通过appType确定认证类型。在登录后，将认证类型、用户id、用户权限存入会话中。在session中名称分别为appType, uid, perms。

开发者应定义AUTH_XXX和PERM_XXX系列权限。

实现 checkAuth/hasPerm: 

- AUTH_USER : appType=='user'
- AUTH_EMP: appType == 'emp'
- PERM_MGR: appType == 'emp' && perms.contains("mgr")
- PERM_TEST_MODE: global $TEST_MODE

## 调用服务

## 接口调用日志

## 批处理

## 一站式数据模型部署工具


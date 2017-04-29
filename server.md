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

## 函数型接口

定义函数 `api_{接口名}`

## 对象型接口

定义类 `AC_{对象}`，继承AccessControl类。

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


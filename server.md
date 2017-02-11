% 服务端

# 通用函数

- 参数 param / mparam
- 数据库 dbconn / queryOne / queryAll / execOne
- 权限 checkAuth / hasPerm / AccessControl
- 错误处理 MyException
- 接口应用程序 ApiApp

# 函数型接口

定义函数 `api_{接口名}`

# 对象型接口

定义类 `AC_{对象}`，继承AccessControl类。

# 权限模型/会话/登录

通过appType确定认证类型。在登录后，将认证类型、用户id、用户权限存入会话中。在session中名称分别为appType, uid, perms。

开发者应定义AUTH_XXX和PERM_XXX系列权限。

实现 checkAuth/hasPerm: 

- AUTH_USER : appType=='user'
- AUTH_EMP: appType == 'emp'
- PERM_MGR: appType == 'emp' && perms.contains("mgr")
- PERM_TEST_MODE: global $TEST_MODE


# 其它机制

## 会话

## 批处理

## API调用日志

# 扩展

- session实现方式，使用redis等库，并可持久
- API调用日志存储方式，使用非关系数据库。

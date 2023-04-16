# DACA规范

DACA, 全称分布式访问和控制架构(Distributed Access and Control Architecture), 用在基于关系数据库建模的分布式应用中（常见如BS或CS架构应用），定义客户端、服务端框架的接口和实现规范，以及应用开发规范，包括三个主要组成部分：

- [业务查询协议](BQP.html)，简称BQP(Business Query Protocol)规范，定义业务接口通讯协议的格式及设计规范。典型如对象CRUD接口、批处理接口规范等。
- 服务端框架，包括BQP协议实现规范、业务建模开发规范、后端函数接口规范、业务权限模型、部署规范、日志与审计等。典型如函数型或对象型接口开发，callSvc/param/queryOne/jdRet/logit等函数规范。
- 客户端框架，包括基于BQP协议的业务封装规范、前端函数接口和组件规范等。典型如列表与详情页实现模型、makeUrl/callSvr/useBatchCall/showPage/showDlg等函数接口。


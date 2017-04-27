## 对外开放接口设计

外部合作伙伴希望调用后端对外开放接口，有两种设计方式。

一种是将它当作特殊的应用端，使用特别的应用标识（如partner）先登录，然后维持会话，继而调用其它接口，所有这些接口定义特别的权限，如AUTH_PARTNER_XX。

另一种是每次接口调用均需验证身份，使用的是统一的AUTH_PARTNER权限，一般合作接口很少的情况下常常使用这种设计方式。

协议规定，参数"partnerId", "_pwd/_sign"用于合作伙伴验证身份。实际使用时，可选用密码或MD5签名两种方式之一，一般MD5签名性能较HTTPS高。

- 使用密码("_pwd")验证时，应考虑强制使用HTTPS协议，禁止HTTP请求。
- 使用签名验证身份时，服务端依据[签名算法][]章节进行身份验证。

以导入订单接口为例：

	导入订单接口：
	importOrder(partnerId, _sign)(POST fields for Ordr) -> orderId

	参数：

	partnerId:: 合作伙伴编号。
	_sign:: 合作伙伴身份验证。关于_sign如何生成请参考附录-签名算法。

	应用逻辑：

	- 权限：AUTH_PARTNER

### 签名算法

签名生成规则如下：

- 所有名字不以下划线开头的参数（包括URL中和POST中的参数）均为待签名参数。如_pwd/_test这些参数不参与签名。
- 对所有待签名参数按照字段名的ASCII 码从小到大排序（字典序，注意区分大小写）后，使用URL键值对的格式（即key1=value1&key2=value2…）拼接成字符串string1。
  注意：字段名和字段值都采用原始值，不进行URL 转义。
- 将string1和合作密码拼接得到string2, 即 `string2=string1 + pwd`
- 然后对string2做md5加密，即`_sign=md5(string2)`, 将值传给`_sign`参数.

**[示例]**

假如有以下参数：

	svcId=100
	amount=0

合伙方密码为`ABCD`, 则计算签名如下：

	string1 = "amount=0&svcId=100" （按参数名字母排序拼接）
	pwd = "ABCD"
	string2 = string1 + pwd = "amount=0&svcId=100ABCD"

	_sign = md5(string2) = "4c4ca8bf0f29a0e877ce1f1b0bf5054a"


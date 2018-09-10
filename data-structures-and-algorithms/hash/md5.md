# MD5算法
由R. Rivest在1991年设计，取代之前的MD5算法。在1992年4月将规范发布到[RF 1321]((https://www.ietf.org/rfc/rfc1321.txt))。

# 简介
该算法将输入的任意长度的消息，输出长度为128位的摘要信息，该摘要信息在一定程度不会重复、不可反推原始数据。

MD5算法在32位机上运行得非常快速，并且不需要任何大的替换表，可以非常简洁的编码。

MD5是MD4的扩展，略慢于MD4，但更为稳固（指不可逆与无冲突特性）。

# 术语与符号
1. 定义`word`表示32-bit长度，定义`byte`表示8-bit长度。
2. 使用`x_i`表示`x是i的子集`(x sub i)，如果下标是表达式，使用大括号括起来，如`x_{i+1}`。
3. 使用`^`上标表示幂运算，如`x^i`表示x的i次幂。
4. 使用符号`+`表示向`word`中添加内容。
5. 使用`X <<< s`表示x左移s个位。
6. 使用`not(X)`表示逐位补充(complement)X。（译注：应该是反转才对）
7. 使用`X v Y`表示对X、Y执行位的或(OR)运算。
8. 使用`X xor Y`表示对X、Y执行位的异或(XOR)运算。
9. 使用`XY`表示对X、Y执行位的与(AND)运算。

# 算法描述
假设有一个b-bit的消息作为输入，需要输出其消息摘要(md)。此处b是任意的正整数。
b可能为0，不需要是8的倍数，b可能无限大。我们可以想像该消息写下来应该是下面这样：
```
m_0 m_1 ... m_{b-1}
```
执行下面五个步骤来计算该消息的摘要。

### Step 1. 附加填充位
填充消息，使其长度模512之后等于448。也就是说，填充消息使其长度为64位，值为512的倍数（这句翻译得很勉强）。
填充是必须的，即使消息的长度已经是模512等于448。

填充消息执行如下：
将`1`添加到消息，然后加`0`，直到其长度为模512等于448。总之，到少要添加1位，至多添加512位。

### Step 2. 增加长度
b的64-bit表现形式添加到上一步的结果中，可以肯定的是b不可能大于2^64，因此只有低位的64位被使用。
这些位数被放置在2个32位的word中，并按照先前的约定首先添加低阶word。

此时，该消息的长度是512的倍数，也是16个word(32-bit)的倍数。使用`M[0 ... N-1]`表示所得到的消息，其中N是16的倍数。

### Step 3. 初始化MD Buffer
使用四个`word` buffer(A,B,C,D)来计算消息摘要，A,B,C,D都是一个32位寄存器。
分别使用下面的十六进制值来初始化，低位放在前面。
```
word A: 01 23 45 67
word B: 89 ab cd ef
wrod C: fe dc ba 98
wrod D: 76 54 32 10
```

### Step 4. 在16-word块中处理消息
首先定义四个辅助函数，输入3个32位的word，输出一个32位的word。
```
F(X,Y,Z) = XY v not(X) Z
G(X,Y,Z) = XZ v Y not(Z)
H(X,Y,Z) = X xor Y xor Z
I(X,Y,Z) = Y xor (X v not(Z)) 
```
每个bit位F充当条件：if X then Y else Z。函数F可以使用`+`代替`v`，因为`XY`与`not(X)`永远不会出现在相同的位置。
有趣的是，如果X,Y,Z的位置是独立且无偏的(independent and unbiased)，那么每位计算的`F(X,Y,Z)`也是独立无偏的。

函数G,H,I与F类似，因为它们以逐位并行(bitwise parallel)的方式从X,Y,Z位和生输出。如此，如果X,Y,Z是独立且无偏的，
那么每个位的`G(X,Y,Z)`，`H(X,Y,Z)`与`I(X,Y,Z)`也会独立无偏的。注：函数H是其输入的位的xor或等价函数。

该步使用一个由正弦函数构成的64元素表T[1 ... 64]。使用`T[i]`表示第i个元素，其值为 4294967296 * asb(sin(i)) 的整数部分，
其中i是弧度，表中的元素在附录中给出。

进行如下操作：
```
/* 处理每个16-word块 */
For i = 0 to N/16-1 do

	/* Copy block i into X. */
 	For j = 0 to 15 do
		Set X[j] to M[i*16+j].
 	end /* of loop on j */

	/* Save A as AA, B as BB, C as CC, and D as DD. */
	AA = A
	BB = B
	CC = C
	DD = D
	/* Round 1. */
	/* Let [abcd k s i] denote the operation
		a = b + ((a + F(b,c,d) + X[k] + T[i]) <<< s). */
	/* Do the following 16 operations. */
	[ABCD  0  7  1]  [DABC  1 12  2]  [CDAB  2 17  3]  [BCDA  3 22  4]
	[ABCD  4  7  5]  [DABC  5 12  6]  [CDAB  6 17  7]  [BCDA  7 22  8]
	[ABCD  8  7  9]  [DABC  9 12 10]  [CDAB 10 17 11]  [BCDA 11 22 12]
	[ABCD 12  7 13]  [DABC 13 12 14]  [CDAB 14 17 15]  [BCDA 15 22 16]

	/* Round 3. */
	/* Let [abcd k s t] denote the operation
		a = b + ((a + H(b,c,d) + X[k] + T[i]) <<< s). */
	/* Do the following 16 operations. */
	[ABCD  5  4 33]  [DABC  8 11 34]  [CDAB 11 16 35]  [BCDA 14 23 36]
	[ABCD  1  4 37]  [DABC  4 11 38]  [CDAB  7 16 39]  [BCDA 10 23 40]
	[ABCD 13  4 41]  [DABC  0 11 42]  [CDAB  3 16 43]  [BCDA  6 23 44]
	[ABCD  9  4 45]  [DABC 12 11 46]  [CDAB 15 16 47]  [BCDA  2 23 48]

	/* Round 4. */
	/* Let [abcd k s t] denote the operation
		a = b + ((a + I(b,c,d) + X[k] + T[i]) <<< s). */
	/* Do the following 16 operations. */
	[ABCD  0  6 49]  [DABC  7 10 50]  [CDAB 14 15 51]  [BCDA  5 21 52]
	[ABCD 12  6 53]  [DABC  3 10 54]  [CDAB 10 15 55]  [BCDA  1 21 56]
	[ABCD  8  6 57]  [DABC 15 10 58]  [CDAB  6 15 59]  [BCDA 13 21 60]
	[ABCD  4  6 61]  [DABC 11 10 62]  [CDAB  2 15 63]  [BCDA  9 21 64]

	/* Then perform the following additions. (That is increment each
		of the four registers by the value it had before this block
		was started.) */
	A = A + AA
	B = B + BB
	C = C + CC
	D = D + DD

end /* of loop on i */
```

### Step 5. Output
输出A、B、C、D作为消息摘要，以A的低阶字节开始，以D的高阶字节结束。

附录中有一份C语言的实现。

# 总结
MD5消息摘要算法很容易实现，为任意长度的消息提供一个指纹。
推测得到两个具有相同摘要消息的难度大约为2^64个操作。
推测得到任何具有给定消息摘要的消息难度大约为2^128个操作。
MD5算法已被仔细审查弱点，然而它是一个相对较新的算法，进一步的安全分析是合理的。

# 与MD4的区别
TODO

# C语言实现
包含如下的文件：
1. [global.h](./c-implementation/global.h)        -- 全局头文件
2. [md5.h](./c-implementation/md5.h)              -- MD5头文件
3. [md5c.c](./c-implementation/md5c.c)            -- MD5源码
4. [mddriver.c](./c-implementation/mddriver.c)    -- md2,md4,md5测试
 
# 参考
1. [RF 1321](https://www.ietf.org/rfc/rfc1321.txt)
2. [https://en.wikipedia.org/wiki/MD5](https://en.wikipedia.org/wiki/MD5)

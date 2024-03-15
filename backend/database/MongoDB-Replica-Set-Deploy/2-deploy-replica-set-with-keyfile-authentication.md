# 使用密钥文件身份验证部署副本集
对副本集实施访问控制需要配置：
+ 使用[内部身份验证](https://www.mongodb.com/docs/v4.4/core/security-internal-authentication/)的副本集成员之间的安全性。
+ 使用基于[角色的访问控制](https://www.mongodb.com/docs/v4.4/core/authorization/)确保连接客户端和副本集之间的安全性。

对于本教程，副本集的每个成员都使用相同的内部身份验证机制和设置。

强制执行内部身份验证还强制执行用户访问控制。要连接到副本集，像`mongo shell`这样的客户端需要使用用户帐户。查阅[用户和认证机制](https://www.mongodb.com/docs/v4.4/tutorial/deploy-replica-set-with-keyfile-access-control/#std-label-security-repSetDeploy-access-control)。

> 如果可能，请使用逻辑 DNS 主机名而不是 IP 地址，特别是在配置副本集成员或分片集群成员时。使用逻辑 DNS 主机名可以避免由于 IP 地址更改而导致的配置更改。

## IP绑定
mongod 和 mongos 默认绑定到`localhost`。如果部署的成员在不同的主机上运行，​​或者如果您希望远程客户端连接到您的部署，则必须指定`--bind_ip`或`net.bindIp`。

## 操作系统
本教程主要涉及`mongod`进程。 Windows用户应使用`mongod.exe`程序。

## 密钥文件安全
密钥文件是最低限度的安全形式，最适合测试或开发环境。对于生产环境，我们建议使用[x.509证书](https://www.mongodb.com/docs/v4.4/core/security-x.509/)。

# 使用密钥文件访问控制部署新副本集
运行环境：
+ macOS Big sur (version 11.7.10)
+ Docker desktop macOS 3.3.0(62916)

## 模拟环境搭建
1. 新建工作目录：
```bash
mkdir -p $HOME/docker/mongo/volume # 工作目录
mkdir -p $HOME/docker/mongo/volume/config
```

2. 在工作目录下新建`docker-compose.yml`文件，配置MongoDB环境，内容如下：
```yml
version: '3.1'
services:
  mongo0:
    image: mongo:4.2
    restart: "no"
    command:
      - "--config"
      - "/etc/mongo/config/mongod.conf"
    volumes:
      - ./volume:/etc/mongo
  mongo1:
    image: mongo:4.2
    restart: "no"
    command:
      - "--config"
      - "/etc/mongo/config/mongod.conf"
    volumes:
      - ./volume:/etc/mongo
  mongo2:
    image: mongo:4.2
    restart: "no"
    command:
      - "--config"
      - "/etc/mongo/config/mongod.conf"
    volumes:
      - ./volume:/etc/mongo
```

## 部署MongoDB

### 1. 创建密钥文件
通过密钥文件身份验证，副本集中的每个 mongod 实例都使用密钥文件的内容作为共享密码来对部署中的其他成员进行身份验证。 只有具有正确密钥文件的 mongod 实例才能加入副本集。

您可以使用您选择的任何方法生成密钥文件。 例如，以下操作使用 openssl 生成复杂的伪随机 1024 字符串作为共享密码。 然后它使用 chmod 更改文件权限以仅为文件所有者提供读取权限：
```bash
cd $HOME/docker/mongo/volume/config
openssl rand -base64 756 > keyfile
chmod 400 keyfile
```

### 2. 将密钥文件复制到每个副本集成员。
将密钥文件复制到托管副本集成员的每台服务器。确保运行 mongod 实例的用户是文件的所有者并且可以访问密钥文件。

本例中因为密钥文件在工作目录下，docker容器可以通过挂载卷使用，所以不用复制。

### 3. 启动副本集的每个成员并启用访问控制。
对于副本集中的每个成员，使用`security.keyFile`配置文件设置或`--keyFile`命令行选项启动 mongod。mongod 会强制执行内部/成员身份验证和基于角色的访问控制。

如果使用配置文件，请设置`security.keyFile`到密钥文件的路径，以及`replication.replSetName`为副本集名称。

根据您的配置需要包括其他选项。例如，如果您希望远程客户端连接到您的部署或您的部署成员在不同的主机上运行，​​请指定`net.bindIp`设置。

配置文件示例（在`$HOME/docker/mongo/volume/config`目录下创建）：
```yml
security:
  keyFile: /etc/mongo/config/keyfile
replication:
  replSetName: "demo"
net:
# 注意：docker中不要指定ip，否则有意想不到的错误，如果部署在主机（虚拟机）上
# 可以指定ip
#  bindIp: 127.0.0.1,172.30.0.2
  port: 27017
```

启动docker容器：
```bash
cd $HOME/docker/mongo
docker compose up -d
...
➜  mongo docker compose up -d
[+] Running 4/4
 ⠿ Network "mongo_default"   Created               3.2s
 ⠿ Container mongo_mongo2_1  Started               5.6s
 ⠿ Container mongo_mongo1_1  Started               6.0s
 ⠿ Container mongo_mongo0_1  Started               6.2s
```

### 4. 通过本地主机接口连接到副本集的成员。
通过`localhost`接口将`mongo shell`连接到 mongod 实例之一。您必须在与 mongod 实例相同的物理计算机上运行`mongo shell`。

本地主机接口仅在尚未为部署创建用户之前可用。创建第一个用户后，本地主机界面将关闭。

```bash
# 1. 查看容器ID
docker ps
...
CONTAINER ID   IMAGE      ...  PORTS       NAMES
0e99d4814b46   mongo:4.2  ...  27017/tcp   mongo_mongo2_1
0a88d405e6b6   mongo:4.2  ...  27017/tcp   mongo_mongo0_1
c0190e62048d   mongo:4.2  ...  27017/tcp   mongo_mongo1_1

# 2. 随便选择一个mongo容器进入bash
docker exec -it mongo_mongo0_1 bash

# 3. 进入mongo shell
root@0a88d405e6b6:/# mongo
...
MongoDB shell version v4.2.24
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("a68115f0-59dc-49cc-86c7-6012743af0ad") }
MongoDB server version: 4.2.24
```

### 5. 启动副本集
从`mongo shell`运行`rs.initiate()`方法。
> 仅在副本集的一个且仅一个 mongod 实例上运行`rs.initiate()`。

```bash
> rs.initiate({_id: "demo", members: [{_id: 0, host: "mongo0:27017"}, {_id:1,host:"mongo1:27017"}, {_id:2, host: "mongo2:27017"} ]})
...
{ "ok" : 1 }
# 查看复制集
>rs.status()
...
demo:SECONDARY> rs.status()
{
	"set" : "demo",
	"date" : ISODate("2024-03-15T14:01:06.720Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncingTo" : "",
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"majorityVoteCount" : 2,
	"writeMajorityCount" : 2,
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1710511259, 1),
			"t" : NumberLong(1)
		},
		"lastCommittedWallTime" : ISODate("2024-03-15T14:00:59.080Z"),
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1710511259, 1),
			"t" : NumberLong(1)
		},
		"readConcernMajorityWallTime" : ISODate("2024-03-15T14:00:59.080Z"),
		"appliedOpTime" : {
			"ts" : Timestamp(1710511259, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1710511259, 1),
			"t" : NumberLong(1)
		},
		"lastAppliedWallTime" : ISODate("2024-03-15T14:00:59.080Z"),
		"lastDurableWallTime" : ISODate("2024-03-15T14:00:59.080Z")
	},
	"lastStableRecoveryTimestamp" : Timestamp(1710511239, 1),
	"lastStableCheckpointTimestamp" : Timestamp(1710511239, 1),
	"electionCandidateMetrics" : {
		"lastElectionReason" : "electionTimeout",
		"lastElectionDate" : ISODate("2024-03-15T13:59:38.990Z"),
		"electionTerm" : NumberLong(1),
		"lastCommittedOpTimeAtElection" : {
			"ts" : Timestamp(0, 0),
			"t" : NumberLong(-1)
		},
		"lastSeenOpTimeAtElection" : {
			"ts" : Timestamp(1710511167, 1),
			"t" : NumberLong(-1)
		},
		"numVotesNeeded" : 2,
		"priorityAtElection" : 1,
		"electionTimeoutMillis" : NumberLong(10000),
		"numCatchUpOps" : NumberLong(0),
		"newTermStartDate" : ISODate("2024-03-15T13:59:39.058Z"),
		"wMajorityWriteAvailabilityDate" : ISODate("2024-03-15T13:59:40.335Z")
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "mongo0:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 130,
			"optime" : {
				"ts" : Timestamp(1710511259, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2024-03-15T14:00:59Z"),
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "could not find member to sync from",
			"electionTime" : Timestamp(1710511178, 1),
			"electionDate" : ISODate("2024-03-15T13:59:38Z"),
			"configVersion" : 1,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 1,
			"name" : "mongo1:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 98,
			"optime" : {
				"ts" : Timestamp(1710511259, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1710511259, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2024-03-15T14:00:59Z"),
			"optimeDurableDate" : ISODate("2024-03-15T14:00:59Z"),
			"lastHeartbeat" : ISODate("2024-03-15T14:01:05.264Z"),
			"lastHeartbeatRecv" : ISODate("2024-03-15T14:01:06.525Z"),
			"pingMs" : NumberLong(1),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "mongo0:27017",
			"syncSourceHost" : "mongo0:27017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 1
		},
		{
			"_id" : 2,
			"name" : "mongo2:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 98,
			"optime" : {
				"ts" : Timestamp(1710511259, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1710511259, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2024-03-15T14:00:59Z"),
			"optimeDurableDate" : ISODate("2024-03-15T14:00:59Z"),
			"lastHeartbeat" : ISODate("2024-03-15T14:01:05.269Z"),
			"lastHeartbeatRecv" : ISODate("2024-03-15T14:01:06.398Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "mongo0:27017",
			"syncSourceHost" : "mongo0:27017",
			"syncSourceId" : 0,
			"infoMessage" : "",
			"configVersion" : 1
		}
	],
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1710511259, 1),
		"signature" : {
			"hash" : BinData(0,"ouJIqfsXYUiskzc1cX1cVMeRhmo="),
			"keyId" : NumberLong("7346589573247401987")
		}
	},
	"operationTime" : Timestamp(1710511259, 1)
}
```
可以看到`members[n].stateStr`的值，有的为`PRIMARY`，有的为`SECONDARY`。启动复制集成功。

`rs.initiate()`触发选举并选举其中一名成员作为主要成员。

### 6. 创建用户管理员
创建第一个用户后，[本地主机例外](https://www.mongodb.com/docs/v4.4/core/security-users/#std-label-localhost-exception)不再可用。

第一个用户必须具有创建其他用户的权限，例如具有[userAdminAnyDatabase](https://www.mongodb.com/docs/v4.4/reference/built-in-roles/#mongodb-authrole-userAdminAnyDatabase)的用户。 这可确保您可以在[本地主机例外](https://www.mongodb.com/docs/v4.4/core/security-users/#std-label-localhost-exception)关闭后创建其他用户。

如果至少一个用户没有创建用户的权限，则一旦本地主机例外关闭，您可能无法使用新权限创建或修改用户，因此无法访问必要的操作。

> 您必须连接到主服务器才能创建用户。
```bash
mongo
demo:PRIMARY> admin = db.getSiblingDB("admin")
admin
demo:PRIMARY> admin.createUser({user: "fred", pwd:  "123456", roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]})
Successfully added user: {
	"user" : "fred",
	"roles" : [
		{
			"role" : "userAdminAnyDatabase",
			"db" : "admin"
		}
	]
}
```

### 7. 以用户管理员身份进行身份验证
```bash
mongo
demo:PRIMARY> db.getSiblingDB("admin").auth("fred","123456")
1
```

### 8. 创建集群管理员
[clusterAdmin](https://www.mongodb.com/docs/v4.4/reference/built-in-roles/#mongodb-authrole-clusterAdmin)角色授予对复制操作的访问权限，例如配置副本集。

创建集群管理员用户并在 admin 数据库中分配 clusterAdmin 角色：

```bash
demo:PRIMARY> db.getSiblingDB("admin").createUser({"user" : "ravi","pwd" : "123456",roles: [ { "role" : "clusterAdmin", "db" : "admin" } ]})
Successfully added user: {
	"user" : "ravi",
	"roles" : [
		{
			"role" : "clusterAdmin",
			"db" : "admin"
		}
	]
}
```
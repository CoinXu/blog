# MongoDB部署之副本集(Replica Set)模式
MongoDB 中的副本集是一组维护相同数据集的 mongod 进程。 副本集提供冗余和高可用性，是所有生产部署的基础。 

## 冗余和数据可用性
复制集提供冗余并提高数据可用性。通过不同数据库服务器上的多个数据副本，复制提供了针对单个数据库服务器丢失的一定程度的容错能力。

在某些情况下，复制可以提供更高的读取容量，因为客户端可以将读取操作发送到不同的服务器。 在不同数据中心维护数据副本可以提高分布式应用程序的数据局部性和可用性。 您还可以维护额外的副本用于专用目的，例如灾难恢复、报告或备份。

## MongoDB 中的复制
副本集是一组维护相同数据集的 mongod 实例。 副本集包含多个数据承载节点和一个可选的仲裁节点。 在数据承载节点中，只有一个成员被视为主节点，而其他节点被视为次节点。

> 每个副本集节点必须属于一个且仅属于一个副本集。副本集节点不能属于多个副本集。

主节点接收所有写操作。 副本集只能有一个主节点能够写入； 某些情况下，另一个 mongod 实例可能会暂时认为自己也是主节点。 主节点将其数据集的所有更改记录在其操作日志中，即`oplog`。 

![replica-set-read-write-operations-primary](./assets/replica-set-read-write-operations-primary.bakedsvg.svg)

次级节点复制主节点的`oplog`并将操作应用于其数据集，以便次级节点的数据集反映主节点的数据集。如果主节点不可用，符合条件的次节点将会举行选举，使其成为新的主节点。

在某些情况下（比如你有一个主节点，一个次节点，但是成本限制无法添加另一个次节点），你可以选择将一个`mongod`实例添加到副本集，作为`arbiter`（仲裁者），仲裁者参于选举，但不保存数据（即不提供冗余数据）。

![replica-set-primary-with-secondary-and-arbiter](./assets/replica-set-primary-with-secondary-and-arbiter.bakedsvg.svg)

仲裁者永远是仲裁者，但在选举期间，主节点可能下台成为次节点，次节点可能成为主节点。

## 异步复制
次节点复制主节点的的`oplog`，并将其操作异步应用于其数据集。通过让次节点的数据集映射主节点的数据集，即使一个或多个成员发生故障，副本集也能继续运行。

## 复制延迟和流量控制
复制延迟是指将主服务器上的写入操作复制到辅助服务器所需的时间量。 一些小的延迟时间可能是可以接受的，但随着复制延迟的增加，会出现严重的问题，包括在主服务器上建立缓存压力。

从 MongoDB 4.2 开始，管理员可以限制主数据库应用其写入的速率，目的是将[majority committed](https://www.mongodb.com/docs/v4.4/reference/command/replSetGetStatus/#mongodb-data-replSetGetStatus.optimes.lastCommittedOpTime)的延迟保持在可配置的最大值 [flowControlTargetLagSeconds](https://www.mongodb.com/docs/v4.4/reference/parameters/#mongodb-parameter-param.flowControlTargetLagSeconds)之下。

默认情况下，流量控制处于启用状态。

启用流量控制后，随着延迟接近[flowControlTargetLagSeconds](https://www.mongodb.com/docs/v4.4/reference/parameters/#mongodb-parameter-param.flowControlTargetLagSeconds)，主节点上的写入操作必须在获取锁定以应用写入操作之前获取票证。 通过限制每秒发出的票证数量，流量控制机制尝试将延迟保持在目标以下。

## 自动故障转移
当主节点在超过配置的[electionTimeoutMillis](https://www.mongodb.com/docs/v4.4/reference/replica-configuration/#mongodb-rsconf-rsconf.settings.electionTimeoutMillis)时间段（默认情况下为10秒）内未与集合中的其他成员通信时，符合资格的次节点将要求进行选举以提名自己为新的主节点。集群尝试完成新主节点的选举并恢复正常运行。

![replica-set-trigger-election](./assets/replica-set-trigger-election.bakedsvg.svg)

在选举成功完成之前，副本集无法处理写操作。如果读取查询配置为在主数据库离线时在辅助数据库上运行，则副本集可以继续提供读取查询服务。

集群选举新主节点之前的中位时间通常不应超过 12 秒（使用默认配置的情况下），网络延迟等因素可能会延长副本集选举完成所需的时间，这反过来又会影响集群在没有主节点的情况下运行的时间。 这些因素取决于您特定的集群架构。

由于临时网络延迟等因素，即使主节点在其他方面是健康的，集群也可能会更频繁地进行选举。 这可能会导致写入操作的回滚次数增加。

您的应用程序连接逻辑应包括对自动故障转移和后续选举的容忍。 MongoDB 驱动程序可以检测主数据库的丢失，并自动重试某些写入操作，从而提供自动故障转移和选举的额外内置处理：

兼容的驱动程序默认启用可重试写入。

从4.4版本开始，MongoDB提供[镜像读取](https://www.mongodb.com/docs/v4.4/replication/#std-label-mirrored-reads)使用最近访问的数据预热可选次节点成员的缓存。预热辅助节点的缓存有助于在选举后更快地恢复性能。

## 读操作
默认情况下，客户端从主数据库读取，但是，客户端可以指定[读取首选项](https://www.mongodb.com/docs/v4.4/core/read-preference/)以将读取操作发送到辅助节点。


![replica-set-read-preference-secondary](./assets/replica-set-read-preference-secondary.bakedsvg.svg)

__异步复制__ 到辅助节点意味着从辅助节点读取数据可能会返回不反映主节点上数据状态的数据。

包含读操作的[分布式事务](https://www.mongodb.com/docs/v4.4/core/transactions/#std-label-transactions)必须使用读首选项`primary`。给定事务中的所有操作必须路由到同一成员。

副本集提供了许多选项来支持应用程序需求。 例如，您可以部署[成员在多个数据中心](https://www.mongodb.com/docs/v4.4/core/replica-set-architecture-geographically-distributed/)的副本集，或者通过调整某些成员的[members[n].priority](https://www.mongodb.com/docs/v4.4/reference/replica-configuration/#mongodb-rsconf-rsconf.members-n-.priority)来控制选举结果。 副本集还支持专用成员进行报告、灾难恢复或备份功能。

# 参考资料
[https://www.mongodb.com/docs/v4.4/replication/](https://www.mongodb.com/docs/v4.4/replication/)
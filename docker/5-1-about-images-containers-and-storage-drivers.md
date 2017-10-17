# 镜像、容器与存储驱动

要有效的使用存储驱动，你需要理解Docker是如何构建与存储镜像的。之后，你需要明白容器如何使用镜像。
最后，你需要一个启动镜像与操作容器的知识的简短介绍。

了解容器如何管理镜像与容器数据将会帮你明白规划容器与Docker化你的应用的最佳方式，避免之后出现性能问题。

# 镜像与层 (Images and layers)
Docker镜像由一系列有序的层组成。每一层由镜像Dockerfile中的一条指令表示。
除了最后一层之外，其余层的层都是只读的。考虑如下Dockerfile:
```conf
FROM ubuntu:15.04
COPY . /app
RUN make /app
CMD python /app/app.py
```
该Dockerfile包含了四条命令，每一条创建一个层。
+ `FROM`声明开始从`ubuntu:15.04`镜像创建一个层。
+ `COPY`命令添加从当前Docker客户端当前目录添加一些文件。
+ `RUN`命令使用`make`命令构建你的应用。
+ `CMD`声明指明了在容器内运行的命令。

每一层内容仅仅是与之前层的内容差异，堆积在其他层之上。当创建一个新的容器的时候，
添加一个新的可写层在所有层之上。该层一般称之为`容器层`(container layer)。
运行中的容器所有变化(比如写入新文件、修改已存在的文件、删除文件)都将写入该层。
下图展示了一个基于Ubuntu 15.04的镜像。

![container-layers](https://raw.githubusercontent.com/CoinXu/blog/master/docker/container-layers.jpg)

存储驱动处理这些镜像层彼此交互方式的细节，不同的存储驱动都可以是用，只是在不同的情况下有各自的优缺点。

# 容器与层 (Container and layers)
容器与镜像最大的不同就是位于顶层的可写层。所有写入容器的(新增或修改)数据保存在可写层。
当容器删除后，可写层也被删除，底层镜像保持不变。

由于每个容器有自己的可写容器层，并且所有的改变都存在容器层中，
所以多个容器可以共享相同的底层镜像，还可以有自己的数据状态。下图展示了多个容器共享同一个Ubuntu 15.04 镜像。

![sharing-layers.jpg](https://raw.githubusercontent.com/CoinXu/blog/master/docker/sharing-layers.jpg)

> __注__：如果你需要多个镜像共同访问同一个已存的数据，可以将数据存在一个Docker volume中并挂载到你的容器。

Docker 使用存储驱动管理镜像层与可写容器层内容。每个存储驱动以不同方式实现，
但所有的驱动都使用可堆叠(stackable)镜像层与写时复制(copy-on-write)策略。

# 容器占用磁盘大小 (Container size on disk)
查看运行中的容器大小的近似值，可以使用`docker ps -s`命令，两列数据与大小相关。

+ size: 每个容器可写层占用磁盘上数据量
+ virtual size: 容器镜像只读层数据量。多个容器可能共享相同的部分或所有的只读镜像数据。
  两个容器由同一镜像启动并共享其所有的只读数据，而两个容器具有不同的镜像，但是这两个镜像具有共同共享数据。
  所以你不能只计算`virtual sizes`，这将高估磁盘的使用量。

所有运行中的容器所占的磁盘空间为每个容器的`size`与`virtual size`值之合。如果多个容器具有相同的`virtual size`，
他们可能由相同的的镜像启动。

这也不包含容器以如下附加方式占用磁盘空间：

+ 使用`json-file`日志驱动产生的日志文件占用的空间
+ 容器的数据卷与绑定挂载产生的占用
+ 容器配置文件，通常很小
+ 内存数据写入磁盘(如果开启了交换空间配置)
+ 检查点(Checkpoints)，如果你使用了实验性的checkpoint/restore特性

# 写时复制机制(copy-on-write CoW)
CoW是一种最大效率共享与复制文件策略。如果一个文件或目录在镜像中的底层，并且其他层(包含在写入层)需要访问该文件，
则仅使用该文件。其他层首次修改该文件(创建镜像或启动容器时)，该文件复制到该层并修改。
这对后面的层级而言I/O与大小将变得最小化。下面将会深入解释该特性。

### 共享机制促使镜像变得更小 (Sharing promotes smaller images)
使用`docker pull`拉取远程仓库镜像或创建一个本地不存在的容器时，每个层将会分别的下载到Docker本地存储区域。
在Linux主机上一般位于`/var/lib/docker`。你可以在下面示例开始拉取时看到这些层级:
```bash
$ docker pull ubuntu:15.04

15.04: Pulling from library/ubuntu
1ba8ac955b97: Pull complete
f157c4e5ede7: Pull complete
0b7e98f84c4c: Pull complete
a3ed95caeb02: Pull complete
Digest: sha256:5e279a9df07990286cce22e1b0f5b0490629ca6d187698746ae5e28e604a640e
Status: Downloaded newer image for ubuntu:15.04
```
这些层将会存储在本地存储区域各自的目录中。列出`/var/lib/docker/<storage-driver>/layers/`的内容可以确认这些层。
以下示例使用`aufs`默认存储驱动:
```bash
ls /var/lib/docker/aufs/layers
1d6674ff835b10f76e354806e16b950f91a191d3b471236609ab13a930275e24
5dbb0cbe0148cf447b9464a358c1587be586058d9a4c9ce079320265e2bb94e7
bef7199f2ed8e86fa4ada1309cfad3089e0542fec8894690529e4c04a7ca2d73
ebf814eccfe98f2704660ca1d844e4348db3b5ccc637eb905d4818fbfb00a06a
```
目录名称与层的ID不是对应关系(开始于Docker1.10)。

现在，想像你有两个不同的Dockerfile，你使用第一个创建一个名为`acme/my-base-image:1.0`的镜像。
```conf
FROM ubuntu:16.10
COPY . /app
```
另一个基于`acme/my-base-image:1.0`，但是有一些附加的层：
```conf
FROM acme/my-base-iamge:1.0
CMD /app/hello.sh
```
第二个镜像包含第一个镜像所有的层，并用`CMD`指令添加了一个新的层，还有一个读写层(译注：容器最顶层都是读写层)。
Docker已经拥有了第一个镜像中的所有层，所以不必再次拉取这些层。这两个镜像将会共享它们所有的共有层。

如果你用这两个Dockerfile创建镜像，可以使用`docker images`和`docker history`命令检查共享层的加密ID是否相同。

1. 创建新的目录`cow-test/`
2. 在`cow-test/`中创建一个新文件饮食如下内容
   ```bash
   #!/bin/sh
   echo "hello world"
   ```
   保存文件，并使其可执行
   ```bash
   chmod +x hello.sh
   ```
3. 复制上述第一个Dockerfile的内容到名为`Dockerfile.base`新文件中
4. 复制上述第二个Dockerfile的内容到名为`Dockerfile`新文件中
5. 在`cow-test`目录中构建第一个镜像
   ```bash
   $ docker build -t acme/my-base-image:1.0 -f Dockerfile.base .

   Sending build context to Docker daemon  4.096kB
   Step 1/2 : FROM ubuntu:16.10
    ---> 31005225a745
   Step 2/2 : COPY . /app
    ---> Using cache
    ---> bd09118bcef6
   Successfully built bd09118bcef6
   Successfully tagged acme/my-base-image:1.0
   ```
6. 构建第二个镜像
   ```bash
   $ docker build -t acme/my-final-image:1.0 -f Dockerfile .

   Sending build context to Docker daemon  4.096kB
   Step 1/2 : FROM acme/my-base-image:1.0
    ---> bd09118bcef6
   Step 2/2 : CMD /app/hello.sh
    ---> Running in a07b694759ba
    ---> dbf995fc07ff
   Removing intermediate container a07b694759ba
   Successfully built dbf995fc07ff
   Successfully tagged acme/my-final-image:1.0
   ```
7. 查看两个镜像的大小:
   ```bash
   $ docker images

   REPOSITORY           TAG   IMAGE ID      CREATED           SIZE
   acme/my-final-image  1.0   dbf995fc07ff  58 seconds ago    103MB
   acme/my-base-image   1.0   bd09118bcef6  3 minutes ago     103MB
   ```
8. 查看组成所有的镜像的层级
   ```bash
   $ docker history bd09118bcef6
   IMAGE          CREATED        CREATED BY                                     SIZE                COMMENT
   bd09118bcef6   4 minutes ago  /bin/sh -c #(nop) COPY dir:35a7eb158c1504e...  100B
   31005225a745   3 months ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]           0B
   <missing>      3 months ago   /bin/sh -c mkdir -p /run/systemd && echo '...  7B
   <missing>      3 months ago   /bin/sh -c sed -i 's/^#\s*\(deb.*universe\...  2.78kB
   <missing>      3 months ago   /bin/sh -c rm -rf /var/lib/apt/lists/*         0B
   <missing>      3 months ago   /bin/sh -c set -xe   && echo '#!/bin/sh' >...  745B
   <missing>      3 months ago   /bin/sh -c #(nop) ADD file:eef57983bd66e3a...  103MB
   ```
   ```bash
   $ docker history dbf995fc07ff

   IMAGE         CREATED        CREATED BY                                     SIZE                COMMENT
   dbf995fc07ff  3 minutes ago  /bin/sh -c #(nop)  CMD ["/bin/sh" "-c" "/a...  0B
   bd09118bcef6  5 minutes ago  /bin/sh -c #(nop) COPY dir:35a7eb158c1504e...  100B
   31005225a745  3 months ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]           0B
   <missing>     3 months ago   /bin/sh -c mkdir -p /run/systemd && echo '...  7B
   <missing>     3 months ago   /bin/sh -c sed -i 's/^#\s*\(deb.*universe\...  2.78kB
   <missing>     3 months ago   /bin/sh -c rm -rf /var/lib/apt/lists/*         0B
   <missing>     3 months ago   /bin/sh -c set -xe   && echo '#!/bin/sh' >...  745B
   <missing>     3 months ago   /bin/sh -c #(nop) ADD file:eef57983bd66e3a...  103MB
   ```
   可以看到，除了第二个镜像的顶层之外，所有的层都是相同的。这些相同的层在两个镜像中共享，
   并且在`/var/lib/docker/`中只存储一次。新的层实际上不占用任何空间，因它不会更改任何文件，只能运行命令。

### 复制机制使得容器更高效
当你运行一个容器时，一个非常小(thin)的可写容器层将被添加到其他层之上，容器对文件系统的任何变动都将存储在此，
容器未改变的任何文件都不会复制到该层，这意味着可写层会尽可能的小。

当容器中一个文件被修改时，存储驱动执行一个CoW操作，具体步骤由存储驱动决定。
对默认的`aufs`、`overlay`与`overlay2`驱动来说，CoW操作将会遵循以下大致序列：

+ 搜索要更新的文件的镜像图层，该过程从最新的层级开始，逐层搜索直到最下层。
  当找到目标时，将会添加一个缓存为后面的操作提速。
+ 在找到该文件的层，对找到的文件的第一个副本执行`copy_up`的操作，复制文件到容器的可写层。
+ 任何的变更操作都作用在该文件的副本上，并且容器不关心底层文件的只读副本。

`Btrfs` `ZFS`和其他存储驱动处理CoW不同于此，你可以稍后在这些驱动的介绍中查阅详细信息。

写入大量数据的容器将会占消耗更多的空间，这是因为大多数写入操作位于容器写入层。
> __注__: 对于大量写入的应用，你不应该将数据存储在容器中，而应使用Docker volumes。
  它们独立于运行中的容器并有着高效的I/O设计。此外，volumes可以在多个容器之间共享且不会增加容器可写层的大小。

`copy_up`操作将会带来明显的性能开销，大小因不同的存储驱动而异。大文件、大量的层以及深目录影响明显。
不过也不必担忧，由于每个`copy_up`操作只会发生在文件第一次修改之时，所以性能开销缓解了许多。

以下程序启动5个基于之前创建的`acme/my-final-img:1.0`镜像启动5个容器来验证CoW。
> 该程序不能在Docker for Mac与Docker for Windows上运行。

1. 在Docker主机上运行以下`docker run`命令，最后显示的字符为每个容器的ID。
   ```bash
   $ docker run -dit --name my_container_1 acme/my-final-image:1.0 bash \
     && docker run -dit --name my_container_2 acme/my-final-image:1.0 bash \
     && docker run -dit --name my_container_3 acme/my-final-image:1.0 bash \
     && docker run -dit --name my_container_4 acme/my-final-image:1.0 bash \
     && docker run -dit --name my_container_5 acme/my-final-image:1.0 bash

     c36785c423ec7e0422b2af7364a7ba4da6146cbba7981a0951fcc3fa0430c409
     dcad7101795e4206e637d9358a818e5c32e13b349e62b00bf05cd5a4343ea513
     1e7264576d78a3134fbaf7829bc24b1d96017cf2bc046b7cd8b08b5775c33d0c
     38fa94212a419a082e6a6b87a8e2ec4a44dd327d7069b85892a707e3fc818544
     1a174fc216cccf18ec7d4fe14e008e30130b11ede0f0f94a87982e310cf2e765
   ```
2. 运行`docker ps`命令确定5个容器已经运行
   ```bash
   CONTAINER ID  IMAGE                     COMMAND  CREATED              STATUS             PORTS   NAMES
   1a174fc216cc  acme/my-final-image:1.0   "bash"   About a minute ago   Up About a minute          my_container_5
   38fa94212a41  acme/my-final-image:1.0   "bash"   About a minute ago   Up About a minute          my_container_4
   1e7264576d78  acme/my-final-image:1.0   "bash"   About a minute ago   Up About a minute          my_container_3
   dcad7101795e  acme/my-final-image:1.0   "bash"   About a minute ago   Up About a minute          my_container_2
   c36785c423ec  acme/my-final-image:1.0   "bash"   About a minute ago   Up About a minute          my_container_1
   ```
3. 列出本地存储区域内容
   ```bash
   sudo ls /var/lib/docker/containers
   1a174fc216cccf18ec7d4fe14e008e30130b11ede0f0f94a87982e310cf2e765
   1e7264576d78a3134fbaf7829bc24b1d96017cf2bc046b7cd8b08b5775c33d0c
   38fa94212a419a082e6a6b87a8e2ec4a44dd327d7069b85892a707e3fc818544
   c36785c423ec7e0422b2af7364a7ba4da6146cbba7981a0951fcc3fa0430c409
   dcad7101795e4206e637d9358a818e5c32e13b349e62b00bf05cd5a4343ea513
   ```
4. 查看其大小
   ```bash
   $ sudo du -sh /var/lib/docker/containers/*

   32K  /var/lib/docker/containers/1a174fc216cccf18ec7d4fe14e008e30130b11ede0f0f94a87982e310cf2e765
   32K  /var/lib/docker/containers/1e7264576d78a3134fbaf7829bc24b1d96017cf2bc046b7cd8b08b5775c33d0c
   32K  /var/lib/docker/containers/38fa94212a419a082e6a6b87a8e2ec4a44dd327d7069b85892a707e3fc818544
   32K  /var/lib/docker/containers/c36785c423ec7e0422b2af7364a7ba4da6146cbba7981a0951fcc3fa0430c409
   32K  /var/lib/docker/containers/dcad7101795e4206e637d9358a818e5c32e13b349e62b00bf05cd5a4343ea513
   ```
   每个容器在文件系统中只占用32k空间

CoW不仅节省空间，也可以减少启动时间。当你启动一个(或多个依赖于同一镜像的)容器时，Docker只需要创建容器可写层。

如果Docker在每次启动时都要制作底层镜像堆栈的整个副本，则容器启动时间和磁盘占用量将会显著增加。
这与虚拟机运行方式类似：每个虚拟机都有一个或多个虚拟磁盘。

# 数据卷与存储驱动
容器被删除时，任何没有写入数据卷的数据都会被删除。数据卷是Docker主机文件系统直接挂载到容器上的一个目录或文件。
数据卷不受存储驱动控制，对数据卷的读取和写入会绕开存储驱动，直接使用主机原生操作。
你可以挂载任意数量数据卷到容器上，多个容器也可以共享一个或多个数据卷。

下图展示了单个Docker主机运行两个容器的情形，每个容器存在于本地存储区域(/var/lib/docker/...)中，
在主机上还有一个共享数据卷直接挂载到两个容器上，地址为`/data`。

![shared-volume.jpg](https://raw.githubusercontent.com/CoinXu/blog/master/docker/shared-volume.jpg)

数据卷位于Docker主机本地存储区域之外，进一步增强了与存储驱动控制的独立性。当一个容器被删除时，
任何存储在数据卷中的数据仍然存在于Docker主机上。

数据卷更详细介绍，请看[管理容器数据](https://docs.docker.com/engine/tutorials/dockervolumes/)
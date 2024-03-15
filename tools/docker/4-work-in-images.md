# 书写Dockerfile最佳实践
Docker可以从Dockerfile中读取指令自动构建镜像，
Dockerfile是一个包含了创建镜像所有指令的文本文件，指令按照顺序排列。
Dockerfile遵循一定的格式并使用一组约定的指令，你可以在[Dockerfile参考](./4-1-dockerfile-reference.md)
页学习基础知识。如果你之前没有写过Dockerfile，建议你从那里开始。

本文件包含了Docker公司及Docker社区为创建易用、高效的Dockerfile所建议的最佳实践与方法。
我们强烈建议你遵循以下建议（事实上，你如果你创建一个官方镜像，你必须采用这些实践）。

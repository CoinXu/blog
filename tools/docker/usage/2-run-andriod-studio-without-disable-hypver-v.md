# 同时运行Hyper-V与Android Studio
如果你的Docker运行在windows 10上并基于Hyper-V程序。此时要进行Android开发，你可能会遇到小小的麻烦。

在Android Studio中运行安卓模拟器的时候，需要禁用Hypver-V并重启。因为Goolge安卓模拟器使用了Intel CPU的HAXM (Hardware Accelerated Execution Manager)，但Hyper-V使用了CPU虚拟化扩展，不知道为什么，二者不能同时存在，在PC启动时只能选择其中的一个。

Android Studio提示如下图：
![android-emulator-incompatible-with-hyper-v.png](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/android-emulator-incompatible-with-hyper-v.png)

要求关掉hypervisorlaunchtype并重启：
![set-hypervisorlaunchtype-of.png](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/set-hypervisorlaunchtype-of.png)

### 总不能我要提交代码的时候(git在docker容器中)又换回Docker，重启一次PC吧？

# 解决方案
Window下除了使用Vistua Studio的模拟器外，还可以选择由微软官方提供的[Visual Studio Emulator for Android](https://www.visualstudio.com/vs/msft-android-emulator/)，传说性能更好。

下载安装并启动一个Device，点击Android Studio上的运行按钮，然后就可能会发现，弹出的设备选择面板上并没有你已启动的设备....
![connected-devices-none](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/connected-devices-none.png)

一番搜索之后发现了该篇[博客](https://www.clearlyagileinc.com/blog/using-the-visual-studio-android-emulator-with-android-studio)，
其文表明Visual Studio Emulator for Android安装后以`C:\Program Files (x86)\Android\android-sdk`为默认的Andriod SDK路径，而Android Studio默认是将SDK下载到`C:\Users\[USER]\AppData\Local\Android\Sdk`。解决办法是修改windows注册表：`HKEY_LOCAL_MACHINE > SOFTWARE > WOW6432Node > Android SDK Tools`。

打开注册表，并导航到上面的目录，添加`Android SDK Tools`：
![connected-devices-none](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/reg-androiod-sdk-tools.png)

再启动Visual Studio Emulator for Android上的设备、在Android Studio上点击运行按钮，弹出的设备选择面板上应该就有启动的设备了。
![android-studio-emulator-in-connected-list](https://raw.githubusercontent.com/CoinXu/blog/master/docker/usage/android-studio-emulator-in-connected-list.png)







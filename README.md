# 热更新插件
该插件是简单的cordova插件，通过该插件我们可以实现简单的cordova应用的前端页面的更新。
## 安装
$ cordova plugin add com.mLink.cordova.plugin.hotUpdate
## 注意事项
##### ·该插件只可以更新www目录下的文件
##### ·该插件并不会主动请求更新，而是需要主动调用jsAPI然后传入www资源的服务地址，然后插件即可下载该url下的www资源，将其保存至沙河路径并且重定向gaiapp的起始页index.html
##### ·一旦有过一次www资源的更新，以后的每次app启动后的起始页都将是存储在沙盒路径下的index.html。当app版本升级后的第一次启动会将旧版本app沙盒路径下保存的www资源删除，然后加载appbundle下的www资源
##### ·该插件中的iOS部分引用了AFNetWorking和ZipArchive两个第三方框架，如果项目中本来就已经引入了这两个框架，则在安装插件的过程总有可能会出现问题。
## 插件API
### hotUpdate.downLoadAndUpdateHTMLResouce(args,suceess,error)
#### 描述
下载HTML资源并且更新app
#### 参数
##### ·args: String- html资源的url地址
##### ·suceess：Function- api调用成功的回调
##### ·error：Function- api调用失败的回调

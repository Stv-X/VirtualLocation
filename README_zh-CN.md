# Virtual Location

Virtual Location是一个 macOS 应用程序，允许用户在连接的 iOS 设备上模拟 GPS 位置。该应用程序采用 SwiftUI 和 SwiftData 构建，提供了管理设备连接、位置模拟和位置历史记录的直观界面。

## 功能特性

- **设备管理**: 自动检测通过 USB 或无线连接的 iOS 设备
- **地图界面**: 具有搜索和选择功能的交互式地图
- **位置模拟**: 使用 pymobiledevice3 在 iOS 设备上设置自定义 GPS 坐标
- **位置历史**: 存储和管理收藏位置和最近的位置记录
- **坐标输入**: 支持地图选择和手动坐标输入
- **隧道连接**: 与 iOS 设备建立安全连接以进行位置模拟

## 架构

该应用程序遵循现代化的 SwiftUI 架构，包含以下主要组件：

- **VirtualLocationViewModel**: 中心视图模型，管理地图状态、位置搜索和位置记录
- **DeviceConnectionManager**: 处理设备发现、隧道建立和位置模拟命令
- **DeviceCommandRunner**: 通过 Python 子进程执行 pymobiledevice3 命令
- **CLIResolver**: 管理 Python 环境解析
- **LocationRecord**: 用于存储位置历史和收藏夹的 SwiftData 模型
- **Views**: 基于 SwiftUI 的用户界面，包括侧边栏导航、地图视图和检查器面板

## 依赖项

- **pymobiledevice3**: 用于 iOS 设备通信的 Python 库（包含在项目捆绑包中）
- **MapKit**: Apple 的地图框架，用于位置服务
- **SwiftUI & SwiftData**: Apple 的现代 UI 和数据持久化框架

## 安装

1. 克隆或下载此仓库
2. 在 Xcode 中打开项目
3. 构建并运行应用程序

该应用程序捆绑了一个包含 pymobiledevice3 的 Python 虚拟环境，因此无需额外安装 Python。

## 使用方法

1. 通过 USB 将 iOS 设备连接到 Mac
2. 启动 Virtual Location
3. 应用程序将自动检测连接的设备
4. 在地图上搜索或手动选择位置
5. 单击"发送位置"按钮将虚拟位置设置到您的设备上
6. 位置记录会自动保存以供将来参考

## 安全提示

该应用程序需要管理员权限来建立用于位置模拟的设备隧道。所有设备通信都在您的 Mac 和连接的 iOS 设备之间本地进行。

## 故障排除

- 如果设备未出现，请确保正确的电缆连接和设备信任
- 某些 iOS 版本可能需要额外的设备设置才能进行位置模拟
- 如果位置模拟停止响应，请重启两个设备
- 查看检查器面板了解连接状态和错误消息

## 技术详情

该应用程序利用 pymobiledevice3 的 DVT（开发者工具）框架与 iOS 设备通信并模拟位置更改。使用 RSD（远程服务发现）协议建立安全隧道，这需要通过 sudo 提升权限。

## 贡献

欢迎贡献！请随时提交拉取请求。对于重大更改，请先开 issue 讨论您想要更改的内容。

## 许可证

本项目根据 MIT 许可证授权 - 详见 LICENSE 文件。

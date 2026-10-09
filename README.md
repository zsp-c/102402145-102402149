# 校园失物招领平台

一个面向校园场景的失物招领 App，后端基于 Spring Boot 3，前端基于 Flutter。

## 功能模块

- **用户系统**：学号注册登录、JWT 鉴权、个人资料编辑、头像上传
- **物品发布**：寻物启事 / 招领启事发布，支持多图上传（阿里云 OSS）
- **物品浏览**：首页列表、分类筛选、关键词搜索、搜索历史
- **物品详情**：浏览量统计、标记已解决（已找回 / 已归还）
- **我的发布**：累计发布、进行中、已找回统计
- **消息通知**：认领联系消息、SSE 实时推送、全部已读、一键删除已读

## 技术栈

### 后端（campus_lost_found_platform）

| 技术 | 说明 |
|------|------|
| Spring Boot 3.2.5 | 主框架 |
| Java 21 | 运行环境 |
| MyBatis-Plus 3.5.5 | ORM 框架 |
| MySQL 8.x | 关系型数据库 |
| Druid | 数据库连接池 |
| Redis | 缓存（已引入，按需使用） |
| JJWT 0.11.5 | JWT 令牌签发与校验 |
| 阿里云 OSS SDK 3.17.4 | 对象存储（图片） |
| Knife4j 4.4.0 | 接口文档（Swagger） |
| Lombok | 简化实体类代码 |

### 前端（campus_lost_found_client）

| 技术 | 说明 |
|------|------|
| Flutter 3.x | 跨平台 UI 框架 |
| Dart | 编程语言 |
| http | 网络请求 |
| ValueNotifier / ValueListenableBuilder | 状态管理 |

## 项目结构

```
102402145-102402149/
├── campus_lost_found_platform/      # 后端（Maven 多模块）
│   ├── campus-common/               # 公共模块：工具类、异常、常量、配置属性
│   ├── campus-pojo/                 # 数据模型：entity、dto、vo
│   ├── campus-server/               # 服务端：controller、service、mapper、配置
│   │   └── src/main/resources/
│   │       ├── application.yaml     # 主配置（引用 dev 配置）
│   │       └── application-dev.yml  # 开发环境配置（需自行创建，见下文）
│   ├── sql/                         # 数据库脚本
│   │   ├── campus_lost_found.sql
│   │   └── search_history.sql
│   └── pom.xml
└── campus_lost_found_client/        # 前端（Flutter）
    ├── lib/
    │   ├── models/                  # 数据模型
    │   ├── screens/                 # 页面
    │   ├── services/                # 接口调用
    │   ├── data/                    # 全局状态
    │   └── utils/                   # 工具类
    └── pubspec.yaml
```

## 环境要求

- JDK 21
- Maven 3.6+
- MySQL 8.x
- Redis（可选，项目已引入依赖）
- Flutter 3.x（前端）
- 阿里云 OSS Bucket（用于图片存储）

## 快速开始

### 一、数据库初始化

1. 创建数据库：

```sql
CREATE DATABASE campus_lost_found DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. 依次执行 `campus_lost_found_platform/sql/` 下的 SQL 脚本：
   - `campus_lost_found.sql` —— 建表（user、item、item_image、claim）
   - `search_history.sql` —— 搜索历史表

### 二、后端配置

> **重要**：`application-dev.yml` 包含数据库密码、OSS 密钥等敏感信息，**不应提交到版本库**。请自行创建该文件并填入你自己的配置。

在 `campus-server/src/main/resources/` 下新建 `application-dev.yml`，内容如下：

```yaml
campus:
  # JWT 配置
  jwt:
    user-secret-key: 你自己的JWT密钥（至少32位，建议随机字符串）
    user-ttl: 7200000              # 令牌有效期（毫秒），此处为 2 小时
    user-token-name: token         # 前端请求头名称

  # 数据源配置
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    host: localhost
    port: 3306
    database: campus_lost_found
    username: 你的数据库用户名
    password: 你的数据库密码

  # 阿里云 OSS 配置
  alioss:
    endpoint: oss-cn-你的区域.aliyuncs.com
    accessKeyId: 你的AccessKeyId
    accessKeySecret: 你的AccessKeySecret
    bucketName: 你的Bucket名称
```

> **OSS 说明**：Bucket 权限建议设置为**私有**，项目通过 `AliOssUtil.signUrl()` 生成临时签名 URL 访问图片，无需将对象设为公共读。

### 三、启动后端

```bash
cd campus_lost_found_platform
mvn clean install -DskipTests
mvn spring-boot:run -pl campus-server
```

服务启动后：
- 接口地址：`http://localhost:8080`
- 接口文档（Knife4j）：`http://localhost:8080/doc.html`

### 四、前端配置

修改 `campus_lost_found_client/lib/services/api_service.dart` 中的后端地址：

```dart
class ApiConfig {
  // Android 模拟器访问宿主机用 10.0.2.2；真机调试改为电脑局域网 IP
  static const String baseUrl = 'http://10.0.2.2:8080';
}
```

### 五、启动前端

```bash
cd campus_lost_found_client
flutter pub get
flutter run
```

## 数据库表说明

| 表名 | 说明 |
|------|------|
| `user` | 用户表（学号、密码哈希、昵称、头像、学院、年级、统计数据） |
| `item` | 物品表（寻物/招领、状态、分类、描述、封面图） |
| `item_image` | 物品图片表（一个物品多张图，sort_order=0 为封面） |
| `claim` | 认领消息表（发送者、接收者、消息内容、已读状态） |
| `search_history` | 搜索历史表（按用户隔离，同关键词只保留最新） |

物品状态：`SEEKING`（寻找中）/ `PENDING`（待认领）/ `FOUND`（已找回）/ `CLAIMED`（已归还）。已解决的物品不会出现在首页列表和搜索结果中。

## 接口鉴权

除登录、注册外，所有接口需在请求头携带 `token`：

```
token: <JWT令牌>
```

## 注意事项

1. **密钥安全**：`application-dev.yml` 中的数据库密码、OSS AccessKey 等属于敏感信息，切勿提交到公开仓库。建议将该文件加入 `.gitignore`。
2. **OSS 签名 URL**：图片访问使用临时签名 URL，默认有效期内有效，不要在代码中硬编码签名 URL。
3. **端口占用**：后端默认 8080 端口，如被占用可在 `application.yaml` 中修改 `server.port`。
4. **MySQL 时区**：连接串已配置 `serverTimezone=Asia/Shanghai`，确保数据库时区一致。
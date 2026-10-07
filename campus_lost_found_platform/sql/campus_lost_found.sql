-- ============================================================
--  校园失物招领平台 —— MySQL 建表脚本
--  字符集 utf8mb4（需要存 emoji，如前端热词里的 🎧）
--  约定：时间字段统一 create_time / update_time
--        逻辑删除只用于 item 表（用户发的信息可以删，用户本身不删）
--        物品分类是固定 8 类，不单独建表，item 直接存分类名称
-- ============================================================

CREATE DATABASE IF NOT EXISTS `campus_lost_found`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE `campus_lost_found`;

-- ------------------------------------------------------------
-- 1. 用户 user
--    对应接口文档 /auth/register、/auth/login、/users/{userId}
--    注意：password 只进不出，任何 VO 都不要把它返回给前端
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`
(
    `user_id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户 id',
    `student_id`      VARCHAR(32)     NOT NULL COMMENT '学号，登录账号',
    `password`        VARCHAR(100)    NOT NULL COMMENT 'BCrypt 密文（60 字符）',
    `nickname`        VARCHAR(32)     NOT NULL COMMENT '昵称',
    `avatar`          VARCHAR(255)             DEFAULT NULL COMMENT '头像 url',
    `phone`           VARCHAR(20)              DEFAULT NULL COMMENT '手机号，认领时展示给发布者',
    `college`         VARCHAR(32)              DEFAULT NULL COMMENT '学院',
    `grade`           VARCHAR(16)              DEFAULT NULL COMMENT '年级，如「大二」',
    `total_publish`   INT             NOT NULL DEFAULT 0 COMMENT '累计发布数',
    `total_completed` INT             NOT NULL DEFAULT 0 COMMENT '累计已找回/已归还数',
    `status`          TINYINT         NOT NULL DEFAULT 1 COMMENT '账号状态：1-正常 0-禁用',
    `create_time`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `update_time`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_user_student_id` (`student_id`),
    KEY `idx_user_phone` (`phone`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='用户';

-- ------------------------------------------------------------
-- 2. 失物/招领信息 item
--    对应接口文档 /items、/items/{id}
--    type     : LOST-寻物 / FOUND-招领
--    status   : SEEKING-寻找中 PENDING-待认领 FOUND-已找回 CLAIMED-已归还
--    category : 固定 8 类，取值见 CategoryConstant
--               证件卡类 / 数码电子 / 钥匙门卡 / 箱包
--               水杯水壶 / 手表饰品 / 耳机音频 / 其他物品
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `item`;
CREATE TABLE `item`
(
    `item_id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '物品 id',
    `user_id`           BIGINT UNSIGNED NOT NULL COMMENT '发布者 id',
    `type`              VARCHAR(8)      NOT NULL COMMENT 'LOST-寻物 / FOUND-招领',
    `status`            VARCHAR(16)     NOT NULL DEFAULT 'SEEKING' COMMENT 'SEEKING/PENDING/FOUND/CLAIMED',
    `name`              VARCHAR(64)     NOT NULL COMMENT '物品名称',
    `description`       VARCHAR(1000)            DEFAULT NULL COMMENT '详细描述',
    `category`          VARCHAR(32)              DEFAULT NULL COMMENT '物品分类名称',
    `location`          VARCHAR(128)             DEFAULT NULL COMMENT '丢失/拾取地点',
    `image`             VARCHAR(255)             DEFAULT NULL COMMENT '封面图 url（多图见 item_image）',
    `view_count`        INT             NOT NULL DEFAULT 0 COMMENT '浏览量',
    `find_or_lost_time` DATETIME                 DEFAULT NULL COMMENT '丢失/拾取时间',
    `is_deleted`        TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删 1-已删',
    `create_time`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    `update_time`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`item_id`),
    KEY `idx_item_user` (`user_id`),
    KEY `idx_item_category` (`category`),
    KEY `idx_item_type_status` (`type`, `status`),
    -- 首页/列表按时间倒序翻页
    KEY `idx_item_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='失物招领信息';

-- ------------------------------------------------------------
-- 3. 物品图片 item_image
--    一个物品多张图（前端的详情页是图片轮播）。
--    item.image 存封面（第一张）做列表查询，这里是完整图集。
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `item_image`;
CREATE TABLE `item_image`
(
    `image_id`    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '图片 id',
    `item_id`     BIGINT UNSIGNED NOT NULL COMMENT '物品 id',
    `url`         VARCHAR(255)    NOT NULL COMMENT '图片 url',
    `sort_order`  INT             NOT NULL DEFAULT 0 COMMENT '排序，0 为封面',
    `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`image_id`),
    KEY `idx_item_image_item` (`item_id`, `sort_order`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='物品图片';

-- ------------------------------------------------------------
-- 4. 认领消息 claim  ★ 消息入库 + SSE 推送的核心表
--
--    设计要点：
--    (1) receiver_id 冗余存一份。
--        消息路由到谁，SSE 推送时直接按 receiver_id 找连接，
--        不用回表 join item 才知道发布者是谁。
--    (2) 入库是「事实来源」，SSE 只是「尽力而为的实时通道」。
--        用户离线时推送失败无所谓：消息已在库，
--        客户端重新连上 SSE 后拉一次未读即可，不会丢消息。
--    (3) read_status 支撑未读红点；配合 receiver_id 建复合索引，
--        「我的消息列表」和「未读数」两条查询都走索引。
--    (4) 不设「同意/拒绝」状态：消息能送到对方就够，认领结果线下自行沟通。
--        所以 claim 表只记录「谁在什么时间、针对哪件物品、给谁发了什么」。
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `claim`;
CREATE TABLE `claim`
(
    `claim_id`      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '消息 id',
    `item_id`       BIGINT UNSIGNED NOT NULL COMMENT '关联的物品 id',
    `sender_id`     BIGINT UNSIGNED NOT NULL COMMENT '发送者 id（认领/提供线索的人）',
    `receiver_id`   BIGINT UNSIGNED NOT NULL COMMENT '接收者 id（物品发布者），SSE 按此路由',
    `msg_type`      VARCHAR(16)     NOT NULL DEFAULT 'CONTACT' COMMENT 'CONTACT-认领联系 / SYSTEM-系统通知',
    `claim_content` VARCHAR(500)    NOT NULL COMMENT '消息内容',
    `read_status`   TINYINT         NOT NULL DEFAULT 0 COMMENT '已读状态：0-未读 1-已读',
    `create_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    `update_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`claim_id`),
    -- 收件箱列表、未读数统计
    KEY `idx_claim_receiver_read` (`receiver_id`, `read_status`, `create_time`),
    -- 「我发出的」消息
    KEY `idx_claim_sender` (`sender_id`, `create_time`),
    -- 按物品查全部认领线索
    KEY `idx_claim_item` (`item_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='认领消息（消息入库 + SSE 推送）';

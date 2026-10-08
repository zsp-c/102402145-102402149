-- ============================================================
--  校园失物招领平台 —— MySQL 建表脚本
--  字符集 utf8mb4（需要存 emoji）
--  时间字段统一 create_time / update_time
--  逻辑删除仅用于 item 表
-- ============================================================

CREATE DATABASE IF NOT EXISTS `campus_lost_found`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE `campus_lost_found`;

-- ------------------------------------------------------------
-- 1. 用户表 user
--    对应后端实体 com.zsp.campus.entity.User
--    password 为 BCrypt 密文，序列化时 @JsonIgnore 不返回前端
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user`
(
    `user_id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户 id',
    `student_id`      VARCHAR(32)     NOT NULL COMMENT '学号，登录账号',
    `password`        VARCHAR(100)    NOT NULL COMMENT 'BCrypt 密文',
    `nickname`        VARCHAR(32)     NOT NULL COMMENT '昵称',
    `avatar`          VARCHAR(255)             DEFAULT NULL COMMENT '头像 url',
    `phone`           VARCHAR(20)              DEFAULT NULL COMMENT '手机号',
    `college`         VARCHAR(32)              DEFAULT NULL COMMENT '学院',
    `grade`           VARCHAR(16)              DEFAULT NULL COMMENT '年级',
    `total_publish`   INT             NOT NULL DEFAULT 0 COMMENT '累计发布数',
    `total_completed` INT             NOT NULL DEFAULT 0 COMMENT '累计已找回/已归还数',
    `status`          TINYINT         NOT NULL DEFAULT 1 COMMENT '账号状态：1-正常 0-禁用',
    `create_time`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `update_time`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `uk_user_student_id` (`student_id`),
    KEY `idx_user_phone` (`phone`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='用户表';

-- ------------------------------------------------------------
-- 2. 失物/招领信息表 item
--    对应后端实体 com.zsp.campus.entity.Item
--    type     : LOST-寻物 / FOUND-招领
--    status   : SEEKING-寻找中 PENDING-待认领 FOUND-已找回 CLAIMED-已归还
--    image    : 封面图 url（列表页用，多图存 item_image 表）
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
    `image`             VARCHAR(255)             DEFAULT NULL COMMENT '封面图 url',
    `view_count`        INT             NOT NULL DEFAULT 0 COMMENT '浏览量',
    `find_or_lost_time` DATETIME                 DEFAULT NULL COMMENT '丢失/拾取时间',
    `is_deleted`        TINYINT         NOT NULL DEFAULT 0 COMMENT '逻辑删除：0-未删 1-已删',
    `create_time`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    `update_time`       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`item_id`),
    KEY `idx_item_user` (`user_id`),
    KEY `idx_item_category` (`category`),
    KEY `idx_item_type_status` (`type`, `status`),
    KEY `idx_item_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='失物招领信息表';

-- ------------------------------------------------------------
-- 3. 物品图片表 item_image
--    一个物品多张图，item.image 存封面（第一张），此处存完整图集
--    对应 ItemDto.images 列表
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
  DEFAULT CHARSET = utf8mb4 COMMENT ='物品图片表';

-- ------------------------------------------------------------
-- 4. 认领消息表 claim
--    对应后端实体 com.zsp.campus.entity.Claim
--    消息入库是事实来源，SSE 只是实时推送通道
--    receiver_id 冗余存储，SSE 按此字段路由
--    read_status 支撑未读红点
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `claim`;
CREATE TABLE `claim`
(
    `claim_id`      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '消息 id',
    `item_id`       BIGINT UNSIGNED NOT NULL COMMENT '关联的物品 id',
    `sender_id`     BIGINT UNSIGNED NOT NULL COMMENT '发送者 id',
    `receiver_id`   BIGINT UNSIGNED NOT NULL COMMENT '接收者 id（物品发布者）',
    `msg_type`      VARCHAR(16)     NOT NULL DEFAULT 'CONTACT' COMMENT 'CONTACT-认领联系 / SYSTEM-系统通知',
    `claim_content` VARCHAR(500)    NOT NULL COMMENT '消息内容',
    `read_status`   TINYINT         NOT NULL DEFAULT 0 COMMENT '已读状态：0-未读 1-已读',
    `create_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    `update_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`claim_id`),
    KEY `idx_claim_receiver_read` (`receiver_id`, `read_status`, `create_time`),
    KEY `idx_claim_sender` (`sender_id`, `create_time`),
    KEY `idx_claim_item` (`item_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='认领消息表';

-- ============================================================
--  初始化测试数据
-- ============================================================

-- 默认测试账号：学号 00000，密码 123456（BCrypt 哈希）
INSERT INTO `user` (`user_id`, `student_id`, `password`, `nickname`, `avatar`, `phone`, `college`, `grade`, `total_publish`, `total_completed`, `status`)
VALUES (1, '00000', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '测试用户', '', '13800138000', '计算机学院', '大三', 0, 0, 1);
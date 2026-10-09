-- ============================================================
--  搜索模块 —— 搜索历史表 search_history
--  对应后端实体 com.zsp.campus.entity.SearchHistory
--  （history_id 与表结构在这里补，未改动 campus_lost_found.sql）
--  每个用户各存各的；同一关键词重复搜索只更新搜索时间，不产生重复行
--  字符集 utf8mb4，时间字段统一 create_time
-- ============================================================

USE `campus_lost_found`;

DROP TABLE IF EXISTS `search_history`;
CREATE TABLE `search_history`
(
    `history_id`  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '历史 id',
    `user_id`     BIGINT UNSIGNED NOT NULL COMMENT '用户 id',
    `keyword`     VARCHAR(64)     NOT NULL COMMENT '搜索关键词',
    `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '最近一次搜索时间',
    PRIMARY KEY (`history_id`),
    UNIQUE KEY `uk_history_user_keyword` (`user_id`, `keyword`),
    KEY `idx_history_user_time` (`user_id`, `create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4 COMMENT ='搜索历史表';

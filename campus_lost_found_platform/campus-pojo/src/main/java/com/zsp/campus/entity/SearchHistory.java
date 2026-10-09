package com.zsp.campus.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 搜索历史实体类，对应表 search_history
 *
 * <p>搜索历史按用户隔离，每个用户各存各的。同一关键词只保留最新一次，
 * 重复搜索相当于把该词「置顶」（由 SearchHistoryServiceImpl 先删后插实现）。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@TableName("search_history")
public class SearchHistory implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /** 历史 id */
    @TableId(type = IdType.AUTO)
    private Long historyId;

    /** 用户 id，关联 user 表 */
    private Long userId;

    /** 搜索关键词 */
    private String keyword;

    /** 最近一次搜索时间 */
    private LocalDateTime createTime;
}

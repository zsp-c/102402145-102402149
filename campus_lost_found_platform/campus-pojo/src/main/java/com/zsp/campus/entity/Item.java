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
 * 失物招领信息实体类，对应表 item
 * 多张图片存在 item_image 表，这里的 image 是封面图（列表页用）
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@TableName("item")
public class Item implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /** 物品 id */
    @TableId(type = IdType.AUTO)
    private Long itemId;

    /** 发布者 id，关联 user 表 */
    private Long userId;

    /** LOST-寻物 / FOUND-招领 */
    private String type;

    /** SEEKING-寻找中 / PENDING-待认领 / FOUND-已找回 / CLAIMED-已归还 */
    private String status;

    /** 物品名称 */
    private String name;

    /** 物品描述 */
    private String description;

    /** 物品分类名称，固定 8 类，取值见 CategoryConstant */
    private String category;

    /** 丢失 / 拾取地点 */
    private String location;

    /** 封面图 url */
    private String image;

    /** 浏览量 */
    private Integer viewCount;

    /** 丢失 / 拾取时间 */
    private LocalDateTime findOrLostTime;

    /** 逻辑删除：0-未删 1-已删 */
    private Integer isDeleted;

    /** 发布时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
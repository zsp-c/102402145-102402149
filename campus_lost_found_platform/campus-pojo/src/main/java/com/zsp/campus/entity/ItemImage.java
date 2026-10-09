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
 * 物品图片实体类，对应表 item_image。
 * 一个物品可有多张图，item.image 存封面（第一张），此处存完整图集。
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@TableName("item_image")
public class ItemImage implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /** 图片 id */
    @TableId(type = IdType.AUTO)
    private Long imageId;

    /** 物品 id */
    private Long itemId;

    /** 图片 url */
    private String url;

    /** 排序，0 为封面 */
    private Integer sortOrder;

    /** 创建时间 */
    private LocalDateTime createTime;
}
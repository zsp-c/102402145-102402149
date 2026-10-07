package com.zsp.campus.dto;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 物品发布 dto
 */
@Data
public class ItemDto {
    /** LOST-寻物 / FOUND-招领 */
    private String type;

    /** 物品名称 */
    private String name;

    /** 物品描述 */
    private String description;

    /** 物品分类名称，固定 8 类，取值见 CategoryConstant */
    private String category;

    /** 丢失 / 拾取地点 */
    private String location;

    /**
     * 图片 url 列表。
     * 详情页是图片轮播，所以要支持多张；列表页取第一张作封面存进 item.image。
     */
    private List<String> images;

    /** 丢失 / 拾取时间 */
    private LocalDateTime findOrLostTime;
}

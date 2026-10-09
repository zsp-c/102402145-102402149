package com.zsp.campus.vo;

import com.zsp.campus.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 物品查询回显 vo
 *
 * <p>字段与 item 表一致，另带一份发布者信息（关联查询得到）和完整图片列表。
 * 注意：User 里有手机号和学号，如果不想让前端看到，后续应换成只含
 * 昵称 / 学院 / 年级的 PublisherVo。
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ItemVo {
    /** 物品 id */
    private Long itemId;

    /** LOST-寻物 / FOUND-招领 */
    private String type;

    /** SEEKING / PENDING / FOUND / CLAIMED */
    private String status;

    /** 物品名称 */
    private String name;

    /** 物品描述 */
    private String description;

    /** 物品分类名称 */
    private String category;

    /** 丢失 / 拾取地点 */
    private String location;

    /** 封面图 url */
    private String image;

    /** 完整图片列表（列表页只含封面，详情页含全部） */
    private List<String> images;

    /** 浏览量 */
    private Integer viewCount;

    /** 丢失 / 拾取时间 */
    private LocalDateTime findOrLostTime;

    /** 发布时间 */
    private LocalDateTime createTime;

    /** 发布者信息 */
    private User user;
}
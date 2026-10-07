package com.zsp.campus.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户实体类，对应表 user
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class User implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /** 用户 id */
    private Long userId;

    /** 学号，登录账号 */
    private String studentId;

    /**
     * BCrypt 密文。
     * 加 @JsonIgnore 是因为 LoginVo 直接返回了整个 User，
     * 不加会把密码哈希序列化给前端。
     */
    @JsonIgnore
    private String password;

    /** 昵称 */
    private String nickname;

    /** 头像 url */
    private String avatar;

    /** 手机号，认领时随消息展示给物品发布者 */
    private String phone;

    /** 学院 */
    private String college;

    /** 年级，如「大二」 */
    private String grade;

    /** 累计发布数 */
    private Integer totalPublish;

    /** 累计已找回 / 已归还数 */
    private Integer totalCompleted;

    /** 账号状态：1-正常 0-禁用 */
    private Integer status;

    /** 注册时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}

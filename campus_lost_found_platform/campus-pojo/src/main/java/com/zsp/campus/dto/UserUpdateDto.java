package com.zsp.campus.dto;

import lombok.Data;

/**
 * 用户资料更新 DTO。
 * 学号、密码等敏感字段不在此处修改。
 */
@Data
public class UserUpdateDto {
    private String nickname;
    private String avatar;
    private String phone;
    private String college;
    private String grade;
}
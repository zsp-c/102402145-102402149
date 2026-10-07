package com.zsp.campus.dto;

import lombok.Data;

@Data
public class RegisterDto {
    // 头像
    private String avatar;
    // 昵称
    private String nickname;
    private String phone;
    private String studentId;
    private String password;
    //年级
    private String grade;
    //学院
    private String college;
}

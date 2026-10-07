package com.zsp.campus.vo;


import com.zsp.campus.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginVo {
    private String token; //jwt生成的token
    private User user;
}

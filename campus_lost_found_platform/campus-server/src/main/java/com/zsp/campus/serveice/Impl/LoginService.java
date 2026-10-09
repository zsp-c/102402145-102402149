package com.zsp.campus.serveice.impl;

import com.zsp.campus.dto.LoginDto;
import com.zsp.campus.vo.LoginVo;

/**
 * 登录服务
 */
public interface LoginService {

    /**
     * 用户登录
     *
     * @param loginDto 学号 + 密码
     * @return token + 用户信息
     */
    LoginVo login(LoginDto loginDto);
}
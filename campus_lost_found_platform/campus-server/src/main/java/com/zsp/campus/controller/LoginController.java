package com.zsp.campus.controller;

import com.zsp.campus.dto.LoginDto;
import com.zsp.campus.dto.RegisterDto;
import com.zsp.campus.entity.User;
import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.serveice.impl.LoginService;
import com.zsp.campus.serveice.UserService;
import com.zsp.campus.utils.AliOssUtil;
import com.zsp.campus.vo.LoginVo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 鉴权相关接口：登录、注册
 */
@RestController
@Slf4j
@Tag(name = "鉴权模块")
public class LoginController {

    @Autowired
    private LoginService loginService;

    @Autowired
    private UserService userService;

    @Autowired
    private AliOssUtil aliOssUtil;

    /**
     * 用户登录
     */
    @PostMapping("/login")
    @Operation(summary = "用户登录")
    public ApiResponse<LoginVo> login(@RequestBody LoginDto loginDto) {
        log.info("用户登录：{}", loginDto.getStudentId());
        LoginVo loginVo = loginService.login(loginDto);
        signAvatar(loginVo);
        return ApiResponse.success(loginVo);
    }

    /**
     * 用户注册
     */
    @PostMapping("/auth/register")
    @Operation(summary = "用户注册")
    public ApiResponse<Long> register(@RequestBody RegisterDto registerDto) {
        log.info("用户注册：{}", registerDto.getStudentId());
        Long userId = userService.register(registerDto);
        return ApiResponse.success(userId);
    }

    /** 将登录返回的用户头像转为签名URL。 */
    private void signAvatar(LoginVo loginVo) {
        if (loginVo == null) {
            return;
        }
        User user = loginVo.getUser();
        if (user != null && StringUtils.hasText(user.getAvatar())) {
            user.setAvatar(aliOssUtil.signUrl(user.getAvatar()));
        }
    }
}
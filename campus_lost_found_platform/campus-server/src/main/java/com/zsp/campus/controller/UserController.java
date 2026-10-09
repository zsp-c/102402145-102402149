package com.zsp.campus.controller;

import com.zsp.campus.context.BaseContext;
import com.zsp.campus.dto.UserUpdateDto;
import com.zsp.campus.entity.User;
import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.serveice.UserService;
import com.zsp.campus.utils.AliOssUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户相关接口
 */
@RestController
@RequestMapping("/users")
@Slf4j
@Tag(name = "用户模块")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private AliOssUtil aliOssUtil;

    /**
     * 获取当前登录用户信息
     */
    @GetMapping("/me")
    @Operation(summary = "获取当前登录用户信息")
    public ApiResponse<User> me() {
        Long userId = BaseContext.getCurrentId();
        User user = userService.getById(userId);
        signAvatar(user);
        return ApiResponse.success(user);
    }

    /**
     * 修改当前用户资料
     * 可修改字段：昵称、头像、手机号、学院、年级
     */
    @PutMapping("/me")
    @Operation(summary = "修改当前用户资料")
    public ApiResponse<User> updateMe(@RequestBody UserUpdateDto dto) {
        Long userId = BaseContext.getCurrentId();
        log.info("修改当前用户资料，userId={}, dto={}", userId, dto);
        User user = userService.updateUser(userId, dto);
        if (user == null) {
            return ApiResponse.error("用户不存在");
        }
        signAvatar(user);
        return ApiResponse.success(user);
    }

    /**
     * 根据用户 id 查询用户信息
     */
    @GetMapping("/{userId}")
    @Operation(summary = "根据用户 id 查询用户信息")
    public ApiResponse<User> getById(@PathVariable Long userId) {
        User user = userService.getById(userId);
        signAvatar(user);
        return ApiResponse.success(user);
    }

    /**
     * 将用户头像原始URL转换为带签名的临时可访问URL。
     */
    private void signAvatar(User user) {
        if (user != null && user.getAvatar() != null && !user.getAvatar().isEmpty()) {
            user.setAvatar(aliOssUtil.signUrl(user.getAvatar()));
        }
    }
}
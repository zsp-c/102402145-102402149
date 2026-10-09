package com.zsp.campus.serveice;

import com.zsp.campus.dto.RegisterDto;
import com.zsp.campus.dto.UserUpdateDto;
import com.zsp.campus.entity.User;

/**
 * 用户服务
 */
public interface UserService {

    /**
     * 根据 id 查询用户
     */
    User getById(Long userId);

    /**
     * 根据学号查询用户
     */
    User getByStudentId(String studentId);

    /**
     * 用户注册
     *
     * @param registerDto 注册信息
     * @return 新用户 id
     */
    Long register(RegisterDto registerDto);

    /**
     * 更新用户资料
     *
     * @param userId 用户 id
     * @param dto    更新内容
     * @return 更新后的用户
     */
    User updateUser(Long userId, UserUpdateDto dto);
}
package com.zsp.campus.serveice.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.zsp.campus.dto.RegisterDto;
import com.zsp.campus.dto.UserUpdateDto;
import com.zsp.campus.entity.User;
import com.zsp.campus.exception.StudentIdExistException;
import com.zsp.campus.mapper.UserMapper;
import com.zsp.campus.serveice.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 用户服务实现
 */
@Service
@Slf4j
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    private static final BCryptPasswordEncoder PASSWORD_ENCODER = new BCryptPasswordEncoder();

    @Override
    public User getById(Long userId) {
        return userMapper.selectById(userId);
    }

    @Override
    public User getByStudentId(String studentId) {
        return userMapper.selectOne(
                new LambdaQueryWrapper<User>()
                        .eq(User::getStudentId, studentId)
        );
    }

    @Override
    public Long register(RegisterDto registerDto) {
        // 学号唯一性校验
        User exist = getByStudentId(registerDto.getStudentId());
        if (exist != null) {
            throw new StudentIdExistException();
        }

        User user = User.builder()
                .studentId(registerDto.getStudentId())
                .password(PASSWORD_ENCODER.encode(registerDto.getPassword()))
                .nickname(registerDto.getNickname())
                .avatar(registerDto.getAvatar())
                .phone(registerDto.getPhone())
                .college(registerDto.getCollege())
                .grade(registerDto.getGrade())
                .totalPublish(0)
                .totalCompleted(0)
                .status(1)
                .createTime(LocalDateTime.now())
                .updateTime(LocalDateTime.now())
                .build();

        userMapper.insert(user);
        log.info("用户注册成功，userId={}, studentId={}", user.getUserId(), user.getStudentId());
        return user.getUserId();
    }

    @Override
    public User updateUser(Long userId, UserUpdateDto dto) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            return null;
        }

        User update = new User();
        update.setUserId(userId);
        if (StringUtils.hasText(dto.getNickname())) update.setNickname(dto.getNickname());
        if (dto.getAvatar() != null) update.setAvatar(dto.getAvatar());
        if (StringUtils.hasText(dto.getPhone())) update.setPhone(dto.getPhone());
        if (StringUtils.hasText(dto.getCollege())) update.setCollege(dto.getCollege());
        if (StringUtils.hasText(dto.getGrade())) update.setGrade(dto.getGrade());
        update.setUpdateTime(LocalDateTime.now());

        userMapper.updateById(update);
        log.info("用户资料更新成功，userId={}", userId);
        return userMapper.selectById(userId);
    }
}
package com.zsp.campus.serveice.impl;

import com.zsp.campus.constant.JwtClaimsConstant;
import com.zsp.campus.dto.LoginDto;
import com.zsp.campus.entity.User;
import com.zsp.campus.exception.AccountDisabledException;
import com.zsp.campus.exception.AccountNotFoundException;
import com.zsp.campus.exception.PasswordErrorException;
import com.zsp.campus.properties.JwtProperties;
import com.zsp.campus.serveice.impl.LoginService;
import com.zsp.campus.serveice.UserService;
import com.zsp.campus.utils.JwtUtil;
import com.zsp.campus.vo.LoginVo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

/**
 * 登录服务实现
 */
@Service
@Slf4j
public class LoginServiceImpl implements LoginService {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtProperties jwtProperties;

    private static final BCryptPasswordEncoder PASSWORD_ENCODER = new BCryptPasswordEncoder();

    @Override
    public LoginVo login(LoginDto loginDto) {
        String studentId = loginDto.getStudentId();
        String password = loginDto.getPassword();

        // 1. 根据学号查询用户
        User user = userService.getByStudentId(studentId);
        if (user == null) {
            throw new AccountNotFoundException();
        }

        // 2. 校验密码
        if (!PASSWORD_ENCODER.matches(password, user.getPassword())) {
            throw new PasswordErrorException();
        }

        // 3. 校验账号状态
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new AccountDisabledException();
        }

        // 4. 生成 JWT
        Map<String, Object> claims = new HashMap<>();
        claims.put(JwtClaimsConstant.USER_ID, user.getUserId());
        String token = JwtUtil.createJWT(
                jwtProperties.getUserSecretKey(),
                jwtProperties.getUserTtl(),
                claims
        );

        log.info("用户登录成功，userId={}, studentId={}", user.getUserId(), user.getStudentId());

        return LoginVo.builder()
                .token(token)
                .user(user)
                .build();
    }
}
package com.zsp.campus.exception;

/**
 * 账号不存在（登录时按学号查不到用户）
 */
public class AccountNotFoundException extends BaseException {

    public AccountNotFoundException() {
        super("账号不存在");
    }

    public AccountNotFoundException(String message) {
        super(message);
    }
}

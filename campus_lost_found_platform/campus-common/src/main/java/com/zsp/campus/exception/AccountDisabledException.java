package com.zsp.campus.exception;

/**
 * 账号被禁用（user.status = 0）
 */
public class AccountDisabledException extends BaseException {

    public AccountDisabledException() {
        super("账号已被禁用，请联系管理员");
    }

    public AccountDisabledException(String message) {
        super(message);
    }
}

package com.zsp.campus.exception;

/**
 * 密码错误
 */
public class PasswordErrorException extends BaseException {

    public PasswordErrorException() {
        super("密码错误");
    }

    public PasswordErrorException(String message) {
        super(message);
    }
}

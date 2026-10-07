package com.zsp.campus.exception;

/**
 * 未登录或登录已过期（请求头缺少 token，或 token 校验不通过）
 */
public class NotLoginException extends BaseException {

    public NotLoginException() {
        super("未登录或登录已过期，请重新登录");
    }

    public NotLoginException(String message) {
        super(message);
    }
}

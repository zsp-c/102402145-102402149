package com.zsp.campus.exception;

/**
 * 不能联系自己发布的信息（claim.sender_id 与 item.user_id 相同）
 */
public class ContactSelfException extends BaseException {

    public ContactSelfException() {
        super("不能联系自己发布的信息");
    }

    public ContactSelfException(String message) {
        super(message);
    }
}

package com.zsp.campus.exception;

/**
 * 无权操作该物品信息（修改/删除时，item.user_id 与当前登录用户不一致）
 */
public class ItemAccessDeniedException extends BaseException {

    public ItemAccessDeniedException() {
        super("无权操作他人发布的信息");
    }

    public ItemAccessDeniedException(String message) {
        super(message);
    }
}

package com.zsp.campus.exception;

/**
 * 物品信息不存在（查不到，或已被逻辑删除）
 */
public class ItemNotFoundException extends BaseException {

    public ItemNotFoundException() {
        super("物品信息不存在或已被删除");
    }

    public ItemNotFoundException(String message) {
        super(message);
    }
}

package com.zsp.campus.exception;

/**
 * 物品分类不合法（不在 CategoryConstant.ALL 的 8 类之内）
 */
public class InvalidCategoryException extends BaseException {

    public InvalidCategoryException() {
        super("物品分类不合法");
    }

    public InvalidCategoryException(String message) {
        super(message);
    }
}

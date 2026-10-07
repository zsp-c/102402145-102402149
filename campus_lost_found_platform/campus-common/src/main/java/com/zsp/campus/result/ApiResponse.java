package com.zsp.campus.result;

import lombok.Data;

import java.io.Serializable;

@Data
public class ApiResponse<T> implements Serializable {

    private Integer code; //编码：1成功，0和其它数字为失败
    private String msg; //错误信息
    private T data; //数据
    public static <T> ApiResponse<T> success() {
        ApiResponse<T> result = new ApiResponse<T>();
        result.code = 1;
        return result;
    }

    public static <T> ApiResponse<T> success(T object) {
        ApiResponse<T> result = new ApiResponse<T>();
        result.data = object;
        result.code = 1;
        return result;
    }

    public static <T> ApiResponse<T> error(String msg) {
        ApiResponse result = new ApiResponse();
        result.msg = msg;
        result.code = 0;
        return result;
    }
}

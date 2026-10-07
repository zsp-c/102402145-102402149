package com.zsp.campus.handler;
import com.zsp.campus.constant.MessageConstant;
import com.zsp.campus.exception.BaseException;
import com.zsp.campus.result.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLIntegrityConstraintViolationException;

/**
 * 全局异常处理器，处理项目中抛出的业务异常
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    /**
     * 捕获业务异常
     * @param ex
     * @return
     */
    @ExceptionHandler
    public ApiResponse exceptionHandler(BaseException ex){
        log.error("异常信息：{}", ex.getMessage());
        return ApiResponse.error(ex.getMessage());
    }

    /**
     * 处理数据库唯一性约束错误
     * @param ex
     * @return
     */
    @ExceptionHandler
    public ApiResponse exceptionHandler(SQLIntegrityConstraintViolationException ex){
        String message = ex.getMessage();
        if(message.contains("Duplicate entry")){
            String[] split = message.split(" ");
            String studentId=split[2];
            String msg=studentId+ MessageConstant.ALREADY_EXISTS;
            return ApiResponse.error(msg);
        }else{
            return ApiResponse.error(MessageConstant.UNKNOWN_ERROR);
        }
    }
}
package com.zsp.campus.exception;

/**
 * 学号已被注册（注册时 student_id 唯一约束冲突）
 */
public class StudentIdExistException extends BaseException {

    public StudentIdExistException() {
        super("该学号已被注册");
    }

    public StudentIdExistException(String message) {
        super(message);
    }
}

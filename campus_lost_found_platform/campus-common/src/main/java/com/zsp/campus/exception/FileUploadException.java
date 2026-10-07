package com.zsp.campus.exception;

/**
 * 文件上传失败（图片为空、格式不支持，或 OSS 上传出错）
 */
public class FileUploadException extends BaseException {

    public FileUploadException() {
        super("文件上传失败");
    }

    public FileUploadException(String message) {
        super(message);
    }
}

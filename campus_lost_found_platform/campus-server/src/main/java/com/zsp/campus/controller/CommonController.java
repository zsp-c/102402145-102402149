package com.zsp.campus.controller;

import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.utils.AliOssUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

/**
 * 通用接口：文件上传。
 */
@RestController
@RequestMapping("/upload")
@Slf4j
@Tag(name = "通用接口")
public class CommonController {

    @Autowired
    private AliOssUtil aliOssUtil;

    /**
     * 图片上传到阿里云 OSS，返回可访问的 URL。
     */
    @PostMapping("/image")
    @Operation(summary = "上传图片")
    public ApiResponse<String> uploadImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return ApiResponse.error("上传文件不能为空");
        }

        try {
            String original = file.getOriginalFilename();
            String ext = "";
            if (original != null && original.contains(".")) {
                ext = original.substring(original.lastIndexOf("."));
            }
            String objectName = "images/" + UUID.randomUUID().toString().replace("-", "") + ext;
            String url = aliOssUtil.upload(file.getBytes(), objectName);
            log.info("图片上传成功，url={}", url);
            String sign_url = aliOssUtil.signUrl(url);
            return ApiResponse.success(sign_url);
        } catch (IOException e) {
            log.error("图片上传失败", e);
            return ApiResponse.error("图片上传失败");
        }
    }
}
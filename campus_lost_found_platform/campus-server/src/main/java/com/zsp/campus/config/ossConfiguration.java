package com.zsp.campus.config;


import com.zsp.campus.properties.AliOssProperties;
import com.zsp.campus.utils.AliOssUtil;
import com.zsp.campus.utils.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
public class ossConfiguration {

    /**
     * 配置OSS客户端
     */
    @Bean
    public AliOssUtil ossUtil(AliOssProperties alioss) {
        log.info("开始配置OSS客户端");
        return new AliOssUtil(alioss.getEndpoint(), alioss.getAccessKeyId(), alioss.getAccessKeySecret(), alioss.getBucketName());
    }
}

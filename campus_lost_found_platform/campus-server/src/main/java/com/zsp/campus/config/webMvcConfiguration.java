package com.zsp.campus.config;

import com.zsp.campus.interceptor.JwtTokenUserInterceptor;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;


@Configuration
@Slf4j
public class webMvcConfiguration implements WebMvcConfigurer {
    @Autowired
    private JwtTokenUserInterceptor jwtTokenUserInterceptor;
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        log.info("开始注册拦截器");
        registry.addInterceptor(jwtTokenUserInterceptor).addPathPatterns("/**")
                .excludePathPatterns("/login");

    }



}

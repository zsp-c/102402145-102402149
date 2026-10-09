package com.zsp.campus.config;

import com.zsp.campus.interceptor.JwtTokenUserInterceptor;
import com.zsp.campus.json.JacksonObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;


@Configuration
@Slf4j
public class webMvcConfiguration implements WebMvcConfigurer {
    @Autowired
    private JwtTokenUserInterceptor jwtTokenUserInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        log.info("开始注册拦截器");
        registry.addInterceptor(jwtTokenUserInterceptor).addPathPatterns("/**")
                .excludePathPatterns("/login", "/auth/register");
    }

    /**
     * 注册自定义的 Jackson 消息转换器（时间格式 yyyy-MM-dd HH:mm，忽略未知属性）
     */
    @Override
    public void extendMessageConverters(List<HttpMessageConverter<?>> converters) {
        MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter();
        converter.setObjectMapper(new JacksonObjectMapper());
        converters.add(0, converter);
    }
}
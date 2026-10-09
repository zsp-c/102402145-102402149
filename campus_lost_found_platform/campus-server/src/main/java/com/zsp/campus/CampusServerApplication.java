package com.zsp.campus;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.zsp.campus.mapper")
public class CampusServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(CampusServerApplication.class, args);
    }

}
package com.zsp.campus.controller;

import com.zsp.campus.constant.CategoryConstant;
import com.zsp.campus.result.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 物品分类接口。
 * 分类固定为 8 类，不单独建表，直接返回 CategoryConstant.ALL。
 */
@RestController
@RequestMapping("/categories")
@Tag(name = "物品分类")
public class CategoryController {

    @GetMapping
    @Operation(summary = "获取所有物品分类")
    public ApiResponse<List<String>> list() {
        return ApiResponse.success(CategoryConstant.ALL);
    }
}
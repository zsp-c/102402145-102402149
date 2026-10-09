package com.zsp.campus.controller;

import com.zsp.campus.dto.SearchHistoryDto;
import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.serveice.SearchHistoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 搜索模块接口
 *
 * <p>搜索本身走物品模块的 `GET /items/search`，这里的 /search/history
 * 只负责「搜索历史」的查询、记录与清除。
 */
@RestController
@RequestMapping("/search")
@Slf4j
@Tag(name = "搜索模块")
public class SearchHistoryController {

    @Autowired
    private SearchHistoryService searchHistoryService;

    /**
     * 获取我的搜索历史（按时间倒序）。
     */
    @GetMapping("/history")
    @Operation(summary = "获取我的搜索历史")
    public ApiResponse<List<String>> history(
            @RequestParam(required = false) Integer limit) {
        log.info("查询搜索历史，limit={}", limit);
        return ApiResponse.success(searchHistoryService.list(limit));
    }

    /**
     * 记录一次搜索关键词。
     *
     * <p>接口文档只列了 /search/history 的 GET 与 DELETE，「历史从哪来」缺个入口：
     * 这里补一个 POST，前端搜索成功后调用，服务端按当前登录用户落库。
     */
    @PostMapping("/history")
    @Operation(summary = "记录搜索关键词")
    public ApiResponse<Void> record(@RequestBody SearchHistoryDto dto) {
        log.info("记录搜索历史，dto={}", dto);
        searchHistoryService.record(dto == null ? null : dto.getKeyword());
        return ApiResponse.success();
    }

    /**
     * 清除我的搜索历史。
     */
    @DeleteMapping("/history")
    @Operation(summary = "清除搜索历史")
    public ApiResponse<Void> clear() {
        log.info("清除搜索历史");
        searchHistoryService.clear();
        return ApiResponse.success();
    }
}

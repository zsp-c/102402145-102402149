package com.zsp.campus.controller;

import com.zsp.campus.dto.ItemDto;
import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.serveice.ItemService;
import com.zsp.campus.vo.ItemVo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 物品模块接口
 */
@RestController
@RequestMapping("/items")
@Slf4j
@Tag(name = "物品模块")
public class ItemController {

    @Autowired
    private ItemService itemService;

    /**
     * 获取最新信息列表（首页）。
     */
    @GetMapping
    @Operation(summary = "获取最新信息列表")
    public ApiResponse<PageResult> list(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        log.info("查询物品列表，type={}, category={}, pageNum={}, pageSize={}", type, category, pageNum, pageSize);
        PageResult pageResult = itemService.pageQuery(type, category, pageNum, pageSize);
        return ApiResponse.success(pageResult);
    }

    /**
     * 获取物品详情。
     */
    @GetMapping("/{id}")
    @Operation(summary = "获取物品详情")
    public ApiResponse<ItemVo> detail(@PathVariable Long id) {
        log.info("查询物品详情，itemId={}", id);
        ItemVo vo = itemService.getDetail(id);
        return ApiResponse.success(vo);
    }

    /**
     * 发布失物/招领信息。
     */
    @PostMapping
    @Operation(summary = "发布失物/招领信息")
    public ApiResponse<Map<String, Long>> create(@RequestBody ItemDto dto) {
        log.info("发布信息，dto={}", dto);
        Long itemId = itemService.create(dto);
        Map<String, Long> data = new HashMap<>();
        data.put("itemId", itemId);
        return ApiResponse.success(data);
    }

    /**
     * 删除信息（只能删除自己发布的，已解决不可删除）。
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "删除信息")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        log.info("删除信息，itemId={}", id);
        itemService.delete(id);
        return ApiResponse.success();
    }

    /**
     * 标记已解决（寻物→已找回 / 招领→已归还）。
     */
    @PutMapping("/{id}/resolve")
    @Operation(summary = "标记已解决")
    public ApiResponse<Void> resolve(@PathVariable Long id) {
        log.info("标记已解决，itemId={}", id);
        itemService.resolve(id);
        return ApiResponse.success();
    }

    /**
     * 搜索信息。
     */
    @GetMapping("/search")
    @Operation(summary = "搜索信息")
    public ApiResponse<PageResult> search(
            @RequestParam String keyword,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        log.info("搜索信息，keyword={}, type={}, category={}", keyword, type, category);
        PageResult pageResult = itemService.search(keyword, type, category, pageNum, pageSize);
        return ApiResponse.success(pageResult);
    }

    /**
     * 获取我的发布列表。
     */
    @GetMapping("/my")
    @Operation(summary = "获取我的发布列表")
    public ApiResponse<PageResult> my(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        log.info("查询我的发布，type={}, status={}", type, status);
        PageResult pageResult = itemService.myItems(type, status, pageNum, pageSize);
        return ApiResponse.success(pageResult);
    }

    /**
     * 修改已发布信息。
     */
    @PutMapping("/{id}")
    @Operation(summary = "修改已发布信息")
    public ApiResponse<ItemVo> update(@PathVariable Long id, @RequestBody ItemDto dto) {
        log.info("修改信息，itemId={}, dto={}", id, dto);
        ItemVo vo = itemService.update(id, dto);
        return ApiResponse.success(vo);
    }
}
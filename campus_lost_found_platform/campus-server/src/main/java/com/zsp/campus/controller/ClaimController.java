package com.zsp.campus.controller;

import com.zsp.campus.context.BaseContext;
import com.zsp.campus.dto.ClaimDto;
import com.zsp.campus.result.ApiResponse;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.serveice.ClaimService;
import com.zsp.campus.sse.ClaimSseManager;
import com.zsp.campus.vo.ClaimVo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * 消息模块接口。
 *
 * <p>接口路径、参数、返回结构都对齐 apifox_openapi.json 的「消息模块」。
 * 除了 /claims/stream 返回 SSE 事件流，其余都返回统一的 ApiResponse。
 */
@RestController
@RequestMapping("/claims")
@Slf4j
@Tag(name = "消息模块")
public class ClaimController {

    @Autowired
    private ClaimService claimService;

    @Autowired
    private ClaimSseManager claimSseManager;

    /**
     * 认领消息列表（我收到的 + 我发出的）。
     */
    @GetMapping
    @Operation(summary = "认领消息列表")
    public ApiResponse<PageResult> list(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "20") Integer pageSize) {
        log.info("查询认领消息列表，pageNum={}, pageSize={}", pageNum, pageSize);
        PageResult pageResult = claimService.pageQuery(pageNum, pageSize);
        return ApiResponse.success(pageResult);
    }

    /**
     * 发送认领联系。
     */
    @PostMapping
    @Operation(summary = "发送认领联系")
    public ApiResponse<ClaimVo> send(@RequestBody ClaimDto dto) {
        log.info("发送认领联系，dto={}", dto);
        ClaimVo vo = claimService.send(dto);
        return ApiResponse.success(vo);
    }

    /**
     * 未读消息数（红点用）。
     */
    @GetMapping("/unread-count")
    @Operation(summary = "未读消息数")
    public ApiResponse<Integer> unreadCount() {
        Integer count = claimService.unreadCount();
        return ApiResponse.success(count);
    }

    /**
     * 标记单条已读。
     */
    @PutMapping("/{claimId}/read")
    @Operation(summary = "标记单条已读")
    public ApiResponse<Void> read(@PathVariable Long claimId) {
        log.info("标记消息已读，claimId={}", claimId);
        claimService.markRead(claimId);
        return ApiResponse.success();
    }

    /**
     * 全部标记已读。
     */
    @PutMapping("/read-all")
    @Operation(summary = "全部标记已读")
    public ApiResponse<Void> readAll() {
        log.info("全部标记已读");
        claimService.markAllRead();
        return ApiResponse.success();
    }

    /**
     * 删除已读消息：删除当前用户所有已读消息（收到的已读 + 发出的全部）。
     */
    @DeleteMapping("/read")
    @Operation(summary = "删除已读消息")
    public ApiResponse<Integer> deleteRead() {
        log.info("删除已读消息");
        int rows = claimService.deleteRead();
        return ApiResponse.success(rows);
    }

    /**
     * 删除单条消息。
     */
    @DeleteMapping("/{claimId}")
    @Operation(summary = "删除单条消息")
    public ApiResponse<Void> deleteOne(@PathVariable Long claimId) {
        log.info("删除单条消息，claimId={}", claimId);
        claimService.deleteOne(claimId);
        return ApiResponse.success();
    }

    /**
     * SSE 实时消息推送。
     *
     * <p>必须在当前请求线程上把 userId 取出来交给管理器：方法返回后请求就进入异步阶段，
     * 后续推送发生在心跳/业务线程，那时 BaseContext 早被清空了。
     *
     * <p>连接跟普通接口一样要带 token 请求头（走 JWT 拦截器），所以必须用
     * 能自定义 header 的客户端（Flutter 的 http 可以，浏览器原生 EventSource 不行）。
     */
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    @Operation(summary = "SSE 实时消息推送")
    public SseEmitter stream() {
        Long userId = BaseContext.getCurrentId();
        log.info("建立 SSE 连接，userId={}", userId);
        return claimSseManager.subscribe(userId);
    }
}
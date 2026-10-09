package com.zsp.campus.sse;

import com.zsp.campus.vo.ClaimVo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * SSE 连接管理器：按 userId 维护在线连接，把认领消息实时推给接收者。
 *
 * <p>设计要点：
 * <ul>
 *   <li><b>一个用户多条连接</b>：同一个人可能开着多个页面或换设备登录，
 *       所以 value 是列表而不是单个 emitter，推送时全部发一遍。</li>
 *   <li><b>推送是「尽力而为」</b>：消息已经入库，推送失败只移除这条坏连接，
 *       不影响业务。客户端重连后拉一次列表/未读数即可补齐。</li>
 *   <li><b>心跳保活</b>：中间有 Nginx 或浏览器空闲超时的话，长时间没数据的
 *       SSE 连接会被掐断，所以定时发 SSE 注释帧（`:` 开头，客户端自动忽略）。</li>
 *   <li><b>线程安全</b>：HTTP 请求线程和心跳线程会并发读写连接表，
 *       用 ConcurrentHashMap + CopyOnWriteArrayList，SseEmitter.send 自身也是同步的。</li>
 * </ul>
 *
 * <p>注意：推送发生在心跳 / 业务线程上，那时候 BaseContext 早已清空，
 * 所以这里所有方法都显式接收 userId，绝不从 BaseContext 里取。
 */
@Component
@Slf4j
public class ClaimSseManager {

    /** 连接超时时间：30 分钟。超时后客户端会自动重连，消息不丢。 */
    private static final long EMITTER_TIMEOUT = 30 * 60 * 1000L;

    /** 心跳间隔：25 秒。 */
    private static final long HEARTBEAT_SECONDS = 25L;

    /** 在线连接表：userId -> 该用户的全部连接。 */
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    /** 心跳线程池：单线程足够，只做发送注释帧这种轻量操作。 */
    private final ScheduledExecutorService heartbeatPool =
            Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "claim-sse-heartbeat");
                t.setDaemon(true);
                return t;
            });

    public ClaimSseManager() {
        heartbeatPool.scheduleAtFixedRate(this::heartbeat,
                HEARTBEAT_SECONDS, HEARTBEAT_SECONDS, TimeUnit.SECONDS);
    }

    /**
     * 建立一条 SSE 连接。
     *
     * @param userId 当前登录用户 id（由 Controller 在请求线程上取好传进来）
     * @return 交给 Spring 的 SseEmitter
     */
    public SseEmitter subscribe(Long userId) {
        SseEmitter emitter = new SseEmitter(EMITTER_TIMEOUT);

        emitters.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        // 连接结束 / 超时 / 出错都要把自己从表里摘掉，否则会越来越臃肿
        emitter.onCompletion(() -> remove(userId, emitter));
        emitter.onTimeout(() -> {
            remove(userId, emitter);
            emitter.complete();
        });
        emitter.onError(e -> remove(userId, emitter));

        // 首帧：告诉前端「连上了」。前端收到后可以立刻拉一次未读数做校准。
        try {
            emitter.send(SseEmitter.event().name("connected").data("connected"));
        } catch (Exception e) {
            remove(userId, emitter);
            log.warn("SSE 首帧发送失败，userId={}", userId, e);
            return emitter;
        }

        log.info("SSE 连接建立，userId={}，该用户当前连接数={}", userId, count(userId));
        return emitter;
    }

    /**
     * 向指定用户的全部在线连接推送一条认领消息。
     *
     * @param userId 接收者 id
     * @param vo     消息内容（与列表接口返回的结构一致）
     */
    public void push(Long userId, ClaimVo vo) {
        List<SseEmitter> list = emitters.get(userId);
        if (list == null || list.isEmpty()) {
            log.info("用户 {} 当前不在线，消息只入库不推送", userId);
            return;
        }
        for (SseEmitter emitter : list) {
            try {
                emitter.send(SseEmitter.event().name("claim").data(vo));
            } catch (Exception e) {
                // 连接已断开：摘掉即可。消息在库里，用户重连后能拉到
                remove(userId, emitter);
                log.debug("SSE 推送失败，已移除该连接，userId={}", userId, e);
            }
        }
    }

    /** 定时给所有在线连接发注释帧，防中间层掐断空闲连接。 */
    private void heartbeat() {
        emitters.forEach((userId, list) -> {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().comment("ping"));
                } catch (Exception e) {
                    remove(userId, emitter);
                }
            }
        });
    }

    /** 从连接表里摘掉一条连接；该用户没有连接了就整条删掉。 */
    private void remove(Long userId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(userId);
        if (list == null) {
            return;
        }
        list.remove(emitter);
        if (list.isEmpty()) {
            emitters.remove(userId);
        }
        log.info("SSE 连接关闭，userId={}，剩余连接数={}", userId, count(userId));
    }

    /** 某用户当前的连接数。 */
    public int count(Long userId) {
        List<SseEmitter> list = emitters.get(userId);
        return list == null ? 0 : list.size();
    }
}

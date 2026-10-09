package com.zsp.campus.vo;

import com.zsp.campus.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 认领消息视图对象，对应接口文档 ClaimVo。
 *
 * <p>列表接口和 SSE 推送返回的都是这个结构：消息本体来自 claim 表，
 * 另外关联查询出物品名称和收发双方的 User 信息。
 *
 * <p>前端不区分「收件箱 / 发件箱」：拿到的每条消息都同时带 senderId 和 receiverId，
 * 谁等于当前登录用户 id，谁就是「我」，另一方就是「对方」。这样一套数据结构
 * 同时满足「我收到的」和「我发出的」两种展示。
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class ClaimVo {

    /** 消息 id */
    private Long claimId;

    /** 关联的物品 id */
    private Long itemId;

    /** 关联物品名称（关联 item.name，物品被删时为空串） */
    private String itemName;

    /** 发送者 id（认领 / 提供线索的人） */
    private Long senderId;

    /** 发送者信息 */
    private User sender;

    /** 接收者 id（物品发布者），SSE 按此字段路由 */
    private Long receiverId;

    /** 接收者信息 */
    private User receiver;

    /** CONTACT-认领联系 / SYSTEM-系统通知 */
    private String msgType;

    /** 消息内容 */
    private String claimContent;

    /** 已读状态：0-未读 1-已读 */
    private Integer readStatus;

    /** 发送时间 */
    private LocalDateTime createTime;
}

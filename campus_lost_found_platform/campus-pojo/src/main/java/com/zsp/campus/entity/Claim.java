package com.zsp.campus.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serial;
import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 认领消息实体类，对应表 claim
 *
 * <p>消息采用「入库 + SSE 推送」：入库是事实来源，SSE 只是尽力而为的实时通道。
 * 用户离线时推送失败不影响消息本身，客户端重连后拉一次未读即可。
 *
 * <p>只记录「谁能收到这条消息」，不设同意 / 拒绝状态 —— 送达到位即可，
 * 认领结果由双方线下沟通。
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@TableName("claim")
public class Claim implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    /** 消息 id */
    @TableId(type = IdType.AUTO)
    private Long claimId;

    /** 关联的物品 id */
    private Long itemId;

    /** 发送者 id（认领 / 提供线索的人） */
    private Long senderId;

    /** 接收者 id（物品发布者），SSE 按此字段路由 */
    private Long receiverId;

    /** CONTACT-认领联系 / SYSTEM-系统通知 */
    private String msgType;

    /** 消息内容 */
    private String claimContent;

    /** 已读状态：0-未读 1-已读（供未读红点使用） */
    private Integer readStatus;

    /** 发送时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
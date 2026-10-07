package com.zsp.campus.dto;

import lombok.Data;

/**
 * 发送认领消息 dto
 *
 * <p>这里的 senderId 不在 dto 里：由服务端从 JWT 中取当前登录用户，
 * 否则前端可以伪造任意用户身份给发布者发消息。
 */
@Data
public class ClaimDto {
    /** 物品 id */
    private Long itemId;

    /** 消息内容 */
    private String claimContent;
}

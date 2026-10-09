package com.zsp.campus.dto;

import lombok.Data;

/**
 * 记录搜索历史 dto
 *
 * <p>这里的 userId 不在 dto 里：由服务端从 JWT 中取当前登录用户，
 * 否则前端可以往任意用户名下塞搜索历史。
 */
@Data
public class SearchHistoryDto {
    /** 搜索关键词 */
    private String keyword;
}

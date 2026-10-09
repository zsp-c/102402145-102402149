package com.zsp.campus.serveice;

import java.util.List;

/**
 * 搜索历史服务
 */
public interface SearchHistoryService {

    /**
     * 获取当前登录用户的搜索历史，按搜索时间倒序。
     *
     * @param limit 返回条数，可空（默认 10，最大 50）
     * @return 关键词列表
     */
    List<String> list(Integer limit);

    /**
     * 记录一次搜索关键词（同一关键词只保留最新一次）。
     *
     * @param keyword 关键词，空串直接忽略
     */
    void record(String keyword);

    /**
     * 清除当前登录用户的全部搜索历史。
     */
    void clear();
}

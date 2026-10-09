package com.zsp.campus.serveice.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zsp.campus.context.BaseContext;
import com.zsp.campus.entity.SearchHistory;
import com.zsp.campus.mapper.SearchHistoryMapper;
import com.zsp.campus.serveice.SearchHistoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 搜索历史服务实现。
 *
 * <p>核心是「按用户隔离 + 同词置顶」：历史在 search_history 表里按 user_id 分开存，
 * 记录时先把同关键词的旧行删掉再插新行，等价于把该词挪到最新位置，
 * 所以同一关键词在库里永远只有一行。
 */
@Service
@Slf4j
public class SearchHistoryServiceImpl implements SearchHistoryService {

    /** 关键词最大长度，与 search_history.keyword VARCHAR(64) 对齐 */
    private static final int KEYWORD_MAX_LENGTH = 64;
    /** 单用户最多保留的历史条数，超出后丢弃最旧的 */
    private static final int MAX_KEEP = 20;
    /** 未传 limit 时的默认返回条数 */
    private static final int DEFAULT_LIMIT = 10;
    /** 返回条数上限，防止一次拉太多 */
    private static final int MAX_LIMIT = 50;

    @Autowired
    private SearchHistoryMapper searchHistoryMapper;

    @Override
    public List<String> list(Integer limit) {
        Long userId = BaseContext.getCurrentId();
        int size = normalizeLimit(limit);

        // 只取最新 size 条，不需要总数，selectPage 的第三个参数传 false 跳过 count 查询
        Page<SearchHistory> page = new Page<>(1, size, false);
        searchHistoryMapper.selectPage(page, new LambdaQueryWrapper<SearchHistory>()
                .eq(SearchHistory::getUserId, userId)
                .orderByDesc(SearchHistory::getCreateTime)
                .orderByDesc(SearchHistory::getHistoryId));

        List<SearchHistory> rows = page.getRecords();
        if (rows == null || rows.isEmpty()) {
            return Collections.emptyList();
        }
        return rows.stream()
                .map(SearchHistory::getKeyword)
                .filter(StringUtils::hasText)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void record(String keyword) {
        if (!StringUtils.hasText(keyword)) {
            return;
        }
        String trimmed = keyword.trim();
        if (trimmed.length() > KEYWORD_MAX_LENGTH) {
            trimmed = trimmed.substring(0, KEYWORD_MAX_LENGTH);
        }

        Long userId = BaseContext.getCurrentId();

        // 同关键词只保留最新一次：先删旧行再插新行，相当于把它挪到最前面
        searchHistoryMapper.delete(new LambdaQueryWrapper<SearchHistory>()
                .eq(SearchHistory::getUserId, userId)
                .eq(SearchHistory::getKeyword, trimmed));

        SearchHistory history = new SearchHistory();
        history.setUserId(userId);
        history.setKeyword(trimmed);
        history.setCreateTime(LocalDateTime.now());
        searchHistoryMapper.insert(history);

        trimOverflow(userId);

        log.info("记录搜索历史成功，userId={}, keyword={}", userId, trimmed);
    }

    @Override
    public void clear() {
        Long userId = BaseContext.getCurrentId();
        searchHistoryMapper.delete(new LambdaQueryWrapper<SearchHistory>()
                .eq(SearchHistory::getUserId, userId));
        log.info("清除搜索历史成功，userId={}", userId);
    }

    // ============================================================
    //  私有辅助方法
    // ============================================================

    /** 把 limit 收敛到 [1, MAX_LIMIT]，空值或非正数走默认值。 */
    private int normalizeLimit(Integer limit) {
        if (limit == null || limit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }

    /** 超出 MAX_KEEP 的旧记录直接删掉，避免历史无限增长。 */
    private void trimOverflow(Long userId) {
        List<SearchHistory> rows = searchHistoryMapper.selectList(
                new LambdaQueryWrapper<SearchHistory>()
                        .eq(SearchHistory::getUserId, userId)
                        .orderByDesc(SearchHistory::getCreateTime)
                        .orderByDesc(SearchHistory::getHistoryId));
        if (rows == null || rows.size() <= MAX_KEEP) {
            return;
        }
        List<Long> overflowIds = rows.subList(MAX_KEEP, rows.size()).stream()
                .map(SearchHistory::getHistoryId)
                .collect(Collectors.toList());
        searchHistoryMapper.deleteBatchIds(overflowIds);
    }
}

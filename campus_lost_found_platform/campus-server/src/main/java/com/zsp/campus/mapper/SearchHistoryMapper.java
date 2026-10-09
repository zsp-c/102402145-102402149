package com.zsp.campus.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zsp.campus.entity.SearchHistory;
import org.apache.ibatis.annotations.Mapper;

/**
 * 搜索历史 Mapper，基于 MyBatis-Plus BaseMapper。
 *
 * <p>查询都是「按用户过滤 + 按时间倒序 + 取前 N 条」这类条件查询，
 * BaseMapper 的方法足够，不需要写 XML。
 */
@Mapper
public interface SearchHistoryMapper extends BaseMapper<SearchHistory> {
}

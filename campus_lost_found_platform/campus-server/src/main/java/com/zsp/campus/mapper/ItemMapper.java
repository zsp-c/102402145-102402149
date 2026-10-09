package com.zsp.campus.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zsp.campus.entity.Item;
import org.apache.ibatis.annotations.Mapper;

/**
 * 物品 Mapper，基于 MyBatis-Plus BaseMapper
 */
@Mapper
public interface ItemMapper extends BaseMapper<Item> {
}
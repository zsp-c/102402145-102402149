package com.zsp.campus.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zsp.campus.entity.Claim;
import org.apache.ibatis.annotations.Mapper;

/**
 * 认领消息 Mapper，基于 MyBatis-Plus BaseMapper。
 *
 * <p>消息查询都是「按 senderId / receiverId 过滤 + 按时间倒序」这类条件查询，
 * BaseMapper 的方法足够，不需要写 XML；真正复杂的分页条件在
 * ClaimServiceImpl 里用 LambdaQueryWrapper 拼。
 */
@Mapper
public interface ClaimMapper extends BaseMapper<Claim> {
}

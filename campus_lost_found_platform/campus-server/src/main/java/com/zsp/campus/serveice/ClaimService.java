package com.zsp.campus.serveice;

import com.zsp.campus.dto.ClaimDto;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.vo.ClaimVo;

/**
 * 认领消息服务。
 *
 * <p>「入库 + SSE 推送」的分工：send 方法负责把消息写进 claim 表（事实来源），
 * 再尽最大努力往接收者的在线连接推一发；推送失败不影响消息本身，
 * 接收者下次拉列表 / 重连后拉未读一样能看到。
 */
public interface ClaimService {

    /**
     * 分页查询「与我相关」的消息列表（我收到的 + 我发出的），按发送时间倒序。
     *
     * @param pageNum  页码
     * @param pageSize 每页条数
     * @return 分页结果，records 为 ClaimVo
     */
    PageResult pageQuery(Integer pageNum, Integer pageSize);

    /**
     * 发送一条认领联系消息。
     *
     * <p>发送者是当前登录用户（服务端从 JWT 取，不接受前端传入）；
     * 接收者由 itemId 关联到 item.user_id 得到；不能联系自己发布的信息。
     *
     * @param dto 物品 id + 消息内容
     * @return 刚发送的消息（与 SSE 推送给接收者的结构一致）
     */
    ClaimVo send(ClaimDto dto);

    /**
     * 当前登录用户的未读消息数（只统计别人发给我的，供未读红点使用）。
     *
     * @return 未读条数
     */
    Integer unreadCount();

    /**
     * 标记单条消息已读，只能标记自己收到的消息。
     *
     * @param claimId 消息 id
     */
    void markRead(Long claimId);

    /**
     * 把当前登录用户收到的消息全部标记为已读。
     */
    void markAllRead();

    /**
     * 删除当前登录用户所有已读消息（仅收到的已读消息）。
     *
     * @return 删除的条数
     */
    int deleteRead();

    /**
     * 删除单条消息。发送者和接收者都可以删除（各自视角删除）。
     *
     * @param claimId 消息 id
     */
    void deleteOne(Long claimId);
}
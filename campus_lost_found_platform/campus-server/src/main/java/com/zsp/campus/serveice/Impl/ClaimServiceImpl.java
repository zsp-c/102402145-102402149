package com.zsp.campus.serveice.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zsp.campus.context.BaseContext;
import com.zsp.campus.dto.ClaimDto;
import com.zsp.campus.entity.Claim;
import com.zsp.campus.entity.Item;
import com.zsp.campus.entity.User;
import com.zsp.campus.exception.BaseException;
import com.zsp.campus.exception.ContactSelfException;
import com.zsp.campus.exception.ItemNotFoundException;
import com.zsp.campus.mapper.ClaimMapper;
import com.zsp.campus.mapper.ItemMapper;
import com.zsp.campus.mapper.UserMapper;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.serveice.ClaimService;
import com.zsp.campus.sse.ClaimSseManager;
import com.zsp.campus.utils.AliOssUtil;
import com.zsp.campus.vo.ClaimVo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 认领消息服务实现。
 *
 * <p>核心是「一条消息两个视角」：claim 表里一行记录同时有 sender_id 和 receiver_id，
 * 我收到的是 receiver_id = 我，我发出的是 sender_id = 我。所以列表查询用
 * 一个 or 条件就能一次查出「与我相关」的全部消息，前端按 senderId 判断方向。
 */
@Service
@Slf4j
public class ClaimServiceImpl implements ClaimService {

    /** 认领联系 */
    private static final String MSG_TYPE_CONTACT = "CONTACT";
    /** 未读 */
    private static final int READ_STATUS_UNREAD = 0;
    /** 已读 */
    private static final int READ_STATUS_READ = 1;
    /** 消息内容上限，与 claim.claim_content VARCHAR(500) 对齐 */
    private static final int CONTENT_MAX_LENGTH = 500;
    /** 未填写附言时的默认文案 */
    private static final String DEFAULT_CONTENT = "我想联系你了解这个物品的更多细节";
    /** 寻物已解决：已找回 */
    private static final String STATUS_FOUND = "FOUND";
    /** 招领已解决：已归还 */
    private static final String STATUS_CLAIMED = "CLAIMED";

    @Autowired
    private ClaimMapper claimMapper;

    @Autowired
    private ItemMapper itemMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ClaimSseManager claimSseManager;

    @Autowired
    private AliOssUtil aliOssUtil;

    @Override
    public PageResult pageQuery(Integer pageNum, Integer pageSize) {
        Long userId = BaseContext.getCurrentId();

        // 只展示「我收到的」消息，不展示自己发出的
        LambdaQueryWrapper<Claim> wrapper = new LambdaQueryWrapper<Claim>()
                .eq(Claim::getReceiverId, userId)
                .orderByDesc(Claim::getCreateTime);

        Page<Claim> page = new Page<>(pageNum, pageSize);
        claimMapper.selectPage(page, wrapper);

        // 过滤掉已完成（已找回/已归还）物品的消息：物品已解决，联系消息不再展示
        List<Claim> filtered = filterResolvedItems(page.getRecords());

        List<ClaimVo> records = convertToVoList(filtered);

        PageResult result = new PageResult();
        result.setTotal((long) records.size());
        result.setRecords(records);
        result.setPageNum(page.getCurrent());
        result.setPageSize(page.getSize());
        result.setPages(records.isEmpty() ? 0L : 1L);
        return result;
    }

    @Override
    @Transactional
    public ClaimVo send(ClaimDto dto) {
        Long senderId = BaseContext.getCurrentId();

        // 接收者不由前端传，一律从物品的发布者推导，防止伪造收件人
        Item item = itemMapper.selectById(dto.getItemId());
        if (item == null || item.getIsDeleted() != null && item.getIsDeleted() == 1) {
            throw new ItemNotFoundException();
        }
        Long receiverId = item.getUserId();
        if (receiverId.equals(senderId)) {
            throw new ContactSelfException();
        }

        String content = StringUtils.hasText(dto.getClaimContent())
                ? dto.getClaimContent().trim()
                : DEFAULT_CONTENT;
        if (content.length() > CONTENT_MAX_LENGTH) {
            throw new BaseException("消息内容最多 " + CONTENT_MAX_LENGTH + " 个字");
        }

        LocalDateTime now = LocalDateTime.now();
        Claim claim = new Claim();
        claim.setItemId(item.getItemId());
        claim.setSenderId(senderId);
        claim.setReceiverId(receiverId);
        claim.setMsgType(MSG_TYPE_CONTACT);
        claim.setClaimContent(content);
        claim.setReadStatus(READ_STATUS_UNREAD);
        claim.setCreateTime(now);
        claim.setUpdateTime(now);
        claimMapper.insert(claim);

        ClaimVo vo = convertToVo(claim, item);

        // 入库成功后再推送：推失败也不回滚业务，消息已经在库里
        claimSseManager.push(receiverId, vo);

        log.info("发送认领消息成功，claimId={}, itemId={}, senderId={}, receiverId={}",
                claim.getClaimId(), item.getItemId(), senderId, receiverId);
        return vo;
    }

    @Override
    public Integer unreadCount() {
        Long userId = BaseContext.getCurrentId();
        // 只有别人发给我的才算未读红点，我自己发出去的不算
        Long count = claimMapper.selectCount(new LambdaQueryWrapper<Claim>()
                .eq(Claim::getReceiverId, userId)
                .eq(Claim::getReadStatus, READ_STATUS_UNREAD));
        return count == null ? 0 : count.intValue();
    }

    @Override
    public void markRead(Long claimId) {
        Claim claim = getExistClaim(claimId);
        checkReceiver(claim);

        // 已是已读就不必再写库
        if (claim.getReadStatus() != null && claim.getReadStatus() == READ_STATUS_READ) {
            return;
        }

        Claim update = new Claim();
        update.setClaimId(claimId);
        update.setReadStatus(READ_STATUS_READ);
        update.setUpdateTime(LocalDateTime.now());
        claimMapper.updateById(update);

        log.info("标记消息已读成功，claimId={}", claimId);
    }

    @Override
    public void markAllRead() {
        Long userId = BaseContext.getCurrentId();

        Claim update = new Claim();
        update.setReadStatus(READ_STATUS_READ);
        update.setUpdateTime(LocalDateTime.now());
        claimMapper.update(update, new LambdaUpdateWrapper<Claim>()
                .eq(Claim::getReceiverId, userId)
                .eq(Claim::getReadStatus, READ_STATUS_UNREAD));

        log.info("全部标记已读完成，receiverId={}", userId);
    }

    @Override
    public int deleteRead() {
        Long userId = BaseContext.getCurrentId();

        // 只删除我收到的已读消息
        int rows = claimMapper.delete(new LambdaQueryWrapper<Claim>()
                .eq(Claim::getReceiverId, userId)
                .eq(Claim::getReadStatus, READ_STATUS_READ));

        log.info("删除已读消息完成，userId={}, 删除条数={}", userId, rows);
        return rows;
    }

    @Override
    public void deleteOne(Long claimId) {
        Claim claim = getExistClaim(claimId);
        Long currentId = BaseContext.getCurrentId();
        // 发送者和接收者都可以删除自己视角的这条消息
        if (!claim.getSenderId().equals(currentId) && !claim.getReceiverId().equals(currentId)) {
            throw new BaseException("只能删除自己相关的消息");
        }
        claimMapper.deleteById(claimId);
        log.info("删除单条消息成功，claimId={}, userId={}", claimId, currentId);
    }

    // ============================================================
    //  私有辅助方法
    // ============================================================

    /**
     * 过滤掉关联物品已完成（已找回 FOUND / 已归还 CLAIMED）的消息。
     * 物品已解决，联系消息不再展示在消息列表。
     */
    private List<Claim> filterResolvedItems(List<Claim> claims) {
        if (CollectionUtils.isEmpty(claims)) {
            return Collections.emptyList();
        }
        Set<Long> itemIds = claims.stream().map(Claim::getItemId).collect(Collectors.toSet());
        Map<Long, Item> itemMap = itemMapper.selectBatchIds(itemIds).stream()
                .collect(Collectors.toMap(Item::getItemId, i -> i, (a, b) -> a));

        return claims.stream()
                .filter(claim -> {
                    Item item = itemMap.get(claim.getItemId());
                    if (item == null) {
                        // 物品已被物理删除，消息也不再展示
                        return false;
                    }
                    String status = item.getStatus();
                    return !STATUS_FOUND.equals(status) && !STATUS_CLAIMED.equals(status);
                })
                .collect(Collectors.toList());
    }

    /** 查询存在的消息，查不到直接报错。 */
    private Claim getExistClaim(Long claimId) {
        Claim claim = claimMapper.selectById(claimId);
        if (claim == null) {
            throw new BaseException("消息不存在");
        }
        return claim;
    }

    /** 已读是「收件人」的动作，别人（包括发送者自己）无权改。 */
    private void checkReceiver(Claim claim) {
        Long currentId = BaseContext.getCurrentId();
        if (!claim.getReceiverId().equals(currentId)) {
            throw new BaseException("只能操作自己收到的消息");
        }
    }

    /** 单条消息转 VO，用于 send 的返回值和 SSE 推送内容。 */
    private ClaimVo convertToVo(Claim claim, Item item) {
        Map<Long, User> userMap = loadUsers(List.of(claim.getSenderId(), claim.getReceiverId()));
        return convertToVo(claim, item, userMap);
    }

    /** 批量把消息转 VO：物品名、收发双方信息都一次性查出来，避免 N+1。 */
    private List<ClaimVo> convertToVoList(List<Claim> claims) {
        if (CollectionUtils.isEmpty(claims)) {
            return Collections.emptyList();
        }

        Set<Long> itemIds = claims.stream().map(Claim::getItemId).collect(Collectors.toSet());
        Map<Long, Item> itemMap = itemMapper.selectBatchIds(itemIds).stream()
                .collect(Collectors.toMap(Item::getItemId, i -> i, (a, b) -> a));

        Set<Long> userIds = new HashSet<>();
        for (Claim claim : claims) {
            userIds.add(claim.getSenderId());
            userIds.add(claim.getReceiverId());
        }
        Map<Long, User> userMap = loadUsers(userIds);

        List<ClaimVo> result = new ArrayList<>(claims.size());
        for (Claim claim : claims) {
            result.add(convertToVo(claim, itemMap.get(claim.getItemId()), userMap));
        }
        return result;
    }

    /** 组装单个 VO。userMap 里同一个用户只会被签名一次，见 loadUsers。 */
    private ClaimVo convertToVo(Claim claim, Item item, Map<Long, User> userMap) {
        ClaimVo vo = new ClaimVo();
        BeanUtils.copyProperties(claim, vo);
        vo.setItemName(item == null || item.getName() == null ? "" : item.getName());
        vo.setSender(userMap.get(claim.getSenderId()));
        vo.setReceiver(userMap.get(claim.getReceiverId()));
        return vo;
    }

    /**
     * 按 id 批量查用户，并把头像换成签名 URL。
     *
     * <p>签名放在这里做：一个用户可能出现在多条消息里，共用同一个 User 实例，
     * 如果每条消息各签一次，头像 URL 会被重复拼接签名参数。
     */
    private Map<Long, User> loadUsers(java.util.Collection<Long> userIds) {
        if (CollectionUtils.isEmpty(userIds)) {
            return Collections.emptyMap();
        }
        List<User> users = userMapper.selectBatchIds(userIds);
        for (User user : users) {
            if (user != null && StringUtils.hasText(user.getAvatar())) {
                user.setAvatar(aliOssUtil.signUrl(user.getAvatar()));
            }
        }
        return users.stream().collect(Collectors.toMap(User::getUserId, u -> u, (a, b) -> a));
    }
}
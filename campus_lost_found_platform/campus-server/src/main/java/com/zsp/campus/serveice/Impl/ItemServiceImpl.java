package com.zsp.campus.serveice.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zsp.campus.constant.CategoryConstant;
import com.zsp.campus.context.BaseContext;
import com.zsp.campus.dto.ItemDto;
import com.zsp.campus.entity.Item;
import com.zsp.campus.entity.ItemImage;
import com.zsp.campus.entity.User;
import com.zsp.campus.exception.InvalidCategoryException;
import com.zsp.campus.exception.ItemAccessDeniedException;
import com.zsp.campus.exception.ItemNotFoundException;
import com.zsp.campus.mapper.ItemImageMapper;
import com.zsp.campus.mapper.ItemMapper;
import com.zsp.campus.mapper.UserMapper;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.serveice.ItemService;
import com.zsp.campus.utils.AliOssUtil;
import com.zsp.campus.vo.ItemVo;
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
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 物品服务实现
 */
@Service
@Slf4j
public class ItemServiceImpl implements ItemService {

    /** 寻物初始状态：寻找中 */
    private static final String STATUS_SEEKING = "SEEKING";
    /** 招领初始状态：待认领 */
    private static final String STATUS_PENDING = "PENDING";
    /** 寻物已解决：已找回 */
    private static final String STATUS_FOUND = "FOUND";
    /** 招领已解决：已归还 */
    private static final String STATUS_CLAIMED = "CLAIMED";
    /** 寻物 */
    private static final String TYPE_LOST = "LOST";
    /** 招领 */
    private static final String TYPE_FOUND = "FOUND";

    @Autowired
    private ItemMapper itemMapper;

    @Autowired
    private ItemImageMapper itemImageMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private AliOssUtil aliOssUtil;

    @Override
    public PageResult pageQuery(String type, String category, Integer pageNum, Integer pageSize) {
        LambdaQueryWrapper<Item> wrapper = buildBaseWrapper();
        if (StringUtils.hasText(type)) {
            wrapper.eq(Item::getType, type);
        }
        if (StringUtils.hasText(category)) {
            wrapper.eq(Item::getCategory, category);
        }
        wrapper.orderByDesc(Item::getCreateTime);

        Page<Item> page = new Page<>(pageNum, pageSize);
        itemMapper.selectPage(page, wrapper);

        List<ItemVo> records = convertToVoList(page.getRecords(), false);
        return buildPageResult(page, records);
    }

    @Override
    public ItemVo getDetail(Long itemId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null || item.getIsDeleted() != null && item.getIsDeleted() == 1) {
            throw new ItemNotFoundException();
        }

        // 浏览量 +1
        Item update = new Item();
        update.setItemId(itemId);
        update.setViewCount(item.getViewCount() == null ? 1 : item.getViewCount() + 1);
        itemMapper.updateById(update);
        item.setViewCount(update.getViewCount());

        return convertToVo(item, true);
    }

    @Override
    @Transactional
    public Long create(ItemDto dto) {
        // 校验分类
        if (!CategoryConstant.isValid(dto.getCategory())) {
            throw new InvalidCategoryException();
        }

        Long userId = BaseContext.getCurrentId();
        LocalDateTime now = LocalDateTime.now();

        Item item = new Item();
        item.setUserId(userId);
        item.setType(dto.getType());
        // 寻物默认寻找中，招领默认待认领
        item.setStatus(TYPE_LOST.equals(dto.getType()) ? STATUS_SEEKING : STATUS_PENDING);
        item.setName(dto.getName());
        item.setDescription(dto.getDescription());
        item.setCategory(dto.getCategory());
        item.setLocation(dto.getLocation());
        item.setViewCount(0);
        item.setFindOrLostTime(dto.getFindOrLostTime());
        item.setIsDeleted(0);
        item.setCreateTime(now);
        item.setUpdateTime(now);

        // 封面图：取第一张
        List<String> images = dto.getImages();
        if (!CollectionUtils.isEmpty(images) && StringUtils.hasText(images.get(0))) {
            item.setImage(images.get(0));
        }

        itemMapper.insert(item);
        Long itemId = item.getItemId();

        // 保存图片列表到 item_image 表
        saveImages(itemId, images);

        // 发布者累计发布数 +1
        User user = userMapper.selectById(userId);
        if (user != null) {
            User u = new User();
            u.setUserId(userId);
            u.setTotalPublish((user.getTotalPublish() == null ? 0 : user.getTotalPublish()) + 1);
            userMapper.updateById(u);
        }

        log.info("发布信息成功，itemId={}, userId={}", itemId, userId);
        return itemId;
    }

    @Override
    @Transactional
    public void delete(Long itemId) {
        Item item = getExistItem(itemId);
        checkOwnership(item);

        // 已解决不可删除
        if (STATUS_FOUND.equals(item.getStatus()) || STATUS_CLAIMED.equals(item.getStatus())) {
            throw new ItemAccessDeniedException("已解决的信息不可删除");
        }

        // 逻辑删除
        Item update = new Item();
        update.setItemId(itemId);
        update.setIsDeleted(1);
        update.setUpdateTime(LocalDateTime.now());
        itemMapper.updateById(update);

        // 发布者累计发布数 -1
        User user = userMapper.selectById(item.getUserId());
        if (user != null && user.getTotalPublish() != null && user.getTotalPublish() > 0) {
            User u = new User();
            u.setUserId(item.getUserId());
            u.setTotalPublish(user.getTotalPublish() - 1);
            userMapper.updateById(u);
        }

        log.info("删除信息成功，itemId={}", itemId);
    }

    @Override
    @Transactional
    public void resolve(Long itemId) {
        Item item = getExistItem(itemId);
        checkOwnership(item);

        // 根据类型设置已解决状态
        String resolvedStatus = TYPE_LOST.equals(item.getType()) ? STATUS_FOUND : STATUS_CLAIMED;
        Item update = new Item();
        update.setItemId(itemId);
        update.setStatus(resolvedStatus);
        update.setUpdateTime(LocalDateTime.now());
        itemMapper.updateById(update);

        // 发布者累计已完成数 +1
        User user = userMapper.selectById(item.getUserId());
        if (user != null) {
            User u = new User();
            u.setUserId(item.getUserId());
            u.setTotalCompleted((user.getTotalCompleted() == null ? 0 : user.getTotalCompleted()) + 1);
            userMapper.updateById(u);
        }

        log.info("标记已解决成功，itemId={}, status={}", itemId, resolvedStatus);
    }

    @Override
    public PageResult search(String keyword, String type, String category, Integer pageNum, Integer pageSize) {
        LambdaQueryWrapper<Item> wrapper = buildBaseWrapper();
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(Item::getName, keyword)
                    .or().like(Item::getDescription, keyword)
                    .or().like(Item::getLocation, keyword));
        }
        if (StringUtils.hasText(type)) {
            wrapper.eq(Item::getType, type);
        }
        if (StringUtils.hasText(category)) {
            wrapper.eq(Item::getCategory, category);
        }
        wrapper.orderByDesc(Item::getCreateTime);

        Page<Item> page = new Page<>(pageNum, pageSize);
        itemMapper.selectPage(page, wrapper);

        List<ItemVo> records = convertToVoList(page.getRecords(), false);
        return buildPageResult(page, records);
    }

    @Override
    public PageResult myItems(String type, String status, Integer pageNum, Integer pageSize) {
        Long userId = BaseContext.getCurrentId();
        LambdaQueryWrapper<Item> wrapper = buildBaseWrapper();
        wrapper.eq(Item::getUserId, userId);
        if (StringUtils.hasText(type)) {
            wrapper.eq(Item::getType, type);
        }
        if (StringUtils.hasText(status)) {
            wrapper.eq(Item::getStatus, status);
        }
        wrapper.orderByDesc(Item::getCreateTime);

        Page<Item> page = new Page<>(pageNum, pageSize);
        itemMapper.selectPage(page, wrapper);

        List<ItemVo> records = convertToVoList(page.getRecords(), false);
        return buildPageResult(page, records);
    }

    @Override
    @Transactional
    public ItemVo update(Long itemId, ItemDto dto) {
        Item item = getExistItem(itemId);
        checkOwnership(item);

        // 校验分类
        if (StringUtils.hasText(dto.getCategory()) && !CategoryConstant.isValid(dto.getCategory())) {
            throw new InvalidCategoryException();
        }

        Item update = new Item();
        update.setItemId(itemId);
        if (StringUtils.hasText(dto.getType())) update.setType(dto.getType());
        if (StringUtils.hasText(dto.getName())) update.setName(dto.getName());
        if (StringUtils.hasText(dto.getDescription())) update.setDescription(dto.getDescription());
        if (StringUtils.hasText(dto.getCategory())) update.setCategory(dto.getCategory());
        if (StringUtils.hasText(dto.getLocation())) update.setLocation(dto.getLocation());
        if (dto.getFindOrLostTime() != null) update.setFindOrLostTime(dto.getFindOrLostTime());
        update.setUpdateTime(LocalDateTime.now());

        // 更新封面图
        List<String> images = dto.getImages();
        if (images != null) {
            if (!images.isEmpty() && StringUtils.hasText(images.get(0))) {
                update.setImage(images.get(0));
            } else {
                update.setImage(null);
            }
        }

        itemMapper.updateById(update);

        // 重建图片列表：先删后插
        if (images != null) {
            itemImageMapper.delete(new LambdaQueryWrapper<ItemImage>().eq(ItemImage::getItemId, itemId));
            saveImages(itemId, images);
        }

        log.info("修改信息成功，itemId={}", itemId);
        return getDetail(itemId);
    }

    // ============================================================
    //  私有辅助方法
    // ============================================================

    /** 基础查询条件：未逻辑删除。 */
    private LambdaQueryWrapper<Item> buildBaseWrapper() {
        return new LambdaQueryWrapper<Item>()
                .eq(Item::getIsDeleted, 0);
    }

    /** 查询存在且未删除的物品。 */
    private Item getExistItem(Long itemId) {
        Item item = itemMapper.selectById(itemId);
        if (item == null || item.getIsDeleted() != null && item.getIsDeleted() == 1) {
            throw new ItemNotFoundException();
        }
        return item;
    }

    /** 校验当前登录用户是否为物品发布者。 */
    private void checkOwnership(Item item) {
        Long currentId = BaseContext.getCurrentId();
        if (!item.getUserId().equals(currentId)) {
            throw new ItemAccessDeniedException();
        }
    }

    /** 保存图片列表到 item_image 表。 */
    private void saveImages(Long itemId, List<String> images) {
        if (CollectionUtils.isEmpty(images)) {
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        for (int i = 0; i < images.size(); i++) {
            String url = images.get(i);
            if (!StringUtils.hasText(url)) {
                continue;
            }
            ItemImage img = new ItemImage();
            img.setItemId(itemId);
            img.setUrl(url);
            img.setSortOrder(i);
            img.setCreateTime(now);
            itemImageMapper.insert(img);
        }
    }

    /** 批量将 Item 转为 ItemVo（含发布者信息）。 */
    private List<ItemVo> convertToVoList(List<Item> items, boolean withAllImages) {
        if (CollectionUtils.isEmpty(items)) {
            return Collections.emptyList();
        }

        // 批量查询发布者
        Set<Long> userIds = items.stream().map(Item::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(userIds).stream()
                .collect(Collectors.toMap(User::getUserId, u -> u, (a, b) -> a));

        // 批量查询图片
        List<Long> itemIds = items.stream().map(Item::getItemId).collect(Collectors.toList());
        Map<Long, List<ItemImage>> imageMap = itemImageMapper.selectList(
                        new LambdaQueryWrapper<ItemImage>().in(ItemImage::getItemId, itemIds)
                                .orderByAsc(ItemImage::getSortOrder))
                .stream().collect(Collectors.groupingBy(ItemImage::getItemId));

        List<ItemVo> result = new ArrayList<>(items.size());
        for (Item item : items) {
            ItemVo vo = new ItemVo();
            BeanUtils.copyProperties(item, vo);
            vo.setUser(userMap.get(item.getUserId()));
            vo.setImages(extractImages(item, imageMap.get(item.getItemId()), withAllImages));
            signVo(vo);
            result.add(vo);
        }
        return result;
    }

    /** 单个 Item 转 ItemVo。 */
    private ItemVo convertToVo(Item item, boolean withAllImages) {
        ItemVo vo = new ItemVo();
        BeanUtils.copyProperties(item, vo);
        User user = userMapper.selectById(item.getUserId());
        vo.setUser(user);

        List<ItemImage> images = itemImageMapper.selectList(
                new LambdaQueryWrapper<ItemImage>()
                        .eq(ItemImage::getItemId, item.getItemId())
                        .orderByAsc(ItemImage::getSortOrder));
        vo.setImages(extractImages(item, images, withAllImages));
        signVo(vo);
        return vo;
    }

    /** 将 ItemVo 中的图片URL和发布者头像转为签名URL。 */
    private void signVo(ItemVo vo) {
        if (vo == null) {
            return;
        }
        if (StringUtils.hasText(vo.getImage())) {
            vo.setImage(aliOssUtil.signUrl(vo.getImage()));
        }
        if (!CollectionUtils.isEmpty(vo.getImages())) {
            vo.setImages(vo.getImages().stream()
                    .map(aliOssUtil::signUrl)
                    .collect(Collectors.toList()));
        }
        User user = vo.getUser();
        if (user != null && StringUtils.hasText(user.getAvatar())) {
            user.setAvatar(aliOssUtil.signUrl(user.getAvatar()));
        }
    }

    /**
     * 提取图片列表。
     * 列表页（withAllImages=false）只返回封面；详情页返回全部。
     */
    private List<String> extractImages(Item item, List<ItemImage> images, boolean withAllImages) {
        List<String> urls = new ArrayList<>();
        if (!CollectionUtils.isEmpty(images)) {
            urls.addAll(images.stream().map(ItemImage::getUrl).collect(Collectors.toList()));
        }
        // 兜底：item_image 没数据时用 item.image 封面
        if (urls.isEmpty() && StringUtils.hasText(item.getImage())) {
            urls.add(item.getImage());
        }
        if (!withAllImages && urls.size() > 1) {
            return urls.subList(0, 1);
        }
        return urls;
    }

    /** 构造分页结果。 */
    private PageResult buildPageResult(Page<Item> page, List<ItemVo> records) {
        PageResult result = new PageResult();
        result.setTotal(page.getTotal());
        result.setRecords(records);
        result.setPageNum(page.getCurrent());
        result.setPageSize(page.getSize());
        result.setPages(page.getPages());
        return result;
    }
}
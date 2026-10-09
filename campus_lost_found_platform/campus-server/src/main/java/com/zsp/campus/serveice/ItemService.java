package com.zsp.campus.serveice;

import com.zsp.campus.dto.ItemDto;
import com.zsp.campus.result.PageResult;
import com.zsp.campus.vo.ItemVo;

/**
 * 物品服务
 */
public interface ItemService {

    /**
     * 分页查询最新信息列表（首页）。
     *
     * @param type     LOST-寻物 / FOUND-招领，可空
     * @param category 分类名称，可空
     * @param pageNum  页码
     * @param pageSize 每页条数
     * @return 分页结果，records 为 ItemVo
     */
    PageResult pageQuery(String type, String category, Integer pageNum, Integer pageSize);

    /**
     * 获取物品详情，同时浏览量 +1。
     *
     * @param itemId 物品 id
     * @return 物品详情（含发布者信息和完整图片列表）
     */
    ItemVo getDetail(Long itemId);

    /**
     * 发布失物/招领信息。
     *
     * @param dto 发布内容
     * @return 新信息的 itemId
     */
    Long create(ItemDto dto);

    /**
     * 删除信息（只能删除自己发布的，已解决不可删除）。
     *
     * @param itemId 物品 id
     */
    void delete(Long itemId);

    /**
     * 标记已解决（寻物→已找回 / 招领→已归还）。
     *
     * @param itemId 物品 id
     */
    void resolve(Long itemId);

    /**
     * 搜索信息。
     *
     * @param keyword  关键词
     * @param type     LOST / FOUND，可空
     * @param category 分类名称，可空
     * @param pageNum  页码
     * @param pageSize 每页条数
     * @return 分页结果
     */
    PageResult search(String keyword, String type, String category, Integer pageNum, Integer pageSize);

    /**
     * 获取我的发布列表。
     *
     * @param type     LOST / FOUND，可空
     * @param status   状态，可空
     * @param pageNum  页码
     * @param pageSize 每页条数
     * @return 分页结果
     */
    PageResult myItems(String type, String status, Integer pageNum, Integer pageSize);

    /**
     * 修改已发布信息（只能修改自己发布的）。
     *
     * @param itemId 物品 id
     * @param dto    修改内容
     * @return 修改后的物品详情
     */
    ItemVo update(Long itemId, ItemDto dto);
}
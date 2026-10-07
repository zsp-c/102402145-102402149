package com.zsp.campus.constant;

import java.util.List;

/**
 * 物品分类常量。
 *
 * <p>分类固定为 8 类，不单独建表，item 表直接存分类名称。
 * {@link #ALL} 的顺序即前端展示顺序。
 */
public class CategoryConstant {

    /** 证件卡类 */
    public static final String ID_CARD = "证件卡类";
    /** 数码电子 */
    public static final String DIGITAL = "数码电子";
    /** 钥匙门卡 */
    public static final String KEY_CARD = "钥匙门卡";
    /** 箱包 */
    public static final String BAG = "箱包";
    /** 水杯水壶 */
    public static final String CUP = "水杯水壶";
    /** 手表饰品 */
    public static final String WATCH = "手表饰品";
    /** 耳机音频 */
    public static final String EARPHONE = "耳机音频";
    /** 其他物品 */
    public static final String OTHER = "其他物品";

    /** 全部分类。 */
    public static final List<String> ALL =
            List.of(ID_CARD, DIGITAL, KEY_CARD, BAG, CUP, WATCH, EARPHONE, OTHER);

    /** 校验分类名称是否合法，发布物品时用。 */
    public static boolean isValid(String category) {
        return ALL.contains(category);
    }

    private CategoryConstant() {
    }
}

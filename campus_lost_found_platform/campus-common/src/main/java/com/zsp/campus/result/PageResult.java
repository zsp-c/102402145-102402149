package com.zsp.campus.result;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/*
    分页查询返回结果
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageResult {
    private long total; //总记录数

    private List records; //当前页数据集合

}

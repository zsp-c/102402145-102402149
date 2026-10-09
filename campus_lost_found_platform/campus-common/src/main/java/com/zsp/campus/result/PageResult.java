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

    private long pageNum; //当前页码

    private long pageSize; //每页条数

    private long pages; //总页数

    public PageResult(long total, List records) {
        this.total = total;
        this.records = records;
    }
}
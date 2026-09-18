package com.kama.notes.model.entity;

import lombok.Data;

import java.util.Date;

/**
 * 笔记分类实体类
 *
 * 笔记分类独立于题目分类（Category），用于给笔记按技术主题归类，
 * 例如 Redis、SQL、MQ 等。
 */
@Data
public class NoteCategory {
    /*
     * 笔记分类ID（主键）
     */
    private Integer categoryId;

    /*
     * 分类名称
     */
    private String name;

    /*
     * 创建时间
     */
    private Date createdAt;

    /*
     * 更新时间
     */
    private Date updatedAt;
}

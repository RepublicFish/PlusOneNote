package com.kama.notes.mapper;

import com.kama.notes.model.entity.NoteCategory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 笔记分类 Mapper
 */
@Mapper
public interface NoteCategoryMapper {

    /**
     * 新增笔记分类
     *
     * @param noteCategory 笔记分类对象
     * @return 影响行数
     */
    int insert(NoteCategory noteCategory);

    /**
     * 查询全部笔记分类
     *
     * @return 笔记分类列表
     */
    List<NoteCategory> findAll();

    /**
     * 根据分类 ID 查询笔记分类
     *
     * @param categoryId 分类 ID
     * @return 笔记分类，不存在返回 null
     */
    NoteCategory findById(Integer categoryId);

    /**
     * 根据分类名称查询笔记分类
     *
     * @param name 分类名称
     * @return 笔记分类，不存在返回 null
     */
    NoteCategory findByName(String name);

    /**
     * 批量根据分类 ID 查询笔记分类
     *
     * @param categoryIds 分类 ID 列表
     * @return 笔记分类列表
     */
    List<NoteCategory> findByIdBatch(@Param("categoryIds") List<Integer> categoryIds);
}

package com.kama.notes.service;

import com.kama.notes.model.base.ApiResponse;
import com.kama.notes.model.dto.noteCategory.CreateNoteCategoryBody;
import com.kama.notes.model.entity.NoteCategory;
import com.kama.notes.model.vo.noteCategory.NoteCategoryVO;

import java.util.List;
import java.util.Map;

/**
 * 笔记分类服务
 */
public interface NoteCategoryService {

    /**
     * 获取笔记分类列表
     */
    ApiResponse<List<NoteCategoryVO>> listCategories();

    /**
     * 创建笔记分类
     */
    ApiResponse<NoteCategoryVO> createCategory(CreateNoteCategoryBody body);

    /**
     * 根据分类 ID 查询笔记分类
     */
    NoteCategory findById(Integer categoryId);

    /**
     * 批量查询笔记分类，返回 categoryId -> NoteCategory 的映射
     */
    Map<Integer, NoteCategory> getCategoryMapByIds(List<Integer> categoryIds);
}

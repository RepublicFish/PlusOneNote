package com.kama.notes.service.impl;

import com.kama.notes.annotation.NeedLogin;
import com.kama.notes.mapper.NoteCategoryMapper;
import com.kama.notes.model.base.ApiResponse;
import com.kama.notes.model.dto.noteCategory.CreateNoteCategoryBody;
import com.kama.notes.model.entity.NoteCategory;
import com.kama.notes.model.vo.noteCategory.NoteCategoryVO;
import com.kama.notes.service.NoteCategoryService;
import com.kama.notes.utils.ApiResponseUtil;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Log4j2
@Service
public class NoteCategoryServiceImpl implements NoteCategoryService {

    @Autowired
    private NoteCategoryMapper noteCategoryMapper;

    @Override
    public ApiResponse<List<NoteCategoryVO>> listCategories() {
        try {
            List<NoteCategoryVO> categoryVOList = noteCategoryMapper.findAll().stream()
                    .map(this::toVO)
                    .toList();
            return ApiResponseUtil.success("获取笔记分类列表成功", categoryVOList);
        } catch (Exception e) {
            log.error("获取笔记分类列表失败", e);
            return ApiResponseUtil.error("获取笔记分类列表失败");
        }
    }

    @Override
    @NeedLogin
    public ApiResponse<NoteCategoryVO> createCategory(CreateNoteCategoryBody body) {
        String name = body.getName() == null ? "" : body.getName().trim();
        if (name.isEmpty()) {
            return ApiResponseUtil.error("分类名称不能为空");
        }

        // 同名分类直接返回，避免重复创建
        NoteCategory existed = noteCategoryMapper.findByName(name);
        if (existed != null) {
            return ApiResponseUtil.success("该分类已存在", toVO(existed));
        }

        NoteCategory noteCategory = new NoteCategory();
        noteCategory.setName(name);

        try {
            noteCategoryMapper.insert(noteCategory);
            return ApiResponseUtil.success("创建笔记分类成功", toVO(noteCategory));
        } catch (Exception e) {
            log.error("创建笔记分类失败", e);
            return ApiResponseUtil.error("创建笔记分类失败");
        }
    }

    @Override
    public NoteCategory findById(Integer categoryId) {
        if (categoryId == null) {
            return null;
        }
        return noteCategoryMapper.findById(categoryId);
    }

    @Override
    public Map<Integer, NoteCategory> getCategoryMapByIds(List<Integer> categoryIds) {
        if (categoryIds == null || categoryIds.isEmpty()) {
            return Collections.emptyMap();
        }
        return noteCategoryMapper.findByIdBatch(categoryIds).stream()
                .collect(Collectors.toMap(NoteCategory::getCategoryId, Function.identity(), (a, b) -> a));
    }

    private NoteCategoryVO toVO(NoteCategory noteCategory) {
        NoteCategoryVO vo = new NoteCategoryVO();
        vo.setCategoryId(noteCategory.getCategoryId());
        vo.setName(noteCategory.getName());
        return vo;
    }
}

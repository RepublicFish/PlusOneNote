package com.kama.notes.controller;

import com.kama.notes.model.base.ApiResponse;
import com.kama.notes.model.dto.noteCategory.CreateNoteCategoryBody;
import com.kama.notes.model.vo.noteCategory.NoteCategoryVO;
import com.kama.notes.service.NoteCategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.validation.Valid;
import java.util.List;

/**
 * 笔记分类控制器
 *
 * 与题目分类（/api/categories）不同，这里的分类专门用于给笔记归类，
 * 例如 Redis、SQL、MQ 等主题。
 */
@RestController
@RequestMapping("/api")
public class NoteCategoryController {

    @Autowired
    private NoteCategoryService noteCategoryService;

    /**
     * 获取笔记分类列表
     */
    @GetMapping("/note-categories")
    public ApiResponse<List<NoteCategoryVO>> listNoteCategories() {
        return noteCategoryService.listCategories();
    }

    /**
     * 创建笔记分类（需登录）
     */
    @PostMapping("/note-categories")
    public ApiResponse<NoteCategoryVO> createNoteCategory(
            @Valid @RequestBody CreateNoteCategoryBody body) {
        return noteCategoryService.createCategory(body);
    }
}

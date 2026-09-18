package com.kama.notes.model.dto.noteCategory;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 创建笔记分类请求 DTO
 */
@Data
public class CreateNoteCategoryBody {
    /*
     * 分类名称
     */
    @NotBlank(message = "分类名称不能为空")
    @Size(max = 64, message = "分类名称不能超过 64 个字符")
    private String name;
}

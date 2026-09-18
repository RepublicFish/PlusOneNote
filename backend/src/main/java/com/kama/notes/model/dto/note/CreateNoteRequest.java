package com.kama.notes.model.dto.note;

import lombok.Data;

import javax.validation.constraints.Min;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * 发布笔记请求DTO
 *
 * 支持两种类型的笔记：
 * 1. 题目笔记：指定 questionId（原有能力）
 * 2. 分类笔记：指定 categoryId，不绑定题目（新增能力）
 *
 * questionId 与 categoryId 至少需要提供一个。
 */
@Data
public class CreateNoteRequest {
    /*
     * 问题ID
     * 可为空，为空表示该笔记不绑定题目
     */
    @Min(value = 1, message = "问题 ID 必须为正整数")
    private Integer questionId;

    /*
     * 笔记分类ID
     * 可为空，与 questionId 至少提供一个
     */
    @Min(value = 1, message = "笔记分类 ID 必须为正整数")
    private Integer categoryId;

    /*
     * 笔记内容
     */
    @NotBlank(message = "笔记内容不能为空")
    @NotNull(message = "笔记内容不能为空")
    private String content;
}

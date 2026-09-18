import { httpClient } from '@/request'
import { noteCategoryApiList } from '../api/noteCategoryApi.ts'
import { NoteCategory } from '../types/types.ts'

export const noteCategoryService = {
  /**
   * 获取笔记分类列表
   */
  getNoteCategoryList: () => {
    return httpClient.request<NoteCategory[]>(
      noteCategoryApiList.getNoteCategories,
    )
  },

  /**
   * 创建笔记分类
   */
  createNoteCategory: (name: string) => {
    return httpClient.request<NoteCategory>(
      noteCategoryApiList.createNoteCategory,
      {
        body: { name },
      },
    )
  },
}

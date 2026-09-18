import { ApiList } from '@/request'

export const noteCategoryApiList: ApiList = {
  /** 获取笔记分类列表 */
  getNoteCategories: ['GET', '/api/note-categories'],
  /** 创建笔记分类 */
  createNoteCategory: ['POST', '/api/note-categories'],
}

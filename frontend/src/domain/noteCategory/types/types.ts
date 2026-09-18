/**
 * 笔记分类
 *
 * 与题目分类（Category）不同，笔记分类专门用于给笔记按技术主题归类，
 * 例如 Redis、SQL、MQ 等。
 */
export interface NoteCategory {
  /** 笔记分类 ID */
  categoryId: number

  /** 分类名称 */
  name: string
}

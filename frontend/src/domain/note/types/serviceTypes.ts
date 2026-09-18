/** noteService 接口需要使用 */
import { SortOrder } from '../../../base/types'
import { Author, NoteEntity, UserActions } from './types.ts'
import { QuestionSummary } from '../../question'
import { NoteCategory } from '../../noteCategory'

/**
 * 查询笔记列表查询参数
 */
export interface NoteQueryParams {
  questionId?: number
  categoryId?: number
  authorId?: string
  collectionId?: number
  sort?: 'create'
  order?: SortOrder
  recentDays?: number
  page: number
  pageSize: number
}

/**
 * 返回的笔记列表
 *
 * 包含作者信息、题目信息、笔记分类信息、展示内容
 */
export type NoteWithRelations = Omit<
  NoteEntity,
  'authorId' | 'questionId' | 'updatedAt'
> & {
  needCollapsed: boolean // 是否需要折叠真实的笔记，显示展示内容
  displayContent: string // 展示内容
  author: Author // 作者相关信息
  question?: QuestionSummary // 题目相关信息（分类笔记没有题目）
  category?: NoteCategory // 笔记分类信息（题目笔记没有分类）
  userActions: UserActions | undefined // 用户操作信息
}

/**
 * 创建笔记服务参数类型
 *
 * questionId 与 categoryId 至少提供一个：
 * - 传 questionId：题目笔记
 * - 传 categoryId：分类笔记（不绑定题目）
 */
export interface CreateNoteParams {
  content: string
  questionId?: number
  categoryId?: number
}

/**
 * 排行榜列表类型
 */
export interface NoteRankListItem {
  userId: string
  username: string
  avatarUrl: string
  noteCount: number
  rank: number
}

/**
 * 热力图类型
 */
export interface NoteHeatMapItem {
  date: Date
  count: number
  rank: number
}

/**
 * top3 类型
 */
export interface NoteTop3Count {
  lastMonthTop3Count: number
  thisMonthTop3Count: number
}

/**
 * 下载笔记类型
 */
export interface DownloadNote {
  markdown: string
}

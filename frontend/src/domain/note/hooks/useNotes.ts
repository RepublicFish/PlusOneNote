import { useEffect, useState } from 'react'
import {
  CreateNoteParams,
  NoteQueryParams,
  NoteWithRelations,
} from '../types/serviceTypes.ts'
import { noteService } from '../service/noteService.ts'
import { Pagination } from '../../../request'
import { message } from 'antd'
import { useUser } from '../../user/hooks/useUser.ts'
import { NoteCategory } from '../../noteCategory'

/**
 * 获取笔记列表
 */
export function useNotes(noteQueryParams: NoteQueryParams) {
  /**
   * 笔记列表
   */
  const [noteList, setNoteList] = useState<NoteWithRelations[]>([])
  const [loading, setLoading] = useState(false)

  const user = useUser()

  /**
   * 分页参数
   */
  const [pagination, setPagination] = useState<Pagination>()

  useEffect(() => {
    async function fetchData() {
      setLoading(true)
      const { data, pagination } =
        await noteService.getNoteList(noteQueryParams)
      setNoteList(data)
      setPagination(pagination)
      setLoading(false)
    }

    fetchData().then()
  }, [
    noteQueryParams,
    noteQueryParams.authorId,
    noteQueryParams.questionId,
    noteQueryParams.categoryId,
    noteQueryParams.collectionId,
    noteQueryParams.page,
    noteQueryParams.pageSize,
    noteQueryParams.sort,
    noteQueryParams.order,
    noteQueryParams.recentDays,
  ])

  function createNewNoteWithRelations(
    params: CreateNoteParams,
    noteId: number,
    category?: NoteCategory,
  ): NoteWithRelations {
    return {
      noteId,
      content: params.content,
      needCollapsed: true,
      displayContent: params.content,
      likeCount: 0,
      commentCount: 0,
      collectCount: 0,
      createdAt: new Date().toISOString(),
      author: {
        userId: user.userId,
        username: user.username,
        avatarUrl: user.avatarUrl,
      },
      // 题目笔记才有题目信息
      question: params.questionId
        ? {
            questionId: params.questionId,
            title: '',
          }
        : undefined,
      // 分类笔记才有分类信息
      category: category,
      userActions: {
        isLiked: false,
        isCollected: false,
      },
    }
  }

  /**
   * 创建笔记
   *
   * @param params 创建参数：题目笔记传 questionId，分类笔记传 categoryId
   * @param category 分类笔记的分类信息，用于本地列表即时展示
   */
  async function createNoteHandle(
    params: CreateNoteParams,
    category?: NoteCategory,
  ): Promise<number | undefined> {
    if (!params.content.trim()) {
      message.info('笔记内容为空')
      return
    }

    // data == noteId
    const { data } = await noteService.createNoteService(params)

    setNoteList((prevNoteList) => {
      return [
        createNewNoteWithRelations(params, data.noteId, category),
        ...prevNoteList,
      ]
    })
    return data.noteId
  }

  /**
   * 更新笔记（修改正文）
   *
   * 除了 content，同时刷新列表用于折叠展示的 displayContent，
   * 并取消折叠，否则列表里仍会显示修改前的摘要。
   */
  async function updateNoteHandle(
    noteId: number,
    updateBody: CreateNoteParams,
  ) {
    await noteService.updateNoteService(noteId, updateBody)

    setNoteList((prevNoteList) => {
      return prevNoteList.map((note) => {
        if (note.noteId === noteId) {
          return {
            ...note,
            content: updateBody.content,
            displayContent: updateBody.content,
            needCollapsed: false,
          }
        }
        return note
      })
    })
  }

  /**
   * 设置笔记点赞状态
   */
  function setNoteLikeStatusHandle(noteId: number, isLiked: boolean) {
    if (!noteId) return
    setNoteList((prevNoteList) => {
      return prevNoteList.map((item) => {
        if (item.noteId === noteId && item.userActions) {
          return {
            ...item,
            likeCount: isLiked ? item.likeCount + 1 : item.likeCount - 1,
            userActions: {
              ...item.userActions,
              isLiked,
            },
          }
        }
        return item
      })
    })
  }

  /**
   * 设置笔记收藏状态
   */
  function setNoteCollectStatusHandle(noteId: number, isCollected: boolean) {
    if (!noteId) return
    setNoteList((prevNoteList) => {
      return prevNoteList.map((item) => {
        if (item.noteId === noteId && item.userActions) {
          return {
            ...item,
            collectCount: isCollected
              ? item.collectCount + 1
              : item.collectCount - 1,
            userActions: {
              ...item.userActions,
              isCollected,
            },
          }
        }
        return item
      })
    })
  }

  /**
   * 从当前列表中移除某条笔记
   * 用于「删除笔记」成功后，让该笔记立刻从列表里消失
   */
  function removeNoteHandle(noteId: number) {
    setNoteList((prevNoteList) =>
      prevNoteList.filter((note) => note.noteId !== noteId),
    )
  }

  return {
    loading,
    noteList,
    pagination,
    createNoteHandle,
    updateNoteHandle,
    removeNoteHandle,
    setNoteLikeStatusHandle,
    setNoteCollectStatusHandle,
  }
}

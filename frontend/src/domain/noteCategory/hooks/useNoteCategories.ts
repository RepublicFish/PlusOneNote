import { useCallback, useEffect, useState } from 'react'
import { NoteCategory } from '../types/types.ts'
import { noteCategoryService } from '../service/noteCategoryService.ts'

/**
 * 笔记分类列表
 *
 * 提供笔记分类的获取与创建能力，供「笔记分类」页与「创建笔记」页复用。
 */
export function useNoteCategories() {
  const [noteCategories, setNoteCategories] = useState<NoteCategory[]>([])
  const [loading, setLoading] = useState(false)

  /**
   * 获取笔记分类列表
   */
  const fetchNoteCategories = useCallback(async () => {
    setLoading(true)
    try {
      const { data } = await noteCategoryService.getNoteCategoryList()
      setNoteCategories(data ?? [])
    } catch (error) {
      console.error('获取笔记分类失败:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchNoteCategories().then()
  }, [fetchNoteCategories])

  /**
   * 创建笔记分类，成功后会同步加入本地列表
   */
  const createNoteCategory = useCallback(async (name: string) => {
    const { data } = await noteCategoryService.createNoteCategory(name)
    setNoteCategories((prev) => {
      if (prev.some((item) => item.categoryId === data.categoryId)) {
        return prev
      }
      return [...prev, data]
    })
    return data
  }, [])

  return {
    noteCategories,
    loading,
    fetchNoteCategories,
    createNoteCategory,
  }
}

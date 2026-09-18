import React, { useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { Button, Divider, Empty, Skeleton, Tag } from 'antd'
import { EditOutlined } from '@ant-design/icons'
import { NoteList, NoteQueryParams, useNotes } from '../../../../domain/note'
import { useNoteCategories } from '../../../../domain/noteCategory'
import { Panel } from '../../../../base/components'
import { NOTE_CREATE } from '../../router/config.ts'

/**
 * 笔记分类页
 *
 * 展示全部笔记分类，并支持按分类筛选笔记。
 * 与首页不同的是：这里的笔记既可能是「题目笔记」，也可能是「分类笔记」。
 */
const NoteCategoryPage: React.FC = () => {
  const navigate = useNavigate()
  const [urlSearchParams, setUrlSearchParams] = useSearchParams()

  /**
   * 地址栏中的分类 ID（从「创建笔记」页跳转过来时携带）
   */
  const categoryIdFromUrl = urlSearchParams.get('categoryId')
  const initialCategoryId = categoryIdFromUrl
    ? Number(categoryIdFromUrl)
    : undefined

  /**
   * 当前选中的分类 ID（undefined 表示全部）
   */
  const [selectedCategoryId, setSelectedCategoryId] = useState<
    number | undefined
  >(initialCategoryId)

  /**
   * 笔记分类列表
   */
  const { noteCategories, loading: categoryLoading } = useNoteCategories()

  /**
   * 笔记查询参数
   */
  const [noteQueryParams, setNoteQueryParams] = useState<NoteQueryParams>({
    page: 1,
    pageSize: 10,
    sort: 'create',
    order: 'desc',
    categoryId: initialCategoryId,
  })

  const setNoteQueryParamsHandle = (params: NoteQueryParams) => {
    setNoteQueryParams((prev) => ({ ...prev, ...params }))
  }

  const {
    noteList,
    pagination,
    setNoteLikeStatusHandle,
    setNoteCollectStatusHandle,
    removeNoteHandle,
    updateNoteHandle,
    loading,
  } = useNotes(noteQueryParams)

  /**
   * 切换分类
   */
  const selectCategoryHandle = (categoryId?: number) => {
    setSelectedCategoryId(categoryId)
    setNoteQueryParams((prev) => ({ ...prev, page: 1, categoryId }))

    // 同步到地址栏，便于刷新与分享
    if (categoryId === undefined) {
      setUrlSearchParams({})
    } else {
      setUrlSearchParams({ categoryId: String(categoryId) })
    }
  }

  const selectedCategoryName = noteCategories.find(
    (category) => category.categoryId === selectedCategoryId,
  )?.name

  return (
    <div className="flex justify-center">
      <div className="w-[700px]">
        <Panel>
          <div className="flex items-center justify-between">
            <div className="text-sm font-semibold text-neutral-800">
              笔记分类
            </div>
            <Button
              type="primary"
              icon={<EditOutlined />}
              onClick={() => navigate(NOTE_CREATE)}
            >
              写笔记
            </Button>
          </div>
          <Divider />
          <Skeleton loading={categoryLoading} active>
            <div className="flex flex-wrap items-center gap-2">
              <Tag.CheckableTag
                checked={selectedCategoryId === undefined}
                onChange={() => selectCategoryHandle(undefined)}
              >
                全部
              </Tag.CheckableTag>
              {noteCategories.map((category) => (
                <Tag.CheckableTag
                  key={category.categoryId}
                  checked={selectedCategoryId === category.categoryId}
                  onChange={() => selectCategoryHandle(category.categoryId)}
                >
                  {category.name}
                </Tag.CheckableTag>
              ))}
              {noteCategories.length === 0 && (
                <span className="text-xs text-neutral-400">
                  暂无分类，去「写笔记」页创建一个吧
                </span>
              )}
            </div>
          </Skeleton>
        </Panel>
        <Panel>
          <div className="text-sm font-semibold text-neutral-800">
            {selectedCategoryId === undefined
              ? '全部笔记'
              : `${selectedCategoryName ?? '分类'} 笔记`}
          </div>
          <Divider />
          <Skeleton loading={loading} active>
            {noteList.length === 0 && !loading ? (
              <Empty description={'暂无笔记'} />
            ) : (
              <NoteList
                noteList={noteList}
                pagination={pagination}
                queryParams={noteQueryParams}
                setQueryParams={setNoteQueryParamsHandle}
                setNoteLikeStatusHandle={setNoteLikeStatusHandle}
                setNoteCollectStatusHandle={setNoteCollectStatusHandle}
                onNoteDeleted={removeNoteHandle}
                onSaveNoteContent={(noteId, content) =>
                  updateNoteHandle(noteId, { content })
                }
              />
            )}
          </Skeleton>
        </Panel>
      </div>
    </div>
  )
}

export default NoteCategoryPage

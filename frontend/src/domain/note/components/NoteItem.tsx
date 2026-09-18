import React, { useEffect, useState } from 'react'
import { NoteWithRelations } from '../types/serviceTypes.ts'

import AuthorCard from './AuthorCard.tsx'
import { QuestionCard } from '../../question'
import NoteContent from './NoteContent.tsx'
import DisplayContent from './DisplayContent.tsx'
import ExpandButton from './ExpandButton.tsx'
import { Divider, Tag } from 'antd'
import { Link } from 'react-router-dom'
import OptionsCard from './OptionsCard.tsx'
import { NOTE_CATEGORY } from '../../../apps/user/router/config.ts'

interface NoteItemProps {
  note?: NoteWithRelations
  setNoteLikeStatus?: (noteId: number, isLiked: boolean) => void
  /** 控制模态框的展示 */
  toggleIsModalOpen: () => void
  /** 设置查询收藏夹参数和设置被选中的笔记 ID */
  handleCollectionQueryParams: (noteId: number) => void
  handleSelectedNoteId: (noteId: number) => void
  /** 控制组件信息展示 */
  showAuthor?: boolean // 是否展示作者信息
  showQuestion?: boolean // 是否展示题目信息
  showOptions?: boolean // 是否展示点赞/收藏/评论等按钮
  onRefresh?: () => void
  /** 删除笔记成功后的回调（用于把该笔记从列表中移除） */
  onNoteDeleted?: (noteId: number) => void
  /** 保存笔记正文（修改笔记） */
  onSaveNoteContent?: (noteId: number, content: string) => Promise<unknown>
}

const NoteItem: React.FC<NoteItemProps> = ({
  note,
  setNoteLikeStatus,
  showAuthor = true,
  showQuestion = true,
  showOptions = true,
  toggleIsModalOpen,
  handleCollectionQueryParams,
  handleSelectedNoteId,
  onRefresh,
  onNoteDeleted,
  onSaveNoteContent,
}) => {
  const [isCollapsed, setIsCollapsed] = useState(false)

  const toggleCollapsed = () => {
    setIsCollapsed(!isCollapsed)
  }

  useEffect(() => {
    if (note?.needCollapsed) {
      setIsCollapsed(true)
    }
  }, [])

  return (
    <>
      <div className="flex w-full flex-col gap-4">
        {/* 题目笔记展示题目；分类笔记展示分类标签 */}
        {showQuestion && note?.question && (
          <QuestionCard question={note.question} />
        )}
        {note?.category && (
          <div>
            <Link
              to={`${NOTE_CATEGORY}?categoryId=${note.category.categoryId}`}
            >
              <Tag color="blue" className="cursor-pointer">
                {note.category.name}
              </Tag>
            </Link>
          </div>
        )}
        {showAuthor && <AuthorCard note={note} />}
        {isCollapsed ? (
          <DisplayContent displayContent={note?.displayContent ?? ''} />
        ) : (
          <NoteContent note={note} />
        )}
        {note?.needCollapsed && (
          <ExpandButton
            toggleCollapsed={toggleCollapsed}
            isCollapsed={isCollapsed}
            key={note?.noteId}
          />
        )}
        {showOptions && (
          <OptionsCard
            note={note}
            setNoteLikeStatus={setNoteLikeStatus}
            toggleIsModalOpen={toggleIsModalOpen}
            handleCollectionQueryParams={handleCollectionQueryParams}
            handleSelectedNoteId={handleSelectedNoteId}
            onRefresh={onRefresh}
            onNoteDeleted={onNoteDeleted}
            onSaveNoteContent={onSaveNoteContent}
          />
        )}
      </div>
      <Divider />
    </>
  )
}

export default NoteItem

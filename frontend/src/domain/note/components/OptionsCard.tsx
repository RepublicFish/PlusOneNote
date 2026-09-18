import React, { Suspense, useState, useEffect } from 'react'
import { NoteWithRelations } from '../types/serviceTypes.ts'
import { Button, Drawer, message, Modal, Popconfirm, Spin } from 'antd'
import {
  LikeOutlined,
  LikeFilled,
  StarOutlined,
  StarFilled,
  MessageOutlined,
  DeleteOutlined,
  EditOutlined,
} from '@ant-design/icons'
import { useNoteLike } from '../../noteLike'
import { useApp } from '@/base/hooks'
import { useUser } from '../../user/hooks/useUser.ts'
import { noteService } from '../service/noteService.ts'
import { MarkdownEditor } from '@/base/components'
import CommentList from '@/domain/comment/components/CommentList'

interface OptionsCardProps {
  note?: NoteWithRelations
  setNoteLikeStatus?: (noteId: number, isLiked: boolean) => void
  toggleIsModalOpen: () => void
  handleCollectionQueryParams: (noteId: number) => void
  handleSelectedNoteId: (noteId: number) => void
  onRefresh?: () => void
  /** 删除笔记成功后的回调，用于把该笔记从列表中移除 */
  onNoteDeleted?: (noteId: number) => void
  /** 保存笔记正文（修改笔记）。由列表页注入，内部负责调用更新接口并同步列表状态 */
  onSaveNoteContent?: (noteId: number, content: string) => Promise<unknown>
}

const OptionsCard: React.FC<OptionsCardProps> = ({
  note,
  setNoteLikeStatus,
  toggleIsModalOpen,
  handleCollectionQueryParams,
  handleSelectedNoteId,
  onRefresh,
  onNoteDeleted,
  onSaveNoteContent,
}) => {
  const { like, unLike } = useNoteLike()
  const [commentDrawerVisible, setCommentDrawerVisible] = useState(false)
  const [localCommentCount, setLocalCommentCount] = useState(0)
  const app = useApp()
  const user = useUser()
  let likeLoading = false

  /**
   * 修改笔记相关状态
   */
  const [editVisible, setEditVisible] = useState(false)
  const [editContent, setEditContent] = useState('')
  const [saving, setSaving] = useState(false)

  /**
   * 是否为当前登录用户自己的笔记（决定是否显示「编辑 / 删除」）
   *
   * 后端返回的 userId 是数字，而前端类型标注为 string，
   * 因此统一转成字符串再比较，避免类型不一致导致按钮不显示。
   */
  const isAuthor =
    !!note?.author && String(note.author.userId) === String(user.userId)

  useEffect(() => {
    if (note?.commentCount !== undefined) {
      setLocalCommentCount(note.commentCount)
    }
  }, [note?.commentCount])

  /**
   * 点赞按钮点击处理函数
   */
  async function likeButtonClickHandle() {
    if (!app.isLogin) {
      message.info('请先登录')
      return
    }

    if (!setNoteLikeStatus || !note || !note.userActions) return

    if (likeLoading) return

    likeLoading = true
    setNoteLikeStatus(note.noteId, !note.userActions.isLiked)

    if (note.userActions.isLiked) {
      await unLike(note.noteId)
    } else {
      await like(note.noteId)
    }

    likeLoading = false
  }

  /**
   * 收藏按钮点击处理函数
   */
  async function collectButtonClickHandle() {
    if (!app.isLogin) {
      message.info('请先登录')
      return
    }
    if (!note || !note.userActions) return

    toggleIsModalOpen()
    handleCollectionQueryParams(note.noteId)
    handleSelectedNoteId(note.noteId)
  }

  /**
   * 评论按钮点击处理函数
   */
  const handleCommentClick = async () => {
    if (!app.isLogin) {
      message.info('请先登录')
      return
    }
    setCommentDrawerVisible(true)
  }

  // 评论成功后刷新笔记数据
  const handleCommentSuccess = () => {
    onRefresh?.()
  }

  /**
   * 打开「修改笔记」弹窗，预填当前正文
   */
  function openEditHandle() {
    setEditContent(note?.content ?? '')
    setEditVisible(true)
  }

  /**
   * 保存修改（仅作者本人可操作）
   */
  async function saveEditHandle() {
    if (!note) return

    if (!editContent.trim()) {
      message.info('笔记内容为空')
      return
    }

    if (!onSaveNoteContent) {
      message.error('当前页面不支持修改笔记')
      return
    }

    setSaving(true)
    try {
      await onSaveNoteContent(note.noteId, editContent)
      message.success('笔记修改成功')
      setEditVisible(false)
    } catch (e: any) {
      message.error(e?.message || '笔记修改失败')
    } finally {
      setSaving(false)
    }
  }

  /**
   * 删除笔记（仅作者本人可操作）
   */
  async function deleteNoteHandle() {
    if (!note) return
    try {
      await noteService.deleteNoteService(note.noteId)
      message.success('删除笔记成功')
      // 通知列表把该笔记移除
      onNoteDeleted?.(note.noteId)
    } catch (e: any) {
      message.error(e?.message || '删除笔记失败')
    }
  }

  return (
    <>
      <div className="flex items-center space-x-4">
        <Button
          type="text"
          className="flex items-center"
          icon={note?.userActions?.isLiked ? <LikeFilled /> : <LikeOutlined />}
          onClick={likeButtonClickHandle}
        >
          {note?.likeCount || 0} 次点赞
        </Button>
        <Button
          type="text"
          className="flex items-center"
          icon={
            note?.userActions?.isCollected ? <StarFilled /> : <StarOutlined />
          }
          onClick={collectButtonClickHandle}
        >
          {note?.collectCount || 0} 次收藏
        </Button>
        <Button
          type="text"
          className="flex items-center"
          icon={<MessageOutlined />}
          onClick={handleCommentClick}
        >
          {localCommentCount} 条评论
        </Button>
        {/* 仅笔记作者本人可以看到并执行「修改 / 删除」 */}
        {app.isLogin && isAuthor && (
          <>
            <Button
              type="text"
              className="flex items-center"
              icon={<EditOutlined />}
              onClick={openEditHandle}
            >
              编辑
            </Button>
            <Popconfirm
              title="确认删除这条笔记？"
              description="该笔记下的评论、点赞、收藏也会一并清除，且不可恢复。"
              okText="删除"
              cancelText="取消"
              okButtonProps={{ danger: true }}
              onConfirm={deleteNoteHandle}
            >
              <Button
                type="text"
                danger
                className="flex items-center"
                icon={<DeleteOutlined />}
              >
                删除
              </Button>
            </Popconfirm>
          </>
        )}
      </div>

      <Drawer
        title="评论"
        placement="right"
        width={500}
        onClose={() => setCommentDrawerVisible(false)}
        open={commentDrawerVisible}
      >
        {note && (
          <CommentList
            noteId={note.noteId}
            onCommentCountChange={handleCommentSuccess}
          />
        )}
      </Drawer>

      {/* 修改笔记弹窗 */}
      <Modal
        title="修改笔记"
        open={editVisible}
        onCancel={() => setEditVisible(false)}
        onOk={saveEditHandle}
        okText="保存"
        cancelText="取消"
        confirmLoading={saving}
        width={1000}
        destroyOnClose
      >
        <div style={{ height: '60vh' }}>
          <Suspense
            fallback={
              <Spin tip="加载编辑器中" className="mt-12">
                {''}
              </Spin>
            }
          >
            <MarkdownEditor value={editContent} setValue={setEditContent} />
          </Suspense>
        </div>
      </Modal>
    </>
  )
}

export default OptionsCard

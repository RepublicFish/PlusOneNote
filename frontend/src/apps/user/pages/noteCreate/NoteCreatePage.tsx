import React, { Suspense, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button, Divider, Input, message, Modal, Select, Spin } from 'antd'
import { EyeOutlined, PlusOutlined, UploadOutlined } from '@ant-design/icons'
import {
  MarkdownEditor,
  MarkdownRender,
  Panel,
} from '../../../../base/components'
import { useNoteCategories } from '../../../../domain/noteCategory'
import { noteService } from '../../../../domain/note/service/noteService.ts'
import { LoginModal } from '../../../../domain/user'
import { useApp } from '@/base/hooks'
import { NOTE_CATEGORY } from '../../router/config.ts'

/**
 * 创建笔记页
 *
 * 支持自由选择「笔记分类」（Redis / SQL / MQ ...），
 * 笔记不再必须绑定某个题目。
 */
const NoteCreatePage: React.FC = () => {
  const app = useApp()
  const navigate = useNavigate()

  /**
   * 笔记分类列表 + 新建分类能力
   */
  const {
    noteCategories,
    loading: categoryLoading,
    createNoteCategory,
  } = useNoteCategories()

  /**
   * 笔记内容
   */
  const [content, setContent] = useState('')

  /**
   * 选中的笔记分类
   */
  const [categoryId, setCategoryId] = useState<number>()

  /**
   * 新建分类的输入框
   */
  const [newCategoryName, setNewCategoryName] = useState('')
  const [creatingCategory, setCreatingCategory] = useState(false)

  /**
   * 提交状态
   */
  const [submitting, setSubmitting] = useState(false)

  /**
   * 预览
   */
  const [isShowPreview, setIsShowPreview] = useState(false)

  /**
   * 新建分类
   */
  const createCategoryHandle = async () => {
    const name = newCategoryName.trim()
    if (!name) {
      message.info('请输入分类名称')
      return
    }

    setCreatingCategory(true)
    try {
      const created = await createNoteCategory(name)
      setCategoryId(created.categoryId)
      setNewCategoryName('')
      message.success('分类创建成功')
    } catch (e: any) {
      message.error(e.message || '创建分类失败')
    } finally {
      setCreatingCategory(false)
    }
  }

  /**
   * 提交笔记
   */
  const submitHandle = async () => {
    if (!categoryId) {
      message.info('请选择笔记分类')
      return
    }
    if (!content.trim()) {
      message.info('笔记内容为空')
      return
    }

    setSubmitting(true)
    try {
      // 分类笔记：只传 categoryId，不绑定题目
      await noteService.createNoteService({ content, categoryId })
      message.success('笔记创建成功')
      navigate(`${NOTE_CATEGORY}?categoryId=${categoryId}`)
    } catch (e: any) {
      message.error(e.message || '创建笔记失败')
    } finally {
      setSubmitting(false)
    }
  }

  /**
   * 未登录时提示登录
   */
  if (!app.isLogin) {
    return (
      <div className="flex w-full justify-center">
        <div className="w-[700px]">
          <Panel>
            <div className="flex flex-col items-center gap-4 py-16">
              <div className="text-neutral-600">登录后才能创建笔记</div>
              <LoginModal />
            </div>
          </Panel>
        </div>
      </div>
    )
  }

  return (
    <div className="flex w-full justify-center">
      <div className="w-[900px]">
        <Panel>
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-semibold text-neutral-800">
              笔记分类：
            </span>
            <Select
              style={{ width: 200 }}
              placeholder="请选择笔记分类"
              value={categoryId}
              onChange={(value) => setCategoryId(value)}
              loading={categoryLoading}
              showSearch
              optionFilterProp="label"
              options={noteCategories.map((category) => ({
                label: category.name,
                value: category.categoryId,
              }))}
            />
            <Input
              style={{ width: 180 }}
              placeholder="新建分类名称"
              value={newCategoryName}
              onChange={(e) => setNewCategoryName(e.target.value)}
              onPressEnter={createCategoryHandle}
            />
            <Button
              icon={<PlusOutlined />}
              loading={creatingCategory}
              onClick={createCategoryHandle}
            >
              新建分类
            </Button>
          </div>
          <Divider />
          <div className="h-[calc(100vh-var(--header-height)-230px)]">
            <Suspense
              fallback={
                <Spin tip="加载编辑器中" className="mt-12">
                  {''}
                </Spin>
              }
            >
              <MarkdownEditor value={content} setValue={setContent} />
            </Suspense>
          </div>
          <div className="sticky bottom-0 z-20 flex justify-end gap-2 border-t border-gray-200 bg-white p-4 shadow">
            <Button
              icon={<EyeOutlined />}
              onClick={() => setIsShowPreview(true)}
            >
              预览笔记
            </Button>
            <Button
              type="primary"
              icon={<UploadOutlined />}
              loading={submitting}
              onClick={submitHandle}
            >
              提交笔记
            </Button>
          </div>
        </Panel>
      </div>
      <Modal
        open={isShowPreview}
        onCancel={() => setIsShowPreview(false)}
        footer={null}
        width={1000}
      >
        <MarkdownRender markdown={content} />
      </Modal>
    </div>
  )
}

export default NoteCreatePage

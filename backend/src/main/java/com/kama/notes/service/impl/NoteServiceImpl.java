package com.kama.notes.service.impl;

import com.kama.notes.annotation.NeedLogin;
import com.kama.notes.mapper.CollectionNoteMapper;
import com.kama.notes.mapper.CommentLikeMapper;
import com.kama.notes.mapper.CommentMapper;
import com.kama.notes.mapper.NoteCollectMapper;
import com.kama.notes.mapper.NoteLikeMapper;
import com.kama.notes.mapper.QuestionMapper;
import com.kama.notes.model.base.ApiResponse;
import com.kama.notes.model.base.EmptyVO;
import com.kama.notes.model.base.Pagination;
import com.kama.notes.model.dto.note.CreateNoteRequest;
import com.kama.notes.model.dto.note.NoteQueryParams;
import com.kama.notes.model.dto.note.UpdateNoteRequest;
import com.kama.notes.model.entity.Note;
import com.kama.notes.mapper.NoteMapper;
import com.kama.notes.model.entity.NoteCategory;
import com.kama.notes.model.entity.Question;
import com.kama.notes.model.entity.User;
import com.kama.notes.model.vo.category.CategoryVO;
import com.kama.notes.model.vo.note.*;
import com.kama.notes.scope.RequestScopeData;
import com.kama.notes.service.*;
import com.kama.notes.utils.ApiResponseUtil;
import com.kama.notes.utils.MarkdownUtil;
import com.kama.notes.utils.PaginationUtils;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Log4j2
@Service
public class NoteServiceImpl implements NoteService {

    @Autowired
    private NoteMapper noteMapper;

    @Autowired
    private UserService userService;

    @Autowired
    private QuestionService questionService;

    @Autowired
    private NoteLikeService noteLikeService;

    @Autowired
    private CollectionNoteService collectionNoteService;

    @Autowired
    private RequestScopeData requestScopeData;

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private NoteCategoryService noteCategoryService;

    @Autowired
    private QuestionMapper questionMapper;

    @Autowired
    private CommentMapper commentMapper;

    @Autowired
    private CommentLikeMapper commentLikeMapper;

    @Autowired
    private NoteLikeMapper noteLikeMapper;

    @Autowired
    private NoteCollectMapper noteCollectMapper;

    @Autowired
    private CollectionNoteMapper collectionNoteMapper;

    @Override
    public ApiResponse<List<NoteVO>> getNotes(NoteQueryParams params) {

        // 计算分页参数
        int offset = PaginationUtils.calculateOffset(params.getPage(), params.getPageSize());

        // 查询当前查询条件下的笔记总数
        int total = noteMapper.countNotes(params);

        Pagination pagination = new Pagination(params.getPage(), params.getPageSize(), total);

        // 获取笔记列表
        List<Note> notes = noteMapper.findByQueryParams(params, offset, params.getPageSize());

        // 从 笔记列表 中提取 questionIds、categoryIds、authorIds，并去重
        // 注意：分类笔记没有 questionId，需要过滤掉 null，避免拼出 IN (null) 这类 SQL
        List<Integer> questionIds = notes.stream()
                .map(Note::getQuestionId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        List<Integer> categoryIds = notes.stream()
                .map(Note::getCategoryId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        List<Long> authorIds = notes.stream().map(Note::getAuthorId).distinct().toList();
        List<Integer> noteIds = notes.stream().map(Note::getNoteId).toList();

        // 笔记的作者信息
        Map<Long, User> userMapByIds = userService.getUserMapByIds(authorIds);
        // 笔记的问题信息
        Map<Integer, Question> questionMapByIds = questionService.getQuestionMapByIds(questionIds);
        // 笔记的分类信息
        Map<Integer, NoteCategory> categoryMapByIds = noteCategoryService.getCategoryMapByIds(categoryIds);

        // 当前登录用户点赞的笔记列表和收藏的笔记列表
        Set<Integer> userLikedNoteIds;
        Set<Integer> userCollectedNoteIds;

        // 如果是登录状态，则对当前查询的笔记列表进行是否点赞过 / 收藏过的判断
        if (requestScopeData.isLogin() && requestScopeData.getUserId() != null) {
            Long currentUserId = requestScopeData.getUserId();
            userLikedNoteIds = noteLikeService.findUserLikedNoteIds(currentUserId, noteIds);
            userCollectedNoteIds = collectionNoteService.findUserCollectedNoteIds(currentUserId, noteIds);
        } else {  // 未登录状态直接设置为空集合
            userLikedNoteIds = Collections.emptySet();
            userCollectedNoteIds = Collections.emptySet();
        }

        // 用户的点赞信息
        // 用户的收藏信息
        try {
            List<NoteVO> noteVOs = notes.stream().map(note -> {
                NoteVO noteVO = new NoteVO();
                BeanUtils.copyProperties(note, noteVO);

                // 填充作者信息
                User author = userMapByIds.get(note.getAuthorId());
                if (author != null) {
                    NoteVO.SimpleAuthorVO authorVO = new NoteVO.SimpleAuthorVO();
                    BeanUtils.copyProperties(author, authorVO);
                    noteVO.setAuthor(authorVO);
                }

                // 填充问题信息
                Question question = questionMapByIds.get(note.getQuestionId());
                if (question != null) {
                    NoteVO.SimpleQuestionVO questionVO = new NoteVO.SimpleQuestionVO();
                    BeanUtils.copyProperties(question, questionVO);
                    noteVO.setQuestion(questionVO);
                }

                // 填充笔记分类信息
                if (note.getCategoryId() != null) {
                    NoteCategory noteCategory = categoryMapByIds.get(note.getCategoryId());
                    if (noteCategory != null) {
                        NoteVO.SimpleCategoryVO categoryVO = new NoteVO.SimpleCategoryVO();
                        categoryVO.setCategoryId(noteCategory.getCategoryId());
                        categoryVO.setName(noteCategory.getName());
                        noteVO.setCategory(categoryVO);
                    }
                }

                // 填充用户行为信息
                NoteVO.UserActionsVO userActionsVO = new NoteVO.UserActionsVO();
                if (userLikedNoteIds != null && userLikedNoteIds.contains(note.getNoteId())) {
                    userActionsVO.setIsLiked(true);
                }
                if (userCollectedNoteIds != null && userCollectedNoteIds.contains(note.getNoteId())) {
                    userActionsVO.setIsCollected(true);
                }

                // 处理笔记内容折叠内容
                if (MarkdownUtil.needCollapsed(note.getContent())) {
                    noteVO.setNeedCollapsed(true);
                    noteVO.setDisplayContent(MarkdownUtil.extractIntroduction(note.getContent()));
                } else {
                    noteVO.setNeedCollapsed(false);
                }

                noteVO.setUserActions(userActionsVO);
                return noteVO;
            }).toList();

            return ApiResponseUtil.success("获取笔记列表成功", noteVOs, pagination);
        } catch (Exception e) {
            // TODO: 打印日志
            System.out.println(Arrays.toString(e.getStackTrace()));
            return ApiResponseUtil.error("获取笔记列表失败");
        }
    }

    @Override
    @NeedLogin
    public ApiResponse<CreateNoteVO> createNote(CreateNoteRequest request) {
        Long userId = requestScopeData.getUserId();
        Integer questionId = request.getQuestionId();
        Integer categoryId = request.getCategoryId();

        // 题目笔记与分类笔记至少要指定一个归属
        if (questionId == null && categoryId == null) {
            return ApiResponseUtil.error("请指定笔记所属的题目或笔记分类");
        }

        // 判断问题指定的问题是否存在
        if (questionId != null) {
            Question question = questionService.findById(questionId);
            if (question == null) {  // 对应的问题不存在
                return ApiResponseUtil.error("questionId 对应的问题不存在");
            }
        }

        // 判断指定的笔记分类是否存在
        if (categoryId != null) {
            NoteCategory noteCategory = noteCategoryService.findById(categoryId);
            if (noteCategory == null) {
                return ApiResponseUtil.error("categoryId 对应的笔记分类不存在");
            }
        }

        Note note = new Note();
        BeanUtils.copyProperties(request, note);
        note.setAuthorId(userId);

        try {
            noteMapper.insert(note);
            CreateNoteVO createNoteVO = new CreateNoteVO();
            createNoteVO.setNoteId(note.getNoteId());
            return ApiResponseUtil.success("创建笔记成功", createNoteVO);
        } catch (Exception e) {
            return ApiResponseUtil.error("创建笔记失败");
        }
    }

    @Override
    @NeedLogin
    public ApiResponse<EmptyVO> updateNote(Integer noteId, UpdateNoteRequest request) {

        Long userId = requestScopeData.getUserId();

        // 查询笔记
        Note note = noteMapper.findById(noteId);
        if (note == null) {
            return ApiResponseUtil.error("笔记不存在");
        }

        if (!Objects.equals(userId, note.getAuthorId())) {
            return ApiResponseUtil.error("没有权限修改别人的笔记");
        }

        try {
            note.setContent(request.getContent());
            noteMapper.update(note);
            return ApiResponseUtil.success("更新笔记成功");
        } catch (Exception e) {
            return ApiResponseUtil.error("更新笔记失败");
        }
    }

    @Override
    @NeedLogin
    @Transactional(rollbackFor = Exception.class)
    public ApiResponse<EmptyVO> deleteNote(Integer noteId) {

        Long userId = requestScopeData.getUserId();

        Note note = noteMapper.findById(noteId);

        if (note == null) {
            return ApiResponseUtil.error("笔记不存在");
        }

        if (!Objects.equals(userId, note.getAuthorId())) {
            // 没有权限删除别人的笔记
            return ApiResponseUtil.error("没有权限删除别人的笔记");
        }

        try {
            // 先清理与该笔记关联的数据，避免删除笔记后留下孤儿记录。
            // 顺序要求：comment_like 依赖 comment_id，必须在删除 comment 之前处理。
            commentLikeMapper.deleteByNoteId(noteId);    // 该笔记下所有评论的点赞
            commentMapper.deleteByNoteId(noteId);        // 该笔记的评论（含二级回复）
            noteLikeMapper.deleteByNoteId(noteId);       // 笔记点赞
            noteCollectMapper.deleteByNoteId(noteId);    // 笔记收藏
            collectionNoteMapper.deleteByNoteId(noteId); // 收藏夹-笔记关联

            // 最后删除笔记本体
            noteMapper.deleteById(noteId);

            return ApiResponseUtil.success("删除笔记成功");
        } catch (Exception e) {
            log.error("删除笔记失败, noteId={}", noteId, e);
            // 必须抛出异常以触发事务回滚，否则会留下「关联数据已删、笔记还在」的残缺状态
            throw new RuntimeException("删除笔记失败", e);
        }
    }

    // 下载笔记
    @Override
    @NeedLogin
    public ApiResponse<DownloadNoteVO> downloadNote() {

        Long userId = requestScopeData.getUserId();

        // 获取所有笔记
        List<Note> userNotes = noteMapper.findByAuthorId(userId);

        if (userNotes.isEmpty()) {
            return ApiResponseUtil.error("不存在任何笔记");
        }

        // 只有绑定了题目的笔记才能按题目分类导出，分类笔记（questionId 为空）不参与导出
        // 注意：Collectors.toMap 的 key 不能为 null，需要先过滤掉
        List<Note> questionNotes = userNotes.stream()
                .filter(note -> note.getQuestionId() != null)
                .toList();

        if (questionNotes.isEmpty()) {
            return ApiResponseUtil.error("不存在可导出的题目笔记");
        }

        // 将笔记转为 key = questionId, value = note 的 map 对象
        Map<Integer, Note> questionNoteMap = questionNotes.stream()
                .collect(Collectors.toMap(Note::getQuestionId, note -> note, (a, b) -> a));

        // 获取分类树
        List<CategoryVO> categoryTree = categoryService.buildCategoryTree();

        // 根据分类树，创建 markdown 文件
        StringBuilder markdownContent = new StringBuilder();

        // 将 note 中的所有 questionId 提取出来
        List<Integer> questionIds = questionNotes.stream()
                .map(Note::getQuestionId)
                .toList();

        List<Question> questions = questionMapper.findByIdBatch(questionIds);

        for (CategoryVO categoryVO : categoryTree) {

            boolean hasTopLevelToc = false;

            if (categoryVO.getChildren().isEmpty()) {
                continue;
            }

            for (CategoryVO.ChildrenCategoryVO childrenCategoryVO : categoryVO.getChildren()) {

                boolean hasSubLevelToc = false;
                Integer categoryId = childrenCategoryVO.getCategoryId();

                // 用户在该分类下的笔记对应的所有问题
                List<Question> categoryQuestionList = questions.stream()
                        .filter(question -> question.getCategoryId().equals(categoryId))
                        .toList();

                if (categoryQuestionList.isEmpty()) {
                    continue;
                }

                for (Question question : categoryQuestionList) {

                    if (!hasTopLevelToc) {  // 设置一级标题
                        markdownContent.append("# ").append(categoryVO.getName()).append("\n");
                        hasTopLevelToc = true;
                    }

                    if (!hasSubLevelToc) {  // 设置二级标题
                        markdownContent.append("## ").append(childrenCategoryVO.getName()).append("\n");
                        hasSubLevelToc = true;
                    }

                    markdownContent.append("### [")
                            .append(question.getTitle())
                            .append("]")
                            .append("(https://notes.kamacoder.com/questions/")
                            .append(question.getQuestionId())
                            .append(")\n");

                    Note note = questionNoteMap.get(question.getQuestionId());

                    markdownContent.append(note.getContent()).append("\n");
                }
            }
        }

        // 设置笔记内容
        DownloadNoteVO downloadNoteVO = new DownloadNoteVO();
        downloadNoteVO.setMarkdown(markdownContent.toString());

        return ApiResponseUtil.success("生成笔记成功", downloadNoteVO);
    }

    @Override
    public ApiResponse<List<NoteRankListItem>> submitNoteRank() {
        return ApiResponseUtil.success("获取笔记排行榜成功", noteMapper.submitNoteRank());
    }

    @Override
    @NeedLogin
    public ApiResponse<List<NoteHeatMapItem>> submitNoteHeatMap() {
        Long userId = requestScopeData.getUserId();
        return ApiResponseUtil.success("获取笔记热力图成功", noteMapper.submitNoteHeatMap(userId));
    }

    @Override
    @NeedLogin
    public ApiResponse<Top3Count> submitNoteTop3Count() {

        Long userId = requestScopeData.getUserId();

        Top3Count top3Count = noteMapper.submitNoteTop3Count(userId);

        return ApiResponseUtil.success("获取笔记top3成功", top3Count);
    }
}

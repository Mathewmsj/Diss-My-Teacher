// 排名计算工具

const SCORE_MAP = {
  T1: 5,
  T2: 10,
  T3: 15
}

export const ranking = {
  // 计算老师的分数和统计（踩多于赞的评分视为失效，不计入统计）
  calculateTeacherStats(teacherId, ratings, timeRange = 'all') {
    // 如果传入的ratings已经是过滤过的，timeRange参数将被忽略
    const teacherRatings = ratings.filter(r => (r.teacherId || r.teacher) === teacherId)
    const validRatings = teacherRatings.filter(r => (r.dislikes || 0) <= (r.likes || 0))

    const stats = {
      T1: 0,
      T2: 0,
      T3: 0,
      totalScore: 0,
      count: validRatings.length
    }

    validRatings.forEach(rating => {
      stats[rating.tier]++
      stats.totalScore += SCORE_MAP[rating.tier]
    })

    return stats
  },

  // 获取所有老师的排名
  getRanking(teachers, ratings, timeRange = 'all') {
    const filteredRatings = this.filterByTimeRange(ratings, timeRange)
    
    const teacherStats = teachers.map(teacher => {
      const stats = this.calculateTeacherStats(teacher.id, filteredRatings, 'all')
      return {
        ...teacher,
        ...stats
      }
    })

    // 按分数排序
    return teacherStats.sort((a, b) => b.totalScore - a.totalScore)
  },

  // 根据时间范围过滤评分
  filterByTimeRange(ratings, timeRange) {
    if (timeRange === 'all') {
      return ratings
    }

    const now = new Date()
    let startDate

    switch (timeRange) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        break
      case 'month':
        startDate = new Date(now.getFullYear(), now.getMonth(), 1)
        break
      case 'semester':
        const month = now.getMonth()
        // 假设学期：9-1月是第一学期，2-6月是第二学期
        if (month >= 8 || month <= 0) {
          startDate = new Date(now.getFullYear(), 8, 1)
        } else {
          startDate = new Date(now.getFullYear(), 1, 1)
        }
        break
      case 'year':
        startDate = new Date(now.getFullYear(), 0, 1)
        break
      default:
        return ratings
    }

    return ratings.filter(rating => {
      const ratingDate = new Date(rating.created_at || rating.createdAt)
      return ratingDate >= startDate
    })
  },

  // 提取关键词（智能分词版）
  extractKeywords(ratings, limit = 5) {
    if (ratings.length === 0) return []
    
    // 停用词：无意义的词和短语
    const stopWords = new Set([
      // 代词和指示词
      '这个', '那个', '这些', '那些', '这样', '那样', '什么', '怎么', '如何', '为什么',
      // 程度副词
      '非常', '比较', '很', '特别', '相当', '十分', '极其', '有点', '稍微', '稍微',
      '一般', '基本', '大概', '大约', '差不多', '几乎', '完全', '全部', '所有',
      // 连接词
      '但是', '不过', '然而', '而且', '并且', '或者', '如果', '因为', '所以',
      '虽然', '尽管', '即使', '无论', '不管', '只要', '只有', '除了', '除了',
      // 语气词和助词
      '就是', '也是', '都是', '还是', '就是', '其实', '确实', '真的', '应该',
      '可能', '也许', '大概', '或许', '似乎', '好像', '仿佛', '感觉',
      // 否定词
      '不是', '没有', '不会', '不能', '不行', '不可以', '不应该', '不太', '不太',
      // 时间词
      '现在', '以前', '以后', '之前', '之后', '今天', '昨天', '明天', '上课', '下课',
      // 通用无意义词
      '老师', '教授', '可以', '能够', '需要', '必须', '应该', '一定',
      '很多', '一些', '一点', '几个', '有时', '偶尔', '经常', '总是', '一直',
      // 单字停用词
      '的', '了', '在', '是', '我', '你', '他', '她', '它', '们',
      '有', '和', '就', '不', '人', '都', '一', '个', '上', '也', '很',
      '到', '说', '要', '去', '会', '着', '看', '好', '自己', '这', '那'
    ])
    
    // 教学相关常见词（这些词本身有意义，但太常见，如果单独出现则过滤）
    const commonTeachingWords = new Set([
      '作业', '考试', '课程', '课堂', '教学', '讲课', '讲解', '内容', '知识',
      '学生', '班级', '学期', '成绩', '分数', '评分', '评价'
    ])
    
    // 评分权重：T3权重最高，T2次之，T1最低
    const tierWeights = { T1: 1, T2: 2, T3: 3 }
    
    // 收集有效评论
    const validRatings = ratings
      .map(r => ({
        text: (r.reason || '').trim(),
        weight: tierWeights[r.tier] || 1,
        invalid: (r.dislikes || 0) > (r.likes || 0)
      }))
      .filter(item => !item.invalid && item.text.length >= 2)
    
    if (validRatings.length === 0) return []
    
    // 使用改进的TF-IDF思想：词频 × 逆文档频率 × 权重
    const wordStats = {} // { word: { count: 出现次数, score: 加权分数, docs: 出现在多少条评论中 } }
    
    validRatings.forEach(({ text, weight }) => {
      // 清理文本：移除标点，保留中文
      const cleanText = text.replace(/[^\u4e00-\u9fa5]/g, '')
      if (cleanText.length < 2) return
      
      // 提取有意义的短语（优先2-4字词，5字词只在特定情况下提取）
      const extractedWords = new Set() // 每条评论中已提取的词，避免重复计数
      
      // 策略1：提取常见的2-4字短语（滑动窗口）
      for (let len = 2; len <= 4; len++) {
        for (let i = 0; i <= cleanText.length - len; i++) {
          const word = cleanText.substr(i, len)
          
          // 跳过停用词
          if (stopWords.has(word)) continue
          
          // 跳过包含停用子串的词（但允许边界情况）
          let hasStopSubstring = false
          for (let j = 0; j <= word.length - 2; j++) {
            const sub = word.substr(j, 2)
            if (stopWords.has(sub) && (j === 0 || j === word.length - 2)) {
              hasStopSubstring = true
              break
            }
          }
          if (hasStopSubstring) continue
          
          // 记录词
          if (!extractedWords.has(word)) {
            extractedWords.add(word)
            if (!wordStats[word]) {
              wordStats[word] = { count: 0, score: 0, docs: 0 }
            }
            wordStats[word].count++
            wordStats[word].score += weight
            wordStats[word].docs++
          }
        }
      }
      
      // 策略2：提取5字词（但要求是常见教学相关词的组合）
      for (let i = 0; i <= cleanText.length - 5; i++) {
        const word = cleanText.substr(i, 5)
        // 只保留包含常见教学词的5字短语
        let hasTeachingWord = false
        for (const teachingWord of commonTeachingWords) {
          if (word.includes(teachingWord)) {
            hasTeachingWord = true
            break
          }
        }
        if (hasTeachingWord && !stopWords.has(word) && !extractedWords.has(word)) {
          extractedWords.add(word)
          if (!wordStats[word]) {
            wordStats[word] = { count: 0, score: 0, docs: 0 }
          }
          wordStats[word].count++
          wordStats[word].score += weight
          wordStats[word].docs++
        }
      }
    })
    
    // 计算最终分数：TF-IDF思想 + 权重
    const totalDocs = validRatings.length
    const candidates = Object.entries(wordStats)
      .map(([word, stats]) => {
        // TF: 词频（归一化）
        const tf = stats.count / totalDocs
        // IDF: 逆文档频率（出现在越少的文档中，IDF越高，说明越有区分度）
        const idf = Math.log(totalDocs / (stats.docs + 1))
        // 最终分数：TF × IDF × 加权分数
        const finalScore = tf * idf * stats.score
        
        return {
          word,
          score: finalScore,
          count: stats.count,
          docs: stats.docs
        }
      })
      // 过滤：至少出现在2条评论中，或出现在1条但权重很高
      .filter(item => item.docs >= 2 || (item.docs === 1 && item.score >= 5))
      // 过滤：排除纯数字、纯字母
      .filter(item => /[\u4e00-\u9fa5]/.test(item.word))
      // 排序：按分数降序
      .sort((a, b) => {
        if (Math.abs(b.score - a.score) > 0.1) {
          return b.score - a.score
        }
        // 分数相近时，优先选择出现在更多评论中的词
        if (b.docs !== a.docs) {
          return b.docs - a.docs
        }
        // 再按长度（优先长词）
        if (b.word.length !== a.word.length) {
          return b.word.length - a.word.length
        }
        return a.word.localeCompare(b.word, 'zh-CN')
      })
    
    // 去重：如果长词包含短词，且短词不是独立有意义的，则移除短词
    const finalKeywords = []
    for (const candidate of candidates) {
      let shouldAdd = true
      
      // 检查是否被已有长词包含
      for (const existing of finalKeywords) {
        if (existing.word.includes(candidate.word) && existing.word !== candidate.word) {
          // 如果短词出现在长词中间（不是边界），且短词本身不够突出，则跳过
          const index = existing.word.indexOf(candidate.word)
          if (index > 0 && index < existing.word.length - candidate.word.length) {
            if (candidate.score < existing.score * 0.8) {
              shouldAdd = false
              break
            }
          }
        }
      }
      
      // 检查是否包含已有短词（如果当前词是长词，且包含已有短词，保留长词）
      if (shouldAdd) {
        finalKeywords.push(candidate)
        // 移除被当前词包含的已有短词
        for (let i = finalKeywords.length - 2; i >= 0; i--) {
          const existing = finalKeywords[i]
          if (candidate.word.includes(existing.word) && candidate.word !== existing.word) {
            const index = candidate.word.indexOf(existing.word)
            // 如果短词在长词中间，且长词分数更高，移除短词
            if (index > 0 && index < candidate.word.length - existing.word.length) {
              if (candidate.score >= existing.score * 0.8) {
                finalKeywords.splice(i, 1)
              }
            }
          }
        }
      }
      
      if (finalKeywords.length >= limit) break
    }
    
    return finalKeywords.slice(0, limit).map(item => item.word)
  }
}

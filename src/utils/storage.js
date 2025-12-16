// 数据存储工具，使用localStorage

import teachersMock from '../mock/teachers.json'
import ratingsMock from '../mock/ratings.json'
import usersMock from '../mock/users.json'

const STORAGE_KEYS = {
  TEACHERS: 'rmt_teachers',
  RATINGS: 'rmt_ratings',
  USERS: 'rmt_users',
  CURRENT_USER: 'rmt_current_user',
  USER_VOTES: 'rmt_user_votes',
  USER_INTERACTIONS: 'rmt_user_interactions'
}

export const storage = {
  // 初始化默认数据
  init() {
    if (!localStorage.getItem(STORAGE_KEYS.TEACHERS)) {
      localStorage.setItem(STORAGE_KEYS.TEACHERS, JSON.stringify(teachersMock))
    }

    if (!localStorage.getItem(STORAGE_KEYS.RATINGS)) {
      const enriched = ratingsMock.map(r => ({
        ...r,
        userLiked: false,
        userDisliked: false
      }))
      localStorage.setItem(STORAGE_KEYS.RATINGS, JSON.stringify(enriched))
    }

    if (!localStorage.getItem(STORAGE_KEYS.USERS)) {
      localStorage.setItem(STORAGE_KEYS.USERS, JSON.stringify(usersMock))
    }

    if (!localStorage.getItem(STORAGE_KEYS.USER_VOTES)) {
      localStorage.setItem(STORAGE_KEYS.USER_VOTES, JSON.stringify({}))
    }

    if (!localStorage.getItem(STORAGE_KEYS.USER_INTERACTIONS)) {
      localStorage.setItem(STORAGE_KEYS.USER_INTERACTIONS, JSON.stringify({}))
    }
  },

  getTeachers() {
    const data = localStorage.getItem(STORAGE_KEYS.TEACHERS)
    return data ? JSON.parse(data) : []
  },

  getRatings() {
    const data = localStorage.getItem(STORAGE_KEYS.RATINGS)
    return data ? JSON.parse(data) : []
  },

  getUsers() {
    const data = localStorage.getItem(STORAGE_KEYS.USERS)
    return data ? JSON.parse(data) : []
  },

  setUsers(users) {
    localStorage.setItem(STORAGE_KEYS.USERS, JSON.stringify(users))
  },

  getCurrentUser() {
    const data = localStorage.getItem(STORAGE_KEYS.CURRENT_USER)
    return data ? JSON.parse(data) : null
  },

  setCurrentUser(user) {
    if (user) {
      localStorage.setItem(STORAGE_KEYS.CURRENT_USER, JSON.stringify(user))
    } else {
      localStorage.removeItem(STORAGE_KEYS.CURRENT_USER)
    }
  },

  login(email, password) {
    const users = this.getUsers()
    const user = users.find(u => u.email === email && u.password === password)
    if (user) {
      this.setCurrentUser({ 
        id: user.id, 
        name: user.name, 
        email: user.email,
        schoolCode: user.schoolCode || ''
      })
      return { success: true, user }
    }
    return { success: false, message: '邮箱或密码错误' }
  },

  signup(name, email, password, schoolCode) {
    const users = this.getUsers()
    const exists = users.some(u => u.email === email)
    if (exists) {
      return { success: false, message: '邮箱已存在' }
    }
    const newUser = {
      id: Date.now(),
      name,
      email,
      password,
      schoolCode: schoolCode || ''
    }
    users.push(newUser)
    this.setUsers(users)
    this.setCurrentUser({ 
      id: newUser.id, 
      name: newUser.name, 
      email: newUser.email,
      schoolCode: newUser.schoolCode
    })
    return { success: true, user: newUser }
  },

  addRating(rating) {
    const currentUser = this.getCurrentUser()
    if (!currentUser) {
      console.error('用户未登录，无法添加评分')
      return []
    }
    const ratings = this.getRatings()
    ratings.push({
      ...rating,
      userId: currentUser.id,
      id: Date.now(),
      createdAt: new Date().toISOString(),
      likes: 0,
      dislikes: 0,
      userLiked: false,
      userDisliked: false
    })
    localStorage.setItem(STORAGE_KEYS.RATINGS, JSON.stringify(ratings))
    return ratings
  },

  updateRating(id, updates) {
    const ratings = this.getRatings()
    const index = ratings.findIndex(r => r.id === id)
    if (index !== -1) {
      ratings[index] = { ...ratings[index], ...updates }
      localStorage.setItem(STORAGE_KEYS.RATINGS, JSON.stringify(ratings))
    }
    return ratings
  },

  getUserVotes() {
    const data = localStorage.getItem(STORAGE_KEYS.USER_VOTES)
    return data ? JSON.parse(data) : {}
  },

  addUserVote(teacherId) {
    const currentUser = this.getCurrentUser()
    if (!currentUser) {
      console.error('用户未登录，无法记录投票')
      return
    }
    const votes = this.getUserVotes()
    const today = new Date().toISOString().split('T')[0]
    const key = `${currentUser.id}_${today}`
    if (!votes[key]) {
      votes[key] = []
    }
    votes[key].push(teacherId)
    localStorage.setItem(STORAGE_KEYS.USER_VOTES, JSON.stringify(votes))
  },

  getUserVotesToday() {
    const currentUser = this.getCurrentUser()
    if (!currentUser) {
      return []
    }
    const votes = this.getUserVotes()
    const today = new Date().toISOString().split('T')[0]
    const key = `${currentUser.id}_${today}`
    return votes[key] || []
  },

  getUserInteractions() {
    const data = localStorage.getItem(STORAGE_KEYS.USER_INTERACTIONS)
    return data ? JSON.parse(data) : {}
  },

  setUserInteraction(ratingId, type) {
    // type: 'like', 'dislike', or null (to remove)
    const interactions = this.getUserInteractions()
    if (type === null) {
      delete interactions[ratingId]
    } else {
      interactions[ratingId] = type
    }
    localStorage.setItem(STORAGE_KEYS.USER_INTERACTIONS, JSON.stringify(interactions))
  },

  getUserInteraction(ratingId) {
    const interactions = this.getUserInteractions()
    return interactions[ratingId] || null
  }
}

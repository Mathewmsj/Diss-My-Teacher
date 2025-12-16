// 后端部署在 Render 上时的默认地址
// 本地开发可通过设置 VITE_API_BASE 覆盖
const API_BASE = import.meta.env.VITE_API_BASE || 'https://diss-my-teacher.onrender.com/api';

// 请求去重：相同请求在 500ms 内只发送一次
const pendingRequests = new Map();
const REQUEST_DEBOUNCE = 500; // ms

// 简单缓存：GET 请求缓存 2 秒
const cache = new Map();
const CACHE_TTL = 2000; // ms

function authHeaders() {
  const token = localStorage.getItem('authToken');
  return token ? { Authorization: `Token ${token}` } : {};
}

function getCacheKey(path, options) {
  if (options.method && options.method !== 'GET') return null;
  return `${path}:${JSON.stringify(options.body || {})}`;
}

async function request(path, options = {}) {
  const cacheKey = getCacheKey(path, options);
  const now = Date.now();
  
  // 检查缓存
  if (cacheKey && cache.has(cacheKey)) {
    const { data, timestamp } = cache.get(cacheKey);
    if (now - timestamp < CACHE_TTL) {
      return Promise.resolve(data);
    }
    cache.delete(cacheKey);
  }
  
  // 请求去重
  const requestKey = `${path}:${options.method || 'GET'}:${JSON.stringify(options.body || {})}`;
  if (pendingRequests.has(requestKey)) {
    return pendingRequests.get(requestKey);
  }
  
  const isForm = options.body instanceof FormData;
  const headers = {
    ...(!isForm ? { 'Content-Type': 'application/json' } : {}),
    ...authHeaders(),
    ...(options.headers || {}),
  };
  
  // 创建带超时的 fetch（10秒超时）
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 10000);
  
  const fetchPromise = fetch(`${API_BASE}${path}`, {
    headers,
    ...options,
    signal: controller.signal,
  })
    .then(async (res) => {
      clearTimeout(timeoutId);
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg = data.detail || res.statusText;
        throw new Error(msg);
      }
      
      // 缓存 GET 请求结果
      if (cacheKey && res.ok) {
        cache.set(cacheKey, { data, timestamp: now });
      }
      
      return data;
    })
    .catch((err) => {
      clearTimeout(timeoutId);
      if (err.name === 'AbortError') {
        throw new Error('请求超时，请检查网络连接');
      }
      // 网络错误时重试一次
      if (!err.message && navigator.onLine) {
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            fetch(`${API_BASE}${path}`, { headers, ...options })
              .then(async (res) => {
                const data = await res.json().catch(() => ({}));
                if (!res.ok) {
                  const msg = data.detail || res.statusText;
                  reject(new Error(msg));
                } else {
                  if (cacheKey) {
                    cache.set(cacheKey, { data, timestamp: Date.now() });
                  }
                  resolve(data);
                }
              })
              .catch((retryErr) => {
                reject(new Error(retryErr.message || '网络连接失败，请检查网络'));
              });
          }, 1000);
        });
      }
      throw err;
    })
    .finally(() => {
      // 延迟清理 pending 请求，避免立即重复
      setTimeout(() => {
        pendingRequests.delete(requestKey);
      }, REQUEST_DEBOUNCE);
    });
  
  pendingRequests.set(requestKey, fetchPromise);
  return fetchPromise;
}

export const api = {
  loginUser: (identifier, password) =>
    request('/login-user/', {
      method: 'POST',
      body: JSON.stringify({ username: identifier, email: identifier, password }),
    }),
  loginAdmin: (school_code, username, password) =>
    request('/admin-login/', {
      method: 'POST',
      body: JSON.stringify({ school_code, username, password }),
    }),
  signup: (payload) =>
    request('/signup/', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  me: () => request('/users/me/'),
  getQuota: () => request('/user-votes/quota/'),
  getTeachers: () => request('/teachers/'),
  getRatings: () => request('/ratings/'),
  getMyRatings: () => request('/ratings/mine/'),
  getTeachersRaw: () => request('/teachers/'),
  createTeacher: (payload) =>
    request('/teachers/create_one/', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteTeacher: (id) =>
    request(`/teachers/${id}/`, {
      method: 'DELETE',
    }),
  bulkImportTeachers: (file) => {
    const form = new FormData();
    form.append('file', file);
    return request('/teachers/bulk_import/', {
      method: 'POST',
      body: form,
    });
  },
  postRating: (payload) =>
    request('/ratings/', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteRating: (id) =>
    request(`/ratings/${id}/`, {
      method: 'DELETE',
    }),
  getPendingUsers: () => request('/users/pending/'),
  getApprovedUsers: () => request('/users/approved/'),
  getRejectedUsers: () => request('/users/rejected/'),
  getSchools: () => request('/schools/'),
  approveUser: (id) =>
    request(`/users/${id}/approve/`, { method: 'POST' }),
  deleteUser: (id) =>
    request(`/users/${id}/delete_user/`, { method: 'DELETE' }),
  deleteUserHard: (id) =>
    request(`/users/${id}/delete_user/`, { method: 'DELETE' }),
  toggleRate: (id, can_rate) =>
    request(`/users/${id}/toggle_rate/`, {
      method: 'POST',
      body: JSON.stringify({ can_rate }),
    }),
  rejectUser: (id) =>
    request(`/users/${id}/reject/`, { method: 'POST' }),
  setSchoolLimit: (schoolId, limits) => {
    // 支持旧版本（单个 daily_rating_limit）和新版本（按等级 limits 对象）
    const payload = typeof limits === 'object' ? limits : { daily_rating_limit: limits }
    return request(`/schools/${schoolId}/set_daily_limit/`, {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  changePassword: (old_password, new_password) =>
    request('/users/change_password/', {
      method: 'POST',
      body: JSON.stringify({ old_password, new_password }),
    }),
  likeRating: (id) =>
    request(`/ratings/${id}/like/`, { method: 'POST' }),
  dislikeRating: (id) =>
    request(`/ratings/${id}/dislike/`, { method: 'POST' }),
  // 超级管理员接口
  loginSuperAdmin: (username, password) =>
    request('/superadmin-login/', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),
  getSuperAdminStats: () => request('/superadmin/stats/'),
  getAllRatings: () => request('/superadmin/all_ratings/'),
  getAllUsers: () => request('/superadmin/all_users/'),
  getAllSchools: () => request('/superadmin/all_schools/'),
  createSchool: (payload) =>
    request('/superadmin/create_school/', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  createAdmin: (payload) =>
    request('/superadmin/create_admin/', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  updateUser: (id, payload) =>
    request(`/superadmin/${id}/update_user/`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteUserSuper: (id) =>
    request(`/superadmin/${id}/delete_user/`, {
      method: 'DELETE',
    }),
  updateSchool: (schoolCode, payload) =>
    request(`/superadmin/${schoolCode}/update_school/`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  deleteSchool: (schoolCode) =>
    request(`/superadmin/${schoolCode}/delete_school/`, {
      method: 'DELETE',
    }),
  deleteRatingSuper: (id) =>
    request(`/superadmin/${id}/delete_rating/`, {
      method: 'DELETE',
    }),
  resetUserPassword: (id, password) =>
    request(`/superadmin/${id}/reset_user_password/`, {
      method: 'POST',
      body: JSON.stringify({ password }),
    }),
  updateSchoolCode: (oldCode, newCode) =>
    request(`/superadmin/${oldCode}/update_school_code/`, {
      method: 'POST',
      body: JSON.stringify({ new_school_code: newCode }),
    }),
};

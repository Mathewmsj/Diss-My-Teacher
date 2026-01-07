// API 基础地址配置
// 优先级：环境变量 > 自动检测 > 默认值
// 1. 如果设置了 VITE_API_BASE 环境变量，使用该值
// 2. 如果当前访问的是域名（如 mathew.yunguhs.com），使用相对路径 /api
// 3. 如果使用IP访问（如 110.40.153.38），使用相同IP的5000端口
// 4. 否则使用 Render 默认地址
const getApiBase = () => {
  if (import.meta.env.VITE_API_BASE) {
    return import.meta.env.VITE_API_BASE;
  }
  const hostname = window.location.hostname;
  // 检测是否使用域名访问
  if (hostname.includes('yunguhs.com') || (hostname.includes('.') && !hostname.match(/^(\d+\.){3}\d+$/) && hostname !== 'localhost' && hostname !== '127.0.0.1')) {
    // 使用域名时，使用相对路径，nginx 会自动转发到后端
    return '/api';
  }
  // 检测是否使用IP访问（服务器IP：110.40.153.38）
  if (hostname === '110.40.153.38' || hostname.match(/^(\d+\.){3}\d+$/)) {
    // 使用IP访问时，使用相同IP的后端端口5000
    return `http://${hostname}:5000/api`;
  }
  // 本地开发时使用 localhost
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return 'http://localhost:5000/api';
  }
  // 默认使用 Render 地址
  return 'https://diss-my-teacher.onrender.com/api';
};
const API_BASE = getApiBase();

// 请求去重：相同请求在 500ms 内只发送一次
const pendingRequests = new Map();
const REQUEST_DEBOUNCE = 500; // ms

// 简单缓存：GET 请求缓存 2 秒
const cache = new Map();
const CACHE_TTL = 2000; // ms

/**
 * 获取身份验证请求头
 * 
 * 功能说明：
 * 从浏览器的 localStorage 中读取身份验证令牌（Token），
 * 并将其格式化为 HTTP 请求头格式，用于后续的 API 请求。
 * 
 * 工作原理：
 * 1. 从 localStorage 读取 'authToken' 键对应的值
 * 2. 如果 Token 存在，返回包含 Authorization 头的对象
 * 3. 如果 Token 不存在，返回空对象（表示未登录状态）
 * 
 * 返回格式：
 * - 有 Token 时：{ Authorization: 'Token <token_string>' }
 * - 无 Token 时：{}
 * 
 * 使用场景：
 * 在每次 API 请求时，都会调用此函数自动添加身份验证头，
 * 这样后端就能识别当前请求的用户身份。
 * 
 * 安全说明：
 * Token 存储在 localStorage 中，虽然方便，但存在 XSS 攻击风险。
 * 建议在生产环境中使用 HttpOnly Cookie 存储 Token。
 * 
 * @returns {Object} 包含 Authorization 头的对象，或空对象
 */
function authHeaders() {
  // 从 localStorage 读取身份验证令牌
  // localStorage 是浏览器提供的持久化存储，数据在浏览器关闭后仍然保留
  const token = localStorage.getItem('authToken');
  
  // 如果 Token 存在，返回格式化的 Authorization 头
  // Django REST Framework 的 Token 认证要求格式为：Authorization: Token <token>
  // 如果 Token 不存在，返回空对象，表示未登录状态
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
        // 提取更详细的错误信息
        let msg = data.detail || res.statusText;
        if (!msg && data.non_field_errors && data.non_field_errors.length > 0) {
          msg = data.non_field_errors[0];
        } else if (!msg && typeof data === 'object') {
          // 尝试提取第一个字段错误
          const firstKey = Object.keys(data)[0];
          if (firstKey && Array.isArray(data[firstKey]) && data[firstKey].length > 0) {
            msg = `${firstKey}: ${data[firstKey][0]}`;
          } else if (firstKey && typeof data[firstKey] === 'string') {
            msg = `${firstKey}: ${data[firstKey]}`;
          }
        }
        const error = new Error(msg || '请求失败');
        error.response = { data, status: res.status };
        throw error;
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
                  let msg = data.detail || res.statusText;
                  if (!msg && data.non_field_errors && data.non_field_errors.length > 0) {
                    msg = data.non_field_errors[0];
                  } else if (!msg && typeof data === 'object') {
                    const firstKey = Object.keys(data)[0];
                    if (firstKey && Array.isArray(data[firstKey]) && data[firstKey].length > 0) {
                      msg = `${firstKey}: ${data[firstKey][0]}`;
                    } else if (firstKey && typeof data[firstKey] === 'string') {
                      msg = `${firstKey}: ${data[firstKey]}`;
                    }
                  }
                  const error = new Error(msg || '请求失败');
                  error.response = { data, status: res.status };
                  reject(error);
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
  /**
   * 管理员登录 API
   * 
   * 功能说明：
   * 管理员专用的登录接口，需要提供学校代码、管理员账号和密码。
   * 只有 is_staff=True 的用户才能使用此接口登录。
   * 
   * 登录流程：
   * 1. 前端发送 POST 请求到 /api/admin-login/
   * 2. 后端验证用户名和密码
   * 3. 后端检查用户是否为管理员（is_staff=True）
   * 4. 后端验证学校代码是否匹配
   * 5. 后端生成或获取 Token
   * 6. 后端返回 Token、用户ID和学校代码
   * 7. 前端将 Token 和管理员标识存储到 localStorage
   * 
   * 参数说明：
   * @param {string} school_code - 学校代码，用于验证管理员所属学校
   *                                必须与用户关联的学校代码匹配
   * @param {string} username - 管理员账号（用户名）
   * @param {string} password - 管理员密码
   * 
   * 请求体格式：
   * {
   *   "school_code": "SCHOOL001",
   *   "username": "admin",
   *   "password": "password123"
   * }
   * 
   * 响应格式（成功）：
   * {
   *   "detail": "登录成功",
   *   "user_id": 123,
   *   "school_code": "SCHOOL001",
   *   "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
   * }
   * 
   * 响应格式（失败）：
   * {
   *   "detail": "认证失败" | "学校代码不匹配"
   * }
   * 
   * 权限验证：
   * - 用户必须是管理员（is_staff=True）
   * - 学校代码必须匹配（如果用户有关联学校）
   * 
   * 安全说明：
   * 1. 管理员登录需要额外的学校代码验证，提高安全性
   * 2. 管理员只能管理自己学校的用户和教师
   * 3. Token 与普通用户登录使用相同的存储和验证机制
   * 
   * @returns {Promise<Object>} 包含 token、user_id 和 school_code 的响应对象
   */
  loginAdmin: (school_code, username, password) =>
    request('/admin-login/', {
      method: 'POST',
      body: JSON.stringify({ school_code, username, password }),
    }),
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
  toggleFeatured: (id) =>
    request(`/ratings/${id}/toggle_featured/`, { method: 'POST' }),
  // 超级管理员接口
  /**
   * 超级管理员登录 API
   * 
   * 功能说明：
   * 超级管理员专用的登录接口，只需要用户名和密码。
   * 只有 is_superuser=True 的用户才能使用此接口登录。
   * 
   * 登录流程：
   * 1. 前端发送 POST 请求到 /api/superadmin-login/
   * 2. 后端验证用户名和密码
   * 3. 后端检查用户是否为超级管理员（is_superuser=True）
   * 4. 后端检查账户是否激活（is_active=True）
   * 5. 后端生成或获取 Token
   * 6. 后端返回 Token、用户ID和用户名
   * 7. 前端将 Token 和超级管理员标识存储到 localStorage
   * 
   * 参数说明：
   * @param {string} username - 超级管理员用户名
   * @param {string} password - 超级管理员密码
   * 
   * 请求体格式：
   * {
   *   "username": "superadmin",
   *   "password": "password123"
   * }
   * 
   * 响应格式（成功）：
   * {
   *   "detail": "超级管理员登录成功",
   *   "user_id": 1,
   *   "username": "superadmin",
   *   "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
   * }
   * 
   * 响应格式（失败）：
   * {
   *   "detail": "认证失败：需要超级管理员权限" | "账号已停用"
   * }
   * 
   * 权限验证：
   * - 用户必须是超级管理员（is_superuser=True）
   * - 账户必须激活（is_active=True）
   * 
   * 安全说明：
   * 1. 超级管理员拥有系统最高权限，可以管理所有学校、用户和教师
   * 2. 登录后需要设置 isSuperAdmin 标识，用于前端权限控制
   * 3. 建议超级管理员使用强密码并启用双因素认证
   * 
   * @returns {Promise<Object>} 包含 token、user_id 和 username 的响应对象
   */
  loginSuperAdmin: (username, password) =>
    request('/superadmin-login/', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    }),
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

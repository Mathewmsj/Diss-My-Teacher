# Token-Based Authentication Implementation in a Modern Web Application

**Author:** [Your Name]  
**Institution:** [Your Institution]  
**Date:** December 2025

---

## Abstract

This paper presents a comprehensive analysis of the authentication and authorization mechanism implemented in a modern web application using Token-Based Authentication (TBA). Unlike traditional cookie-based session management, this application employs a stateless token authentication system suitable for cross-origin API communication. The implementation leverages Django REST Framework (DRF) on the backend and Vue.js on the frontend, demonstrating how tokens are generated, stored, transmitted, and validated across multiple AJAX requests. This paper addresses four critical aspects: (1) how authorization data is automatically sent with every request without cookies, (2) the token generation and delivery process, (3) server-side token storage and management, and (4) password verification mechanisms including hashing and comparison.

**Keywords:** Authentication, Authorization, Token-Based Authentication, Django REST Framework, Vue.js, Web Security

---

## I. INTRODUCTION

Modern web applications increasingly adopt a decoupled architecture where frontend and backend services are deployed separately, often on different domains. This architecture requires authentication mechanisms that can operate across origins without relying on browser cookies. Token-Based Authentication (TBA) has emerged as a preferred solution for such scenarios.

This paper examines the authentication implementation of "Diss My Teacher," a web application built with Django REST Framework (backend) and Vue.js (frontend). The application implements a stateless authentication system using HTTP tokens transmitted via request headers, stored in browser localStorage, and validated by Django's authentication middleware.

---

## II. HOW AUTHORIZATION DATA IS AUTOMATICALLY SENT WITH EVERY REQUEST

### A. Token Storage Mechanism

Unlike cookie-based authentication where credentials are automatically attached by the browser, token-based authentication requires explicit management. In this application, tokens are stored in the browser's `localStorage`, a persistent storage mechanism that survives browser sessions.

**Frontend Implementation (`src/api.js`):**

```javascript
function authHeaders() {
  const token = localStorage.getItem('authToken');
  return token ? { Authorization: `Token ${token}` } : {};
}
```

This function retrieves the authentication token from localStorage and formats it according to the DRF Token Authentication scheme: `Authorization: Token <token_string>`.

### B. Automatic Token Attachment

Every API request in the application automatically includes the token through a centralized request wrapper:

```javascript
async function request(path, options = {}) {
  const headers = {
    ...(!isForm ? { 'Content-Type': 'application/json' } : {}),
    ...authHeaders(),  // Automatically adds Token to every request
    ...(options.headers || {}),
  };
  
  return fetch(`${API_BASE}${path}`, {
    headers,
    ...options,
  })
}
```

**Key Points:**
- The `authHeaders()` function is called for every request
- If a token exists in localStorage, it is automatically added to the `Authorization` header
- This ensures all AJAX requests include authentication credentials without manual intervention

### C. Comparison with Cookie-Based Authentication

| Aspect | Cookie-Based | Token-Based (This App) |
|--------|-------------|------------------------|
| Storage | Browser Cookie | localStorage |
| Transmission | Automatic by browser | Manual via HTTP Header |
| Cross-Origin | Requires CORS + credentials | Native support |
| Stateless | No (server stores session) | Yes (token contains user info) |

---

## III. TOKEN GENERATION AND DELIVERY PROCESS

### A. Login Flow Overview

The authentication process follows this sequence:

1. User submits credentials (username/email + password)
2. Frontend sends POST request to `/api/login-user/`
3. Backend validates credentials
4. Backend generates/retrieves token
5. Backend returns token in JSON response
6. Frontend stores token in localStorage
7. Subsequent requests include token in Authorization header

### B. Backend Login Implementation

**Code Location:** `backend/api/views.py` - `LoginUserViewSet`

```python
class LoginUserViewSet(viewsets.ViewSet):
    permission_classes = [permissions.AllowAny]

    def create(self, request):
        """
        User login: supports username or email + password.
        """
        identifier = (request.data.get('username') or 
                     request.data.get('email') or '').strip()
        password = request.data.get('password', '')
        
        # Step 1: Find user by username or email
        user = None
        if identifier:
            try:
                user = User.objects.get(username=identifier)
            except User.DoesNotExist:
                try:
                    user = User.objects.get(email=identifier)
                except User.DoesNotExist:
                    pass
        
        if not user:
            return Response({'detail': '用户不存在'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Step 2: Authenticate user (password verification)
        auth_user = authenticate(request, 
                                username=user.username, 
                                password=password)
        
        if not auth_user:
            return Response({'detail': '认证失败'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Step 3: Check account status
        if auth_user.approval_status == User.APPROVAL_PENDING:
            return Response({'detail': '账号待审批，登录受限'}, 
                          status=status.HTTP_403_FORBIDDEN)
        
        # Step 4: Generate or retrieve token
        token, _ = Token.objects.get_or_create(user=auth_user)
        
        # Step 5: Return token to frontend
        return Response({
            'detail': '登录成功',
            'token': token.key,  # Token string
            'user_id': auth_user.id
        })
```

### C. Frontend Token Reception and Storage

**Code Location:** `src/views/Login.vue`

```javascript
onSubmit() {
  this.$refs.formRef.validate(async valid => {
    if (!valid) return
    this.loading = true
    try {
      // Send login request
      res = await api.loginUser(
        this.form.identifier, 
        this.form.password
      )
      
      // Store token in localStorage
      if (res.token) {
        localStorage.setItem('authToken', res.token)
      }
      
      ElMessage.success('登录成功')
      this.$router.push('/')
    } catch (err) {
      ElMessage.error(err.message || '登录失败')
    } finally {
      this.loading = false
    }
  })
}
```

### D. Token Generation Process

The `Token.objects.get_or_create(user=auth_user)` method:

1. Checks if a token already exists for the user
2. If exists, returns the existing token
3. If not, creates a new token using Django's `authtoken` app
4. Token key is a 40-character hexadecimal string (e.g., `9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b`)

---

## IV. SERVER-SIDE TOKEN STORAGE AND MANAGEMENT

### A. Token Model Structure

Django REST Framework's Token Authentication uses the `authtoken` app, which creates a `Token` model with the following structure:

```python
class Token(models.Model):
    key = models.CharField(max_length=40, primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    created = models.DateTimeField(auto_now_add=True)
```

**Key Characteristics:**
- One token per user (OneToOne relationship)
- Token key is the primary key (40-character string)
- Created timestamp tracks token generation time
- Token persists until explicitly deleted

### B. Token Lookup Process

When a request arrives with an `Authorization: Token <key>` header, DRF's `TokenAuthentication` middleware:

1. Extracts the token key from the Authorization header
2. Queries the database: `Token.objects.select_related('user').get(key=token_key)`
3. If found, sets `request.user = token.user`
4. If not found, returns 401 Unauthorized

**Code Location:** `backend/backend/settings.py`

```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

### C. Token Lifecycle Management

**Token Creation:**
- Occurs during login: `Token.objects.get_or_create(user=auth_user)`
- If user logs in again, the same token is reused (not regenerated)

**Token Validation:**
- Performed automatically by DRF middleware on every authenticated request
- No explicit validation code needed in views

**Token Deletion:**
- Can be deleted manually: `token.delete()`
- User logout in this app does NOT delete the token (stateless design)
- Token remains valid until server-side deletion or user deletion

### D. Database Query Example

When validating a token, Django executes:

```sql
SELECT token.key, token.user_id, user.*
FROM authtoken_token token
INNER JOIN api_user user ON token.user_id = user.id
WHERE token.key = '9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b'
```

---

## V. PASSWORD VERIFICATION PROCESS

### A. Password Storage: Hashing

Django uses PBKDF2 (Password-Based Key Derivation Function 2) algorithm for password hashing by default. When a user registers or changes password:

**Code Location:** `backend/api/serializers.py` - `SignupSerializer`

```python
def create(self, validated_data):
    password = validated_data.pop('password')
    user = get_user_model().objects.create(**validated_data)
    user.set_password(password)  # Hashes the password
    user.save()
    return user
```

**What `set_password()` does:**
1. Takes plain text password
2. Generates a random salt
3. Applies PBKDF2 hashing algorithm (default: 260,000 iterations)
4. Stores format: `<algorithm>$<iterations>$<salt>$<hash>`
5. Example: `pbkdf2_sha256$260000$abc123$def456...`

### B. Password Verification Process

**Code Location:** `backend/api/views.py` - `LoginUserViewSet`

```python
# Step 1: Find user
user = User.objects.get(username=identifier)

# Step 2: Authenticate (password verification)
auth_user = authenticate(request, 
                        username=user.username, 
                        password=password)
```

**What `authenticate()` does internally:**

1. Retrieves stored password hash from database
2. Extracts algorithm, iterations, salt, and hash from stored string
3. Applies the same hashing algorithm to the provided password with the stored salt
4. Compares the computed hash with the stored hash
5. Returns `User` object if match, `None` if mismatch

**Django's Password Verification Flow:**

```
Input Password: "mypassword123"
         ↓
Extract salt from stored hash
         ↓
Apply PBKDF2(algorithm, iterations, salt, password)
         ↓
Generate hash: "computed_hash_value"
         ↓
Compare: computed_hash == stored_hash?
         ↓
Match → Return User object
Mismatch → Return None
```

### C. Security Features

**Password Hashing Properties:**
- **One-way function:** Cannot reverse hash to get original password
- **Salt-based:** Each password has unique salt, preventing rainbow table attacks
- **Iterative:** 260,000 iterations slow down brute-force attacks
- **Algorithm:** PBKDF2 with SHA-256 (industry standard)

**Additional Security Checks:**

```python
# Account status verification
if auth_user.approval_status == User.APPROVAL_PENDING:
    return Response({'detail': '账号待审批，登录受限'}, 
                  status=status.HTTP_403_FORBIDDEN)

if not auth_user.is_active:
    return Response({'detail': '账号已停用'}, 
                  status=status.HTTP_403_FORBIDDEN)
```

### D. Password Change Implementation

**Code Location:** `backend/api/views.py` - `UserViewSet.change_password`

```python
@action(detail=False, methods=['post'])
def change_password(self, request):
    user = request.user
    old_password = request.data.get('old_password')
    new_password = request.data.get('new_password')
    
    # Verify old password
    if not user.check_password(old_password):
        return Response({'detail': '原密码不正确'}, 
                      status=status.HTTP_400_BAD_REQUEST)
    
    # Set new password (automatically hashed)
    user.set_password(new_password)
    user.save(update_fields=['password'])
    return Response({'detail': '密码修改成功'})
```

**Key Methods:**
- `check_password(plain_password)`: Verifies password without exposing hash
- `set_password(plain_password)`: Hashes and stores new password

---

## VI. COMPLETE AUTHENTICATION FLOW DIAGRAM

```
┌─────────────┐
│   Browser   │
│  (Vue.js)   │
└──────┬──────┘
       │
       │ 1. POST /api/login-user/
       │    {username, password}
       ▼
┌─────────────────┐
│  Django Backend │
│  LoginUserViewSet│
└──────┬──────────┘
       │
       │ 2. Find User
       │    User.objects.get(username=...)
       ▼
┌─────────────────┐
│  authenticate() │
│  Password Check │
└──────┬──────────┘
       │
       │ 3. PBKDF2 Hash Comparison
       │    check_password()
       ▼
┌─────────────────┐
│ Token Generation│
│ Token.objects.  │
│ get_or_create() │
└──────┬──────────┘
       │
       │ 4. Return {token: "abc123..."}
       ▼
┌─────────────┐
│   Browser   │
│ localStorage│
│ .setItem()  │
└──────┬──────┘
       │
       │ 5. Subsequent Requests
       │    Authorization: Token abc123...
       ▼
┌─────────────────┐
│ TokenAuthentication│
│  Middleware      │
└──────┬──────────┘
       │
       │ 6. Token Lookup
       │    Token.objects.get(key=...)
       ▼
┌─────────────────┐
│  request.user   │
│  Set User Object│
└─────────────────┘
```

---

## VII. SECURITY CONSIDERATIONS

### A. Token Security

**Strengths:**
- Tokens are 40-character random strings (high entropy)
- Stored server-side, cannot be tampered by client
- HTTPS transmission prevents interception

**Vulnerabilities:**
- localStorage is accessible to JavaScript (XSS risk)
- Tokens don't expire automatically
- No built-in token revocation mechanism

### B. Password Security

**Strengths:**
- PBKDF2 with 260,000 iterations (computationally expensive)
- Unique salt per password
- Passwords never stored in plain text

**Best Practices Implemented:**
- Minimum password length validation
- Password complexity requirements (via Django validators)
- Secure password change mechanism

---

## VIII. COMPARISON WITH ALTERNATIVE APPROACHES

### A. Cookie-Based Authentication

**Why Not Used:**
- Cross-origin limitations (frontend and backend on different domains)
- Requires CORS configuration with credentials
- Server-side session storage overhead

**When Cookies Would Be Better:**
- Same-domain deployments
- Traditional server-rendered applications
- Need for automatic credential attachment

### B. JWT (JSON Web Tokens)

**Why Not Used:**
- Simpler implementation with DRF Token Authentication
- No need for token expiration/refresh logic
- Stateless design sufficient for application needs

**When JWT Would Be Better:**
- Microservices architecture
- Need for token expiration
- Distributed systems without shared database

---

## IX. CONCLUSION

This paper has presented a comprehensive analysis of token-based authentication implementation in a modern web application. The system successfully addresses the challenges of cross-origin authentication by:

1. **Eliminating cookie dependency:** Using localStorage and HTTP headers for credential transmission
2. **Automating token attachment:** Centralized request wrapper ensures all AJAX requests include tokens
3. **Secure token management:** Server-side storage with database-backed token lookup
4. **Robust password security:** PBKDF2 hashing with salt and iterative hashing

The implementation demonstrates that token-based authentication is a viable and secure alternative to cookie-based sessions for decoupled web architectures, providing stateless authentication suitable for modern API-driven applications.

**Future Enhancements:**
- Token expiration and refresh mechanisms
- Token revocation on logout
- Rate limiting based on token
- Multi-factor authentication support

---

## REFERENCES

[1] Django Software Foundation, "Django REST Framework Token Authentication," https://www.django-rest-framework.org/api-guide/authentication/#tokenauthentication

[2] OWASP Foundation, "Authentication Cheat Sheet," https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html

[3] NIST Special Publication 800-63B, "Digital Identity Guidelines: Authentication and Lifecycle Management," 2017.

[4] Vue.js Documentation, "HTTP Requests," https://vuejs.org/guide/scaling-up/state-management.html

[5] Mozilla Developer Network, "HTTP Authentication," https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication

---

## APPENDIX A: CODE LISTINGS

### A.1 Frontend API Client (`src/api.js`)

```javascript
// Token retrieval and header construction
function authHeaders() {
  const token = localStorage.getItem('authToken');
  return token ? { Authorization: `Token ${token}` } : {};
}

// Centralized request wrapper
async function request(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...authHeaders(),  // Automatically includes token
    ...(options.headers || {}),
  };
  
  return fetch(`${API_BASE}${path}`, {
    headers,
    ...options,
  });
}
```

### A.2 Backend Login Endpoint (`backend/api/views.py`)

```python
class LoginUserViewSet(viewsets.ViewSet):
    def create(self, request):
        identifier = request.data.get('username') or request.data.get('email')
        password = request.data.get('password')
        
        # User lookup
        user = User.objects.get(username=identifier) or \
               User.objects.get(email=identifier)
        
        # Password verification
        auth_user = authenticate(request, 
                                username=user.username, 
                                password=password)
        
        # Token generation
        token, _ = Token.objects.get_or_create(user=auth_user)
        
        return Response({
            'token': token.key,
            'user_id': auth_user.id
        })
```

### A.3 Authentication Configuration (`backend/backend/settings.py`)

```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

---

## APPENDIX B: DATABASE SCHEMA

### B.1 Token Model

```sql
CREATE TABLE authtoken_token (
    key VARCHAR(40) PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES api_user(id)
);
```

### B.2 User Model (Simplified)

```sql
CREATE TABLE api_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(150) UNIQUE NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    password VARCHAR(128) NOT NULL,  -- Hashed password
    is_active BOOLEAN DEFAULT TRUE,
    is_staff BOOLEAN DEFAULT FALSE,
    ...
);
```

---

**End of Document**

# 生理健康管理系统后端接口文档

## 📋 接口文档必备内容

### 1. 基本信息
**API名称：** 生理健康管理系统后端API  
**接口描述：** 提供用户认证、生理数据管理、AI分析等功能的后端服务  
**基础URL：** http://localhost:8000  
**请求方式：** RESTful API + WebSocket  
**数据格式：** JSON  
**认证方式：** JWT Bearer Token  

---

## 2. 接口列表

### 🔐 用户认证接口

#### 2.1 用户登录
- **接口路径：** `POST /auth/login`
- **接口描述：** 用户通过用户名密码登录系统
- **请求参数：**
  ```json
  {
    "username": "string (必填)",
    "password": "string (必填)"
  }
  ```
- **响应格式：**
  ```json
  // 成功响应
  {
    "code": 200,
    "msg": "登录成功",
    "data": {
      "user_id": 1,
      "username": "test",
      "token": "eyJhbGciOiJIUzI1NiIs..."
    }
  }
  // 失败响应
  {
    "code": 401,
    "msg": "用户名或密码错误",
    "data": null
  }
  ```

#### 2.2 用户注册
- **接口路径：** `POST /auth/register`
- **接口描述：** 新用户注册
- **请求参数：**
  ```json
  {
    "username": "string (必填)",
    "password": "string (必填)",
    "age": "integer (可选)",
    "weight": "float (可选)",
    "height": "float (可选)"
  }
  ```
- **响应格式：**
  ```json
  // 成功响应
  {
    "code": 200,
    "msg": "用户注册成功",
    "data": null
  }
  // 失败响应
  {
    "code": 400,
    "msg": "用户名已存在",
    "data": null
  }
  ```

#### 2.3 获取用户信息
- **接口路径：** `GET /auth/userinfo`
- **接口描述：** 获取当前登录用户的个人信息
- **请求头：** `Authorization: Bearer {token}`
- **响应格式：**
  ```json
  // 成功响应
  {
    "code": 200,
    "msg": "获取成功",
    "data": {
      "username": "test",
      "age": 25,
      "weight": 60.0,
      "height": 170.0
    }
  }
  // 失败响应
  {
    "code": 401,
    "msg": "无效的token",
    "data": null
  }
  ```

### 📊 生理数据接口

#### 2.4 上传生理数据
- **接口路径：** `POST /data/upload/physio`
- **接口描述：** 上传用户的生理数据（心率、血氧、体温）
- **请求头：** `Authorization: Bearer {token}`
- **请求参数：**
  ```json
  {
    "user_id": "integer (必填)",
    "heart_rate": "integer (必填, 30-200)",
    "spo2": "integer (必填, 80-100)",
    "temp": "float (必填, 35-42)",
    "scene": "integer (可选, 0=静息 1=运动 2=睡眠)"
  }
  ```
- **响应格式：**
  ```json
  {
    "code": 200,
    "msg": "上传成功",
    "data": null
  }
  ```

#### 2.5 查询生理数据
- **接口路径：** `GET /data/query/physio`
- **接口描述：** 查询用户的生理数据记录
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `user_id`: integer (必填)
  - `limit`: integer (可选, 默认10, 范围1-100)
- **响应格式：**
  ```json
  {
    "code": 200,
    "msg": "查询成功",
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "heart_rate": 75,
        "spo2": 98,
        "temp": 36.5,
        "scene": 0,
        "timestamp": "2026-03-12 10:00:00"
      }
    ]
  }
  ```

#### 2.6 生成模拟生理数据
- **接口路径：** `GET /data/mock/physio`
- **接口描述：** 生成模拟生理数据（用于测试，无需硬件）
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `user_id`: integer (必填)
  - `scene`: integer (可选, 默认0, 0=静息 1=运动 2=睡眠)
- **响应格式：**
  ```json
  {
    "code": 200,
    "msg": "模拟数据生成成功",
    "data": {
      "heart_rate": 72,
      "spo2": 97,
      "temp": 36.8,
      "scene": 0
    }
  }
  ```

#### 2.7 上传睡眠记录
- **接口路径：** `POST /data/upload/sleep`
- **接口描述：** 上传用户的睡眠记录
- **请求头：** `Authorization: Bearer {token}`
- **请求参数：**
  ```json
  {
    "user_id": "integer (必填)",
    "sleep_start": "string (必填, 格式: YYYY-MM-DD HH:MM:SS)",
    "sleep_end": "string (必填, 格式: YYYY-MM-DD HH:MM:SS)",
    "sleep_score": "integer (必填, 0-100)",
    "deep_sleep_duration": "integer (可选, 分钟)",
    "light_sleep_duration": "integer (可选, 分钟)"
  }
  ```

#### 2.8 查询睡眠记录
- **接口路径：** `GET /data/query/sleep`
- **接口描述：** 查询用户的睡眠记录
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `user_id`: integer (必填)
  - `limit`: integer (可选, 默认7)

#### 2.9 上传运动记录
- **接口路径：** `POST /data/upload/sport`
- **接口描述：** 上传用户的运动记录
- **请求头：** `Authorization: Bearer {token}`
- **请求参数：**
  ```json
  {
    "user_id": "integer (必填)",
    "sport_type": "string (必填)",
    "sport_start": "string (必填, 格式: YYYY-MM-DD HH:MM:SS)",
    "sport_end": "string (必填, 格式: YYYY-MM-DD HH:MM:SS)",
    "avg_heart_rate": "integer (必填, 60-180)",
    "calorie": "float (必填)"
  }
  ```

#### 2.10 查询运动记录
- **接口路径：** `GET /data/query/sport`
- **接口描述：** 查询用户的运动记录
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `user_id`: integer (必填)
  - `limit`: integer (可选, 默认7)

### 🤖 AI服务接口

#### 2.11 生理数据AI分析
- **接口路径：** `GET /ai/physio/analysis`
- **接口描述：** 基于用户生理数据进行AI分析
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `user_id`: integer (必填)
- **响应格式：**
  ```json
  {
    "code": 200,
    "msg": "分析完成",
    "data": "基于您最近的生理数据分析：您的平均心率为75次/分，血氧饱和度98%，体温36.5℃，整体健康状况良好。建议保持规律作息..."
  }
  ```

#### 2.12 运动营养建议
- **接口路径：** `GET /ai/sport/nutrition`
- **接口描述：** 根据运动类型和时长提供营养建议
- **请求头：** `Authorization: Bearer {token}`
- **查询参数：**
  - `sport_type`: string (必填)
  - `sport_duration`: integer (必填, 分钟)
- **响应格式：**
  ```json
  {
    "code": 200,
    "msg": "建议生成完成",
    "data": "针对60分钟跑步运动的营养建议：运动前建议摄入碳水化合物，运动中保持水分补充，运动后及时补充蛋白质..."
  }
  ```

### 🔗 WebSocket实时接口

#### 2.13 实时数据推送
- **接口路径：** `WebSocket /ws/{user_id}`
- **接口描述：** 实时接收硬件设备推送的生理数据
- **连接方式：** `ws://localhost:8000/ws/{user_id}`
- **数据格式：**
  ```json
  // 接收数据示例
  {
    "heart_rate": 78,
    "spo2": 97,
    "temp": 36.6,
    "timestamp": "2026-03-12 10:30:00"
  }
  ```

---

## 3. 状态码说明
```json
{
  "200": "成功",
  "400": "请求参数错误",
  "401": "未认证/token失效",
  "403": "无权限访问",
  "404": "资源不存在",
  "500": "服务器内部错误"
}
```

---

## 4. 数据模型定义

### 用户对象
```json
{
  "id": "integer, 用户ID",
  "username": "string, 用户名",
  "password": "string, 密码哈希值",
  "age": "integer, 年龄",
  "weight": "float, 体重",
  "height": "float, 身高",
  "create_time": "string, 创建时间"
}
```

### 生理数据对象
```json
{
  "id": "integer, 记录ID",
  "user_id": "integer, 用户ID",
  "heart_rate": "integer, 心率",
  "spo2": "integer, 血氧饱和度",
  "temp": "float, 体温",
  "scene": "integer, 场景(0=静息 1=运动 2=睡眠)",
  "timestamp": "string, 记录时间"
}
```

### 睡眠记录对象
```json
{
  "id": "integer, 记录ID",
  "user_id": "integer, 用户ID",
  "sleep_start": "string, 睡眠开始时间",
  "sleep_end": "string, 睡眠结束时间",
  "sleep_score": "integer, 睡眠评分",
  "deep_sleep_duration": "integer, 深睡眠时长(分钟)",
  "light_sleep_duration": "integer, 浅睡眠时长(分钟)"
}
```

### 运动记录对象
```json
{
  "id": "integer, 记录ID",
  "user_id": "integer, 用户ID",
  "sport_type": "string, 运动类型",
  "sport_start": "string, 运动开始时间",
  "sport_end": "string, 运动结束时间",
  "avg_heart_rate": "integer, 平均心率",
  "calorie": "float, 消耗卡路里"
}
```

---

## 5. 测试数据

### 测试用户
- 用户名：`test`，密码：`123456`
- 用户名：`test2`，密码：`654321`
- 用户名：`test3`，密码：`654321`

### 使用说明
1. 所有需要认证的接口都需要在请求头中携带 `Authorization: Bearer {token}`
2. Token通过登录接口获取，有效期24小时
3. 所有时间字段格式为 `YYYY-MM-DD HH:MM:SS`
4. 数值范围有校验，超出范围会返回400错误
// User model placeholder
/// 用户数据模型（与/auth/login返回的data字段对应）
class UserModel {
  int? userId;
  String? username;
  String? token;
  int? age;
  double? weight;

  UserModel({
    this.userId,
    this.username,
    this.token,
    this.age,
    this.weight,
  });

  // 从JSON解析（适配接口字段名）
  UserModel.fromJson(Map<String, dynamic> json) {
    userId = json["user_id"];
    username = json["username"];
    token = json["token"];
    age = json["age"];
    weight = json["weight"];
  }

  // 转JSON用于提交接口
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["user_id"] = userId;
    data["username"] = username;
    data["token"] = token;
    data["age"] = age;
    data["weight"] = weight;
    return data;
  }
}

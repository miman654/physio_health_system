/// API响应数据格式化工具
class ApiResponseFormatter {
  /// 格式化data字段为可渲染字符串
  static String formatApiData(dynamic data) {
    if (data == null) return "无数据";
    if (data is String) return data;
    if (data is Map) {
      // 展示所有键值对
      return data.entries.map((e) => "${e.key}：${e.value}").join("\n");
    }
    if (data is List) {
      if (data.isEmpty) return "无数据";
      // 展示每个对象的主要字段
      return data
          .map((item) => item is Map
              ? item.entries.map((e) => "${e.key}：${e.value}").join(", ")
              : item.toString())
          .join("\n");
    }
    return data.toString();
  }
}

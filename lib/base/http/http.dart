import 'dart:convert';
import 'dart:core';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:qinglong_app/base/http/token_interceptor.dart';
import 'package:qinglong_app/base/http/url.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../../json.jc.dart';
import '../../main.dart';
import '../routes.dart';

class Http {
  Dio? _dio;
  bool pushedLoginPage = false;

  String host;
  int index;

  final bool authenticated;
  bool _closed = false;
  final _pendingWrites = <String>{};

  Http(this.host, this.index, {this.authenticated = true}) {
    _dio = Dio(BaseOptions(
      baseUrl: host,
      connectTimeout: 50000,
      receiveTimeout: 50000,
      sendTimeout: 50000,
      contentType: "application/json",
    ));
    _dio!.interceptors.add(TokenInterceptor(host, index, authenticated: authenticated));
  }

  bool get isClosed => _closed;

  void close() {
    _closed = true;
    _dio?.close(force: true);
  }

  Future<HttpResponse<T>> get<T>(String uri, Map<String, String?>? json,
      {bool compute = true, String serializationName = "data"}) =>
      _request<T>('GET', uri, json, compute, serializationName);

  Future<HttpResponse<T>> post<T>(String uri, dynamic json,
      {bool compute = true, String serializationName = "data"}) =>
      _request<T>('POST', uri, json, compute, serializationName);

  Future<HttpResponse<T>> put<T>(String uri, dynamic json,
      {bool compute = true, String serializationName = "data"}) =>
      _request<T>('PUT', uri, json, compute, serializationName);

  Future<HttpResponse<T>> delete<T>(String uri, dynamic json,
      {bool compute = true, String serializationName = "data"}) =>
      _request<T>('DELETE', uri, json, compute, serializationName);

  HttpResponse<T> _cancelled<T>() =>
      HttpResponse(success: false, code: -1001, message: '会话已切换，请求已取消');

  Future<HttpResponse<T>> _request<T>(String method, String uri, dynamic json,
      bool compute, String serializationName) async {
    if (_closed) return _cancelled<T>();
    final writeKey = method == 'GET' ? null : '$method $uri ${jsonEncode(json)}';
    if (writeKey != null && !_pendingWrites.add(writeKey)) {
      return HttpResponse(success: false, code: -1002, message: '此操作正在提交，请稍候');
    }
    try {
      final response = await _dio!.request(uri,
          options: Options(method: method),
          queryParameters: method == 'GET' ? json : null,
          data: method == 'GET' ? null : json);
      if (_closed) return _cancelled<T>();
      return _handleAuth(decodeResponse<T>(response, serializationName, compute), uri);
    } on DioError catch (e) {
      return exceptionHandler<T>(e, uri);
    } finally {
      if (writeKey != null) _pendingWrites.remove(writeKey);
    }
  }

  HttpResponse<T> _handleAuth<T>(HttpResponse<T> response, String path) {
    if (authenticated && response.code == 401 && !Url.inWhiteList(path)) {
      // Qinglong sends both expired-token and missing-scope errors as 401.
      if (['暂无权限', 'Access denied', '没有该模块的访问权限'].contains(response.message?.trim())) {
        return HttpResponse(success: false, code: 403, message: '没有该模块的访问权限，请检查应用授权');
      }
      exitLogin();
      return HttpResponse(success: false, code: 401, message: '身份已过期，请重新登录');
    }
    return response;
  }

  void exitLogin() {
    if (!pushedLoginPage) {
      "身份已过期,请重新登录".toast();
      pushedLoginPage = true;

      getIt<UserInfoViewModel>(instanceName: index.toString()).exitLoginFocus(index);

      getIt<GlobalKey<NavigatorState>>(instanceName: index.toString()).currentState?.pushNamedAndRemoveUntil(Routes.routeLogin, (route) => false);
    }
  }

  HttpResponse<T> exceptionHandler<T>(DioError e, String path) {
    if (_closed) return _cancelled<T>();
    try {
      final data = e.response?.data;
      final status = e.response?.statusCode ?? 0;
      return _handleAuth(HttpResponse<T>(
        success: false,
        message: data is Map && data['message'] is String
            ? data['message']
            : (status == 0 ? '网络连接失败，请检查地址和证书' : '请求失败（HTTP $status）'),
        code: status == 401 || status == 403 ? status : (data is Map && data['code'] is int ? data['code'] : status),
      ), path);
    } catch (e) {
      return HttpResponse(success: false, message: '请求处理失败', code: 400);
    }
  }

  static HttpResponse<T> decodeResponse<T>(
    Response<dynamic> response,
    String serializationName,
    bool compute,
  ) {
    int code = 0;
    if (response.statusCode == 200) {
      try {
        if (response.data["code"] == 200) {
          if (response.data[serializationName] != null) {
            if (T == NullResponse) {
              return HttpResponse<T>(
                success: true,
                code: 200,
              );
            }

            dynamic data = response.data[serializationName];
            T t;
            if (T == String) {
              if (data is String) {
                t = data as T;
              } else {
                t = jsonEncode(data) as T;
              }
              return HttpResponse<T>(
                success: true,
                code: 200,
                bean: t,
              );
            } else {
              T bean;
              if (compute) {
                bean = DeserializeAction.invokeJson(DeserializeAction<T>(data));
              } else {
                bean = JsonConversion$Json.fromJson<T>(data);
              }
              return HttpResponse<T>(
                success: true,
                code: 200,
                bean: bean,
              );
            }
          } else {
            return HttpResponse<T>(
              success: true,
              code: 200,
            );
          }
        } else {
          return HttpResponse<T>(
            success: false,
            code: response.data["code"],
            message: response.data["message"],
          );
        }
      } catch (e) {
        return HttpResponse<T>(
          success: false,
          code: -1000,
          message: "json解析失败",
        );
      }
    } else {
      code = response.statusCode ?? 0;
      return HttpResponse(
        success: false,
        code: code,
        message: response.statusMessage,
      );
    }
  }
}

class HttpResponse<T> {
  late bool success;
  String? message;
  late int code;
  T? bean;

  HttpResponse({required this.success, this.message, required this.code, this.bean});
}

class DeserializeAction<T> {
  final dynamic json;

  DeserializeAction(this.json);

  T invoke() {
    return JsonConversion$Json.fromJson<T>(json);
  }

  static dynamic invokeJson(DeserializeAction a) => a.invoke();
}

mixin BaseBean<T> {
  T fromJson(Map<String, dynamic> json);
}

class CronBean with BaseBean<CronBean> {
  @override
  CronBean fromJson(Map<String, dynamic> json) {
    return CronBean();
  }
}

void decode<T>() async {
  compute(DeserializeAction.invokeJson, DeserializeAction<T>({}));
}

class NullResponse {}

class NotLoginException implements Exception {}

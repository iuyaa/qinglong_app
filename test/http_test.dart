import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinglong_app/base/http/http.dart';

void main() {
  test('Panel responses preserve logs and reject unsuccessful responses', () {
    Response<dynamic> response(dynamic data, {int status = 200}) => Response(
          requestOptions: RequestOptions(path: '/api/crons/1/log'),
          statusCode: status,
          data: data,
        );

    final log = Http.decodeResponse<String>(
        response({'code': 200, 'data': 'first line\n第二行'}), 'data', false);
    expect(log.success, isTrue);
    expect(log.bean, 'first line\n第二行');

    final denied = Http.decodeResponse<String>(
        response({'code': 401, 'message': 'Unauthorized'}), 'data', false);
    expect(denied.success, isFalse);
    expect(denied.code, 401);

    final unavailable = Http.decodeResponse<String>(
        response('Bad Gateway', status: 502), 'data', false);
    expect(unavailable.success, isFalse);
    expect(unavailable.code, 502);

    final malformed = Http.decodeResponse<String>(
        response('<html>not JSON</html>'), 'data', false);
    expect(malformed.success, isFalse);
  });
}

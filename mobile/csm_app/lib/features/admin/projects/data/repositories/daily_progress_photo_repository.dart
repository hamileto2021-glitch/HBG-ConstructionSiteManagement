import 'dart:io';



import '../../../../../core/network/api_client.dart';
import '../models/daily_progress_photo.dart';

class DailyProgressPhotoRepository {
  DailyProgressPhotoRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DailyProgressPhoto>> getByDiary(
      String diaryId) async {
    final response = await _apiClient.getList(
      '/daily-progress-photos/$diaryId',
    );

    return response
        .map((e) => DailyProgressPhoto.fromJson(e))
        .toList();
  }

  Future<DailyProgressPhoto> upload({
    required String diaryId,
    required File image,
    String? caption,
  }) async {
    final response = await _apiClient.postMultipart(
      endpoint: '/daily-progress-photos/$diaryId',
      file: image,
      fieldName: 'file',
      caption: caption,
    );

    return DailyProgressPhoto.fromJson(response);
  }

  Future<void> delete(String photoId) async {
    await _apiClient.delete(
      '/daily-progress-photos/$photoId',
    );
  }
}
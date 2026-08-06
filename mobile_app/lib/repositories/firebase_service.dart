import 'package:sentinel/repositories/api_repository.dart';

class FirebaseService implements ApiRepository {
  @override
  Future<String> getData() async {
    // internetten veri çekilir
    await Future.delayed(const Duration(seconds: 1));
    return '123';
  }

  @override
  Future<String> setData(String data) async {
    await Future.delayed(const Duration(seconds: 2));
    return "Veri kaydedildi => $data";
  }

  @override
  Future<String> updateData(String data, String key) async {
    await Future.delayed(const Duration(seconds: 2));
    return "$key isimli veri $data değerine güncellendi.";
  }
}

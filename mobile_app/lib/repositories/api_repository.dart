abstract class ApiRepository {
  Future<String> getData();
  Future<String> setData(String data);
  Future<String> updateData(String data, String key);
}

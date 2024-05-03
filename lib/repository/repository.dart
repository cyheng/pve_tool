import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/config.dart';

abstract class StorageRepository<T extends JsonModel> {
  String get prefix;

  static const defaultKey = "default";

  Future<T?> getDefault() async {
    return get(defaultKey);
  }

  Future<T?> get(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(prefix + key);
    if (jsonString != null) {
      return fromJson(json.decode(jsonString));
    } else {
      return null;
    }
  }

  Future<List<String>> getAllKeys() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((key) => key.startsWith(prefix))
        .map((e) => e.replaceFirst(prefix, ""))
        .toList();
  }


  Future<void> remove(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefix + key);
  }

  Future<void> save(String key, T config) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(config.toJson());
    await prefs.setString(prefix + key, jsonString);
  }

  T fromJson(Map<String, dynamic> json);
}

class ServerConfigRepository extends StorageRepository<ServerConfig> {
  @override
  String get prefix => 'server_';
  static final ServerConfigRepository _instance =
      ServerConfigRepository._internal();

  factory ServerConfigRepository() {
    return _instance;
  }

  ServerConfigRepository._internal();

  @override
  ServerConfig fromJson(Map<String, dynamic> jsonStr) {
    return ServerConfig.fromJson(jsonStr);
  }
}

class VmServerConfigRepository extends StorageRepository<VmServerConfig> {
  @override
  String get prefix => 'vm_';
  static final VmServerConfigRepository _instance =
      VmServerConfigRepository._internal();

  factory VmServerConfigRepository() {
    return _instance;
  }

  VmServerConfigRepository._internal();

  @override
  VmServerConfig fromJson(Map<String, dynamic> json) {
    return VmServerConfig.fromJson(json);
  }
}

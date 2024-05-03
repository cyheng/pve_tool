


import 'dart:convert';

import 'constants.dart';
abstract class JsonModel<T> {
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
class ServerConfig implements JsonModel<ServerConfig>{

  String pveHost = '192.168.1.105';
  String pveSSHPort = "22";
  String pveHttpsPort = "8006";
  String pveUsername = 'root';
  String pvePassword = '';
  String pveIsoPath = '/var/lib/vz/template/iso/';

  String nasHost = '192.168.1.6';
  String nasUsername = '';
  String nasPassword = '';
  String nasStorage = 'nas';
  String nasShare = 'pve_backup';
  String nasImageArchive = "vzdump-qemu-201-2024_05_02-23_27_22.vma.zst";
  String nasImageName = "Kylin-Server-V10-SP3-General-Release-2303-X86_64.iso";



  static final ServerConfig _singleton = ServerConfig._internal();

  // 私有构造函数，禁止外部实例化
  ServerConfig._internal();

  // 工厂构造函数，返回单例实例
  factory ServerConfig() {
    return _singleton;
  }
  @override
  ServerConfig fromJson(Map<String, dynamic> json) {
    return ServerConfig.fromJson(json);
  }
  ServerConfig.fromJson(Map<String, dynamic> json){
    pveHost = json[ServerConfigKeys.pveHost];
    pveSSHPort = json[ServerConfigKeys.pveSSHPort];
    pveHttpsPort = json[ServerConfigKeys.pveHttpsPort];
    pveUsername = json[ServerConfigKeys.pveUsername];
    pvePassword = json[ServerConfigKeys.pvePassword];
    pveIsoPath = json[ServerConfigKeys.pveIsoPath];
    nasHost = json[ServerConfigKeys.nasHost];
    nasUsername = json[ServerConfigKeys.nasUsername];
    nasPassword = json[ServerConfigKeys.nasPassword];
    nasStorage = json[ServerConfigKeys.nasStorage];
    nasShare = json[ServerConfigKeys.nasShare];
    nasImageArchive = json[ServerConfigKeys.nasImageArchive];
    nasImageName = json[ServerConfigKeys.nasImageName];
  }


  Map<String, dynamic> toJson() => {
    ServerConfigKeys.pveHost: pveHost,
    ServerConfigKeys.pveSSHPort: pveSSHPort,
    ServerConfigKeys.pveHttpsPort: pveHttpsPort,
    ServerConfigKeys.pveUsername: pveUsername,
    ServerConfigKeys.pvePassword: pvePassword,
    ServerConfigKeys.pveIsoPath: pveIsoPath,
    ServerConfigKeys.nasHost: nasHost,
    ServerConfigKeys.nasUsername: nasUsername,
    ServerConfigKeys.nasPassword: nasPassword,
    ServerConfigKeys.nasStorage: nasStorage,
    ServerConfigKeys.nasShare: nasShare,
    ServerConfigKeys.nasImageArchive: nasImageArchive,
    ServerConfigKeys.nasImageName: nasImageName,
  };

  String get mountIsoPath => '/mnt/pve/$nasStorage/template/iso';

  String get backupArchive => "$nasStorage:backup/$nasImageArchive";

  String get pveApiUrl =>  'https://$pveHost:$pveHttpsPort';

  String get pveApiUsername => '$pveUsername@pam';



  @override
  String toString() {
    return jsonEncode(this);
  }

}


class VmServerConfig implements JsonModel<VmServerConfig>{
  String vmHost = '';
  String vmSSHPort = "22";
  String vmUsername = 'root';
  String vmPassword = '';
  String vmHospitalName = 'test';

  String vpnUsername = 'server@private-test';
  String vpnPassword = '';
  String vpnSharedKey = 'test';

  static final VmServerConfig _singleton = VmServerConfig._internal();

  VmServerConfig._internal();

  factory VmServerConfig() {
    return _singleton;
  }

  VmServerConfig.fromJson(Map<String, dynamic> json){
    vmHost = json[VmServerConfigKeys.vmHost];
    vmSSHPort = json[VmServerConfigKeys.vmSSHPort];
    vmUsername = json[VmServerConfigKeys.vmUsername];
    vmPassword = json[VmServerConfigKeys.vmPassword];
  }


  Map<String, dynamic> toJson() => {
    VmServerConfigKeys.vmHost: vmHost,
    VmServerConfigKeys.vmSSHPort: vmSSHPort,
    VmServerConfigKeys.vmUsername: vmUsername,
    VmServerConfigKeys.vmPassword: vmPassword,
  };
  @override
  String toString() {
    return jsonEncode(this);
  }

  @override
  VmServerConfig fromJson(Map<String, dynamic> json) {
    throw VmServerConfig.fromJson(json);
  }
}
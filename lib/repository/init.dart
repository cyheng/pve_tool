import 'package:shared_preferences/shared_preferences.dart';

import '../model/config.dart';
import 'repository.dart';

class RepositoryInit {


  static Future<void> init() async {
    ServerConfigRepository serverRepo = ServerConfigRepository();

    ServerConfig? defaultServerConfig =  await serverRepo.getDefault();
    if (defaultServerConfig == null) {
      defaultServerConfig = ServerConfig();
      await serverRepo.save(StorageRepository.defaultKey, defaultServerConfig);
    }
    VmServerConfigRepository vmServerRepo = VmServerConfigRepository();
    VmServerConfig? defaultVmServerConfig =  await vmServerRepo.getDefault();
    if (defaultVmServerConfig == null) {
      defaultVmServerConfig = VmServerConfig();
      await vmServerRepo.save(StorageRepository.defaultKey, defaultVmServerConfig);
    }
  }
}

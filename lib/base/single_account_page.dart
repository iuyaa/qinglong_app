import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/http/url.dart';
import 'package:qinglong_app/base/multi_account_userinfo_viewmodel.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/appkey/appkey_viewmodel.dart';
import 'package:qinglong_app/module/config/config_detail_viewmodel.dart';
import 'package:qinglong_app/module/config/config_viewmodel.dart';
import 'package:qinglong_app/module/env/env_viewmodel.dart';
import 'package:qinglong_app/module/home/home_page.dart';
import 'package:qinglong_app/module/home/system_bean.dart';
import 'package:qinglong_app/module/login/login_page.dart';
import 'package:qinglong_app/module/others/dependencies/dependency_viewmodel.dart';
import 'package:qinglong_app/module/subscribe/subscribe_viewmodel.dart';
import 'package:qinglong_app/module/task/task_viewmodel.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';
import 'package:qinglong_app/utils/utils.dart';

import 'routes.dart';



class SingleAccountPage extends StatefulWidget {
  final int index;

  const SingleAccountPage({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  State<SingleAccountPage> createState() => SingleAccountPageState();
}

class SingleAccountPageState extends State<SingleAccountPage> {
  late int index;
  final _routeClients = <ModalRoute<dynamic>, Http>{};
  late final NavigatorObserver sessionObserver = _SessionObserver((route) {
    _routeClients[route] = getIt<Http>(instanceName: index.toString());
    route.completed.whenComplete(() => _routeClients.remove(route));
  });

  late ChangeNotifierProviderFamily<ConfigViewModel, String?> configProvider;
  late ChangeNotifierProviderFamily<DependencyViewModel, String?> dependencyProvider;
  late ChangeNotifierProviderFamily<EnvViewModel, String?> envProvider;
  late ChangeNotifierProviderFamily<TaskViewModel, String?> taskProvider;
  late ChangeNotifierProviderFamily<SubscribeViewModel, String?> subscribeProvider;
  late ChangeNotifierProviderFamily<AppKeyViewModel, String?> appKeyProvider;
  late StateProviderFamily<int, String?> homeIndexProvider;
  late StateProviderFamily<String, String?> codeSearchProvider;

  @override
  void initState() {
    super.initState();
    index = widget.index;
    findLoginInfo();
    registerHttp(getIt<UserInfoViewModel>(instanceName: index.toString()).host ?? '');
    registerGlobalKey();
  }

  void registerProvider() {
    configProvider = ChangeNotifierProvider.family((ref, _) => ConfigViewModel(), name: getProviderName(context));
    dependencyProvider = ChangeNotifierProvider.family((ref, _) => DependencyViewModel(), name: getProviderName(context));
    envProvider = ChangeNotifierProvider.family((ref, _) => EnvViewModel(), name: getProviderName(context));
    taskProvider = ChangeNotifierProvider.family((ref, _) => TaskViewModel(), name: getProviderName(context));
    subscribeProvider = ChangeNotifierProvider.family((ref, _) => SubscribeViewModel(), name: getProviderName(context));
    appKeyProvider = ChangeNotifierProvider.family((ref, _) => AppKeyViewModel(), name: getProviderName(context));
    homeIndexProvider = StateProvider.family((ref, _) => 0, name: getProviderName(context));
    codeSearchProvider = StateProvider.family((ref, _) => "", name: getProviderName(context));
  }

  void resetProviders() {
    final container = ProviderScope.containerOf(context, listen: false);
    container.invalidate(configProvider);
    container.invalidate(dependencyProvider);
    container.invalidate(envProvider);
    container.invalidate(taskProvider);
    container.invalidate(subscribeProvider);
    container.invalidate(appKeyProvider);
    container.invalidate(homeIndexProvider);
    container.invalidate(codeSearchProvider);
  }

  static StateProviderFamily<String, String?> ofCodeSearchProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.codeSearchProvider;
  }

  static StateProviderFamily<int, String?> ofHomeIndexProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.homeIndexProvider;
  }

  static ChangeNotifierProviderFamily<SubscribeViewModel, String?> ofSubscribeProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.subscribeProvider;
  }

  static ChangeNotifierProviderFamily<TaskViewModel, String?> ofTaskProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.taskProvider;
  }

  static ChangeNotifierProviderFamily<AppKeyViewModel, String?> ofAppKeyProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.appKeyProvider;
  }

  static ChangeNotifierProviderFamily<EnvViewModel, String?> ofEnvProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.envProvider;
  }

  static ChangeNotifierProviderFamily<ConfigViewModel, String?> ofConfigProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.configProvider;
  }

  static ChangeNotifierProviderFamily<DependencyViewModel, String?> ofDependencyProvider(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>()!.dependencyProvider;
  }

  static SingleAccountPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<SingleAccountPageState>();
  }

  static UserInfoViewModel ofUserInfo(BuildContext context) {
    int? index = context.findAncestorStateOfType<SingleAccountPageState>()?.index;

    if (index == null) return UserInfoViewModel();

    return getIt<UserInfoViewModel>(instanceName: index.toString());
  }

  static Http? ofHttp(BuildContext context) {
    final owner = of(context);
    if (owner == null) return null;
    Http? client;
    // Non-dependent lookup also works for pages that request data in initState.
    context.visitAncestorElements((element) {
      for (final entry in owner._routeClients.entries) {
        if (identical(element, entry.key.subtreeContext)) {
          client = entry.value;
          return false;
        }
      }
      return true;
    });
    return client ?? getIt<Http>(instanceName: owner.index.toString());
  }

  static Api ofApi(BuildContext context) {
    int? index = context.findAncestorStateOfType<SingleAccountPageState>()?.index;

    if (index == null) return Api(0);

    return Api(index, http: ofHttp(context));
  }

  GlobalKey<NavigatorState> navigator = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Navigator(
        key: navigator,
        observers: [sessionObserver],
        restorationScopeId: index.toString(),
        onGenerateRoute: (setting) {
          return Routes.generateRoute(setting);
        },
        reportsRouteUpdateToEngine: true,
        initialRoute: ofUserInfo(context).isLogined() ? Routes.routeHomePage : Routes.routeLogin,
      );
    });
  }

  void findLoginInfo() {
    registerProvider();
    if (getIt<MultiAccountUserInfoViewModel>().tokenBeans.isNotEmpty && getIt<MultiAccountUserInfoViewModel>().tokenBeans.length > widget.index) {
      var bean = getIt<MultiAccountUserInfoViewModel>().tokenBeans[index];
      final candidates = getIt<MultiAccountUserInfoViewModel>().historyAccounts.where((entry) =>
          entry.host == bean.host && entry.useSecretLogined == bean.useSecretLogined &&
          (bean.userName == null || entry.userName == bean.userName)).toList();
      final history = candidates.length == 1 ? candidates.single : UserInfoBean();
      UserInfoViewModel userInfoViewModel = UserInfoViewModel(
        token: bean.token,
        useSecret: bean.useSecretLogined,
        host: bean.host,
        name: history.userName,
        password: history.password,
        alias: bean.alias ?? history.alias,
      );

      getIt.registerSingleton(
        userInfoViewModel,
        instanceName: widget.index.toString(),
      );
    } else if (getIt<MultiAccountUserInfoViewModel>().historyAccounts.isNotEmpty &&
        getIt<MultiAccountUserInfoViewModel>().historyAccounts.length > widget.index) {
      var history = getIt<MultiAccountUserInfoViewModel>().historyAccounts[index];
      UserInfoViewModel userInfoViewModel = UserInfoViewModel(
        host: history.host,
        useSecret: history.useSecretLogined,
        name: history.userName,
        password: history.password,
        alias: history.alias,
      );
      getIt.registerSingleton(
        userInfoViewModel,
        instanceName: widget.index.toString(),
      );
    } else {
      getIt.registerSingleton(
        UserInfoViewModel(),
        instanceName: widget.index.toString(),
      );
    }
    getIt.registerSingleton(Url(widget.index), instanceName: widget.index.toString());
  }

  void registerSystemBean(String version, bool autoGet) {
    if (getIt.isRegistered<SystemBean>(instanceName: widget.index.toString())) {
      getIt.unregister<SystemBean>(instanceName: widget.index.toString());
    }
    getIt.registerSingleton(
        SystemBean(
          version: version,
          fromAutoGet: autoGet,
        ),
        instanceName: widget.index.toString());
  }

  void registerHttp(String host) {
    if (getIt.isRegistered<Http>(instanceName: widget.index.toString())) {
      getIt<Http>(instanceName: widget.index.toString()).close();
      getIt.unregister<Http>(instanceName: widget.index.toString());
    }
    getIt.registerSingleton(
        Http(
          host,
          widget.index,
        ),
        instanceName: widget.index.toString());
  }

  void registerGlobalKey() {
    if (getIt.isRegistered<GlobalKey<NavigatorState>>(instanceName: widget.index.toString())) {
      getIt.unregister<GlobalKey<NavigatorState>>(instanceName: widget.index.toString());
    }
    getIt.registerSingleton<GlobalKey<NavigatorState>>(navigator, instanceName: widget.index.toString());
  }

  void registerICloud() {
    if (getIt.isRegistered<ICloudUtils>(instanceName: widget.index.toString())) {
      getIt.unregister<ICloudUtils>(instanceName: widget.index.toString());
    }
    getIt.registerSingleton<ICloudUtils>(ICloudUtils(widget.index), instanceName: widget.index.toString());
  }
}

// A page keeps its original session through route-removal animations and timers.
class _SessionObserver extends NavigatorObserver {
  final void Function(ModalRoute<dynamic>) bind;
  _SessionObserver(this.bind);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is ModalRoute<dynamic>) bind(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is ModalRoute<dynamic>) bind(newRoute);
  }
}

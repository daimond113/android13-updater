import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.light)),
      darkTheme: ThemeData.dark().copyWith(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.dark)),
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isMobile = Platform.isAndroid || Platform.isIOS;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android 13 Installer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isMobile ? const SupportedWidget() : const UnsupportedWidget(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SupportedWidget extends StatefulWidget {
  const SupportedWidget({Key? key}) : super(key: key);

  @override
  createState() => SupportedState();
}

class SupportedState extends State<SupportedWidget> {
  Future<bool> auth() async {
    final localAuth = LocalAuthentication();
    var authed = false;
    try {
      authed = await localAuth.authenticate(
          localizedReason: 'Authenticate to install Android 13.',
          options: const AuthenticationOptions(
              stickyAuth: true, biometricOnly: false));
    } catch (e) {
      authed = false;
    }
    if (!authed) {
      if (!mounted) return authed;
      var scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.removeCurrentSnackBar();
      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text("Please authenticate to install"),
        duration: Duration(seconds: 10),
      ));
    }
    return authed;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: DeviceInfoPlugin().deviceInfo,
        builder: (context, AsyncSnapshot<BaseDeviceInfo> snapshot) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: snapshot.connectionState != ConnectionState.done
                        ? <Widget>[
                            const Text(
                              'Fetching device info...',
                              textAlign: TextAlign.center,
                            ),
                          ]
                        : <Widget>[
                            const FractionallySizedBox(
                                widthFactor: 0.6,
                                child: Image(
                                  image: AssetImage('images/android_13.png'),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              'Your device, ${snapshot.data!.toMap()['model']} is supported and is ready to install Android 13.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final bool authed = await auth();
                                if (authed) {
                                  if (!mounted) return;
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (ctx) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) =>
                                            ScaffoldMessenger.of(ctx)
                                                .removeCurrentSnackBar());
                                    return const InstallingAndroidPage();
                                  }));
                                }
                              },
                              label: const Text('Install now'),
                              icon: const Icon(Icons.download),
                            )
                          ],
                  )),
            ));
  }
}

class InstallingAndroidPage extends StatefulWidget {
  const InstallingAndroidPage({Key? key}) : super(key: key);

  @override
  createState() => InstallingAndroidState();
}

class InstallingAndroidState extends State<InstallingAndroidPage> {
  double _progress = 0;

  Future<void> onFinishLoading() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return const BlackScreenWidget();
    }));
  }

  Future<void> updateProgress() async {
    print('Updating progress');
    var random = Random();
    var min = 13;
    var max = 24;
    await Future.doWhile(() async {
      var randomized = random.nextInt(max - min) + min;
      print(_progress);
      await Future.delayed(Duration(seconds: randomized), () {
        if (!mounted) return;
        setState(() {
          _progress += 0.1;
        });
      });
      return _progress <= 1;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await updateProgress());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  bool hasFinished = false;

  Widget build(context) {
    if (_progress >= 1 && !hasFinished) {
      hasFinished = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await onFinishLoading();
      });
    }
    return Scaffold(
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 160.0,
              lineWidth: 10.0,
              percent: _progress > 1 ? 1 : _progress,
              center: Text(
                _progress >= 1
                    ? 'Installed Android 13! Rebooting.'
                    : 'Installing Android 13...',
                style: const TextStyle(
                    fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
              progressColor: Colors.deepPurple[400],
            ),
          ],
        ),
      ),
    );
  }
}

class BlackScreenWidget extends StatefulWidget {
  const BlackScreenWidget({Key? key}) : super(key: key);

  @override
  createState() => BlackScreenState();
}

class BlackScreenState extends State<BlackScreenWidget> {
  var hasErrored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        hasErrored = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: hasErrored
          ? const FractionallySizedBox(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: Image(image: AssetImage('images/destroyed.png')))
          : AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(seconds: 3),
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Loading Android 13...'),
                    ]),
              )),
      backgroundColor: Colors.black,
    );
  }
}

class UnsupportedWidget extends StatelessWidget {
  const UnsupportedWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Your device is not supported and cannot get Android 13. Sorry for the inconvenience.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ));
  }
}

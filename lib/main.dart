import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

// --- [DATA MODELS] ---
enum ClothesSeason { summer, springFall, winter, all }

class MyClothes {
  final String imagePath;
  final String category; // "상의", "하의"
  final ClothesSeason season;
  final bool isAsset;
  MyClothes({required this.imagePath, required this.category, required this.season, this.isAsset = false});
}

// [수정] 샘플 데이터에 계절 정보 추가
List<MyClothes> globalMyCloset = [
  MyClothes(imagePath: "assets/wearimage/sampleimage_1.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sampleimage_2.png", category: "하의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_5.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_6.jpg", category: "상의", season: ClothesSeason.winter, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_7.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_8.jpg", category: "상의", season: ClothesSeason.springFall, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_4.jpg", category: "하의", season: ClothesSeason.summer, isAsset: true),
  MyClothes(imagePath: "assets/wearimage/sam_3.jpg", category: "상의", season: ClothesSeason.summer, isAsset: true),
];

class WeatherData {
  final String temp; final String location; final String description; final int weatherId; final int timezone;
  final double referenceTemp;
  WeatherData({required this.temp, required this.location, required this.description, required this.weatherId, required this.timezone, required this.referenceTemp});
}

class OutfitSet {
  final String description;
  OutfitSet({required this.description});
}

// --- [BUSINESS SERVICES] ---
class WeatherService {
  static const String apiKey = '1dc33607db9cbe1dbdd93317a1a5c360';
  static Future<Map<String, dynamic>?> fetchByGPS() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 5));
      final res = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=${pos.latitude}&lon=${pos.longitude}&appid=$apiKey&units=metric&lang=kr'));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }
  static Future<Map<String, dynamic>?> fetchByCity(String city) async {
    try {
      final res = await http.get(Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=kr'));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
      home: const SplashScreen(),
    );
  }
}

// --- [SCREENS: SPLASH] ---
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swing, _fade;
  Map<String, dynamic>? _initialData;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _swing = Tween<double>(begin: 0.0, end: pi / 1.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.9)));
    _autoStart();
  }
  Future<void> _autoStart() async {
    _controller.forward();
    _initialData = await WeatherService.fetchByGPS();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => MainPage(initialRaw: _initialData)));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4740D4),
      body: AnimatedBuilder(animation: _controller, builder: (context, child) {
        final size = MediaQuery.of(context).size;
        return Stack(children: [
          Center(child: Opacity(opacity: _fade.value, child: Image.asset("assets/wearimage/logo_main.png", width: 280, errorBuilder: (c,e,s)=>const Text("ILLUSION ARCHIVE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))))),
          Positioned(left: 0, child: Transform(alignment: Alignment.centerLeft, transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(_swing.value), child: SizedBox(width: size.width * 0.5, height: size.height, child: Image.asset("assets/wearimage/door_left.png", fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.black26))))),
          Positioned(right: 0, child: Transform(alignment: Alignment.centerRight, transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(-_swing.value), child: SizedBox(width: size.width * 0.5, height: size.height, child: Image.asset("assets/wearimage/door_right.png", fit: BoxFit.cover, errorBuilder: (c,e,s)=>Container(color: Colors.black38))))),
        ]);
      }),
    );
  }
}

// --- [SCREENS: MAIN] ---
class MainPage extends StatefulWidget {
  final Map<String, dynamic>? initialRaw;
  const MainPage({super.key, this.initialRaw});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _idx = 0;
  WeatherData? _weather;
  @override
  void initState() {
    super.initState();
    if (widget.initialRaw != null) _applyRaw(widget.initialRaw!);
  }
  void _applyRaw(Map<String, dynamic> raw) {
    double temp = raw['main']['temp'].toDouble();
    setState(() {
      _weather = WeatherData(temp: temp.toInt().toString(), location: raw['name'].toUpperCase(), description: raw['weather'][0]['description'], weatherId: raw['weather'][0]['id'], timezone: raw['timezone'], referenceTemp: temp);
    });
  }
  void updateWeather(WeatherData d) => setState(() => _weather = d);
  void jumpToTab(int i) => setState(() => _idx = i);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: [
          WeatherPage(mode: "RECOMMEND", weather: _weather, onUpdate: updateWeather, jumpTab: jumpToTab),
          WeatherPage(mode: "CLOSET", weather: _weather, onUpdate: updateWeather, jumpTab: jumpToTab),
          WeatherPage(mode: "SEARCH", weather: _weather, onUpdate: updateWeather, jumpTab: jumpToTab, onSearchDone: () => jumpToTab(0)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF4740D4), unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny_outlined), label: '추천'),
          BottomNavigationBarItem(icon: Icon(Icons.door_sliding_outlined), label: '클로젯'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
        ],
      ),
    );
  }
}

// --- [SCREENS: WEATHER PAGE] ---
class WeatherPage extends StatefulWidget {
  final String mode; final WeatherData? weather; final Function(WeatherData) onUpdate; final Function(int) jumpTab; final VoidCallback? onSearchDone;
  const WeatherPage({super.key, required this.mode, this.weather, required this.onUpdate, required this.jumpTab, this.onSearchDone});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  final ScrollController _hourScrollCtrl = ScrollController();
  int _setIdx = 0; int _hourIdx = 0;

  @override
  void initState() {
    super.initState();
    if (widget.weather == null && widget.mode != "SEARCH") {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleGPS());
    }
  }

  @override
  void didUpdateWidget(covariant WeatherPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weather?.temp != widget.weather?.temp) setState(() => _setIdx = 0);
  }

  Future<void> _handleGPS() async {
    final raw = await WeatherService.fetchByGPS();
    if (raw != null) {
      double t = raw['main']['temp'].toDouble();
      widget.onUpdate(WeatherData(temp: t.toInt().toString(), location: raw['name'].toUpperCase(), description: raw['weather'][0]['description'], weatherId: raw['weather'][0]['id'], timezone: raw['timezone'], referenceTemp: t));
      setState(() { _hourIdx = 0; _setIdx = 0; });
      widget.jumpTab(0);
    }
  }

  void _handleSearch(String v) async {
    if (v.isEmpty) return;
    final double? t = double.tryParse(v);
    if (t != null) {
      widget.onUpdate(WeatherData(temp: t.toInt().toString(), location: "CUSTOM", description: StyleEngine.getAutoDesc(t), weatherId: 800, timezone: 32400, referenceTemp: t));
    } else {
      final raw = await WeatherService.fetchByCity(v);
      if (raw != null) {
        double ct = raw['main']['temp'].toDouble();
        widget.onUpdate(WeatherData(temp: ct.toInt().toString(), location: raw['name'].toUpperCase(), description: raw['weather'][0]['description'], weatherId: raw['weather'][0]['id'], timezone: raw['timezone'], referenceTemp: ct));
      }
    }
    _searchCtrl.clear();
    setState(() { _hourIdx = -1; _setIdx = 0; });
    if (widget.onSearchDone != null) widget.onSearchDone!();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather == null) {
      if (widget.mode == "SEARCH") return _buildSearchUI();
      return Scaffold(backgroundColor: const Color(0xFF4740D4), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 25), const Text("실시간 위치 데이터를 수신 중입니다...", style: TextStyle(color: Colors.white70, fontSize: 14))])));
    }

    final s = StyleEngine.getStyleData(double.parse(widget.weather!.temp), widget.weather!.description, widget.weather!.weatherId);
    final bool isSearch = widget.mode == "SEARCH";
    final Color bgColor = isSearch ? const Color(0xFF4740D4) : s["color"];
    final Color txtColor = isSearch ? Colors.white : s["txtColor"];

    if (isSearch) return _buildSearchUI();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600), color: bgColor,
      child: Stack(children: [
        if (s["isRain"]) Positioned.fill(child: Opacity(opacity: 0.15, child: Image.asset("assets/wearimage/rain_bg.jpg", fit: BoxFit.cover, errorBuilder:(c,e,st)=>Container(color: Colors.black26)))),
        Scaffold(
          backgroundColor: Colors.transparent, drawer: _buildDrawer(context),
          floatingActionButton: FloatingActionButton.small(heroTag: null, onPressed: _handleGPS, backgroundColor: Colors.white.withValues(alpha: 0.9), child: const Icon(Icons.my_location, color: Color(0xFF4740D4))),
          appBar: AppBar(
            toolbarHeight: 40, centerTitle: true, backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: txtColor),
            title: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Text('DAILY CLOSET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: txtColor)), const SizedBox(width: 4), Image.asset("assets/wearimage/logo_symbol.png", height: 28, errorBuilder:(c,e,st)=>Icon(Icons.check_circle, color: txtColor))]),
          ),
          body: _buildMainUI(s, txtColor),
        ),
      ]),
    );
  }

  Widget _buildSearchUI() => Scaffold(
    backgroundColor: const Color(0xFF4740D4),
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
    body: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 35), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      TextField(controller: _searchCtrl, onSubmitted: _handleSearch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), decoration: InputDecoration(hintText: 'Search City or Temp...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)), prefixIcon: const Icon(Icons.search, color: Colors.white70), filled: true, fillColor: Colors.white.withValues(alpha: 0.1), contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(35), borderSide: const BorderSide(color: Colors.white, width: 2)))),
      const SizedBox(height: 25),
      const Text("지역(London) 또는 기온(25)을 입력하여\n실시간 맞춤 코디를 추천받으세요.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
    ]))),
  );

  Widget _buildMainUI(Map<String, dynamic> s, Color txt) {
    final w = widget.weather!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 10),
        Text(w.location, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11, color: txt.withValues(alpha: 0.6))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${w.temp}°C', style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, letterSpacing: -5, color: txt)),
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(s["weather_display"], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: txt))),
        ]),
        _buildForecastBar(w, txt, s["color"]),
        const SizedBox(height: 5),
        _buildOutfitSection(s, widget.mode == "CLOSET", txt),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _buildForecastBar(WeatherData w, Color txt, Color bg) {
    if (_hourIdx == -1) return const SizedBox.shrink();
    DateTime localNow = DateTime.now().toUtc().add(Duration(seconds: w.timezone));
    double baseRef = w.referenceTemp;
    return SizedBox(height: 65, child: ListView.builder(
      controller: _hourScrollCtrl, scrollDirection: Axis.horizontal, itemCount: 24, clipBehavior: Clip.none,
      itemBuilder: (c, i) {
        bool isSel = _hourIdx == i; DateTime fTime = localNow.add(Duration(hours: i + 1));
        int simTemp = (baseRef + (sin((fTime.hour - 8) * pi / 12) * 5)).toInt();
        return GestureDetector(
          onTap: () {
            setState(() => _hourIdx = i);
            widget.onUpdate(WeatherData(temp: simTemp.toString(), location: w.location, description: w.description, weatherId: w.weatherId, timezone: w.timezone, referenceTemp: baseRef));
            _hourScrollCtrl.animateTo(max(0, i * 75.0 - 25.0), duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300), width: 65, margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: isSel ? txt : txt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: isSel ? 3 : 0)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("${fTime.hour}시", style: TextStyle(fontSize: 11, color: isSel ? bg : txt, fontWeight: FontWeight.bold)),
              Text("$simTemp°", style: TextStyle(fontSize: 18, color: isSel ? bg : txt, fontWeight: FontWeight.w900)),
            ]),
          ),
        );
      },
    ));
  }

  // [핵심] 지능형 클로젯 매칭 로직
  Widget _buildOutfitSection(Map<String, dynamic> s, bool isCloset, Color txt) {
    final List<OutfitSet> sets = s["sets"];
    final double currentTemp = double.parse(widget.weather!.temp);

    // 기온에 따른 매칭 계절 결정
    ClothesSeason targetSeason = currentTemp >= 28 ? ClothesSeason.summer : currentTemp >= 12 ? ClothesSeason.springFall : ClothesSeason.winter;

    if (isCloset) {
      // 내 옷장에서 조건에 맞는 옷 필터링
      var matchingTops = globalMyCloset.where((c) => c.category == "상의" && c.season == targetSeason).toList();
      var matchingBottoms = globalMyCloset.where((c) => c.category == "하의" && c.season == targetSeason).toList();

      bool hasMatch = matchingTops.isNotEmpty && matchingBottoms.isNotEmpty;

      return Column(children: [
        const SizedBox(height: 10),
        SizedBox(height: 290, child: hasMatch
            ? Row(children: [
          Expanded(child: _buildCurationImg(matchingTops.last)),
          const SizedBox(width: 10),
          Expanded(child: _buildCurationImg(matchingBottoms.last))
        ])
            : Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Center(child: Text(globalMyCloset.isEmpty ? "내 옷장이 비어있습니다." : "현재 기온(${currentTemp.toInt()}°C)에 적합한\n의상이 옷장에 없습니다.",
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.5))))),
        const SizedBox(height: 15),
        Text("MY ARCHIVE MATCHING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: txt.withValues(alpha: 0.6))),
        Text(hasMatch ? "기온 맞춤 큐레이션 완료" : "아카이브 부족", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: txt)),
        const SizedBox(height: 10),
        Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: txt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Text(hasMatch ? "등록하신 아이템 중 현재 기온에 가장 적합한 조합입니다." : "더 많은 옷을 등록하여 아카이브를 완성하세요.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600))),
      ]);
    }

    // 일반 추천 모드
    return Column(children: [
      const SizedBox(height: 10),
      SizedBox(height: 290, child: PageView.builder(
        controller: _pageCtrl, itemCount: sets.length, onPageChanged: (i) => setState(() => _setIdx = i),
        itemBuilder: (context, idx) {
          String sc = s["scenario"]; bool isR = s["isRain"];
          return Row(children: [Expanded(child: _buildImg(isR ? "assets/wearimage/${sc}_t.jpg" : "assets/wearimage/${sc}_${idx+1}_t.jpg")), const SizedBox(width: 10), Expanded(child: _buildImg(isR ? "assets/wearimage/${sc}_b.jpg" : "assets/wearimage/${sc}_${idx+1}_b.jpg"))]);
        },
      )),
      if (sets.length > 1) Padding(padding: const EdgeInsets.only(top: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(sets.length, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: _setIdx == i ? txt : txt.withValues(alpha: 0.2)))))),
      const SizedBox(height: 15),
      Text("오늘의 코디", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: txt.withValues(alpha: 0.6))),
      Text(s["lookName"], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: txt)),
      const SizedBox(height: 10),
      Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: txt.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Text("${s["infoBox"]}\n(${sets.isNotEmpty && sets.length > _setIdx ? sets[_setIdx].description : ''})", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _buildCurationImg(MyClothes item) => ClipRRect(borderRadius: BorderRadius.circular(15), child: AspectRatio(aspectRatio: 0.85, child: item.isAsset ? Image.asset(item.imagePath, fit: BoxFit.cover) : Image.file(File(item.imagePath), fit: BoxFit.cover)));
  Widget _buildDrawer(BuildContext context) => Drawer(child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), color: const Color(0xFF4740D4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Image.asset("assets/wearimage/logo_symbol.png", height: 100, errorBuilder: (c,e,st)=>const Icon(Icons.check_circle, size: 80, color: Colors.white)), const SizedBox(height: 15), const Text('DAILY CLOSET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))])), ListTile(leading: const Icon(Icons.home_outlined), title: const Text('홈'), onTap: () { Navigator.pop(context); widget.jumpTab(0); }), ListTile(leading: const Icon(Icons.grid_view_rounded), title: const Text('마이 클로젯'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const ClosetGalleryPage())); }), const Spacer(), const ListTile(leading: Icon(Icons.settings_outlined), title: Text('설정'))])));
  Widget _buildImg(String p) => ClipRRect(borderRadius: BorderRadius.circular(15), child: AspectRatio(aspectRatio: 0.85, child: Image.asset(p, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.black12, child: const Icon(Icons.image_search, color: Colors.white)))));
}

// --- [SCREENS: CLOSET GALLERY] ---
class ClosetGalleryPage extends StatefulWidget { const ClosetGalleryPage({super.key}); @override State<ClosetGalleryPage> createState() => _ClosetGalleryPageState(); }
class _ClosetGalleryPageState extends State<ClosetGalleryPage> {
  final ImagePicker _picker = ImagePicker();
  String _filterCat = "전체";
  ClothesSeason _filterSeason = ClothesSeason.all;

  Future<void> _uploadWithWizard() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    // 업로드 위저드 팝업
    if (!mounted) return;
    String? selectedCat;
    ClothesSeason? selectedSeason;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Container(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("아카이브 분류", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text("종류가 무엇인가요?"),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(onPressed: () { selectedCat = "상의"; Navigator.pop(c); }, child: const Text("상의")),
          ElevatedButton(onPressed: () { selectedCat = "하의"; Navigator.pop(c); }, child: const Text("하의")),
        ]),
      ])),
    );

    if (selectedCat == null || !mounted) return;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Container(padding: const EdgeInsets.all(25), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("시즌 선택", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, children: [
          ActionChip(label: const Text("여름"), onPressed: () { selectedSeason = ClothesSeason.summer; Navigator.pop(c); }),
          ActionChip(label: const Text("봄/가을"), onPressed: () { selectedSeason = ClothesSeason.springFall; Navigator.pop(c); }),
          ActionChip(label: const Text("겨울"), onPressed: () { selectedSeason = ClothesSeason.winter; Navigator.pop(c); }),
        ]),
      ])),
    );

    if (selectedSeason != null) {
      setState(() => globalMyCloset.add(MyClothes(imagePath: img.path, category: selectedCat!, season: selectedSeason!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = globalMyCloset.where((c) {
      bool catMatch = _filterCat == "전체" || c.category == _filterCat;
      bool seasonMatch = _filterSeason == ClothesSeason.all || c.season == _filterSeason;
      return catMatch && seasonMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("MY ARCHIVE", style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true, actions: [IconButton(onPressed: _uploadWithWizard, icon: const Icon(Icons.add_photo_alternate_outlined))]),
      body: Column(children: [
        // 필터 섹션
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), child: Row(children: [
          ChoiceChip(label: const Text("전체"), selected: _filterCat == "전체", onSelected: (v) => setState(() => _filterCat = "전체")), const SizedBox(width: 8),
          ChoiceChip(label: const Text("상의"), selected: _filterCat == "상의", onSelected: (v) => setState(() => _filterCat = "상의")), const SizedBox(width: 8),
          ChoiceChip(label: const Text("하의"), selected: _filterCat == "하의", onSelected: (v) => setState(() => _filterCat = "하의")),
          const VerticalDivider(),
          ChoiceChip(label: const Text("Summer"), selected: _filterSeason == ClothesSeason.summer, onSelected: (v) => setState(() => _filterSeason = ClothesSeason.summer)), const SizedBox(width: 8),
          ChoiceChip(label: const Text("Spring/Fall"), selected: _filterSeason == ClothesSeason.springFall, onSelected: (v) => setState(() => _filterSeason = ClothesSeason.springFall)), const SizedBox(width: 8),
          ChoiceChip(label: const Text("Winter"), selected: _filterSeason == ClothesSeason.winter, onSelected: (v) => setState(() => _filterSeason = ClothesSeason.winter)),
        ])),
        Expanded(child: filteredList.isEmpty ? const Center(child: Text("필터에 맞는 아카이브가 없습니다.")) : GridView.builder(
          padding: const EdgeInsets.all(2), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemCount: filteredList.length, itemBuilder: (c, i) {
          var item = filteredList[i];
          return item.isAsset ? Image.asset(item.imagePath, fit: BoxFit.cover) : Image.file(File(item.imagePath), fit: BoxFit.cover);
        },
        )),
      ]),
    );
  }
}

// --- [STYLE ENGINE] ---
class StyleEngine {
  static String getAutoDesc(double t) => t >= 30 ? "무더위" : t >= 20 ? "맑음" : t >= 10 ? "선선함" : "추움";
  static Map<String, dynamic> getStyleData(double temp, String condition, int id) {
    String d = condition; final Map<String, String> nk = {'박무': '안개', '연무': '옅은 안개', '실비': '약한 비', '온흐림': '흐림', '튼구름': '구름 많음', '조각 구름': '구름 조금'};
    nk.forEach((k, v) => d = d.contains(k) ? v : d);
    bool isR = (id >= 200 && id < 600); List<OutfitSet> sets = []; String sc, ln, ib; Color color;
    if (isR) {
      color = const Color(0xFF455A64);
      if (temp >= 23) { sc = "rain_hot"; ln = "썸머 레인 쉴드 룩"; ib = "습한 날씨에도 쾌적함을 유지하세요."; sets = [OutfitSet(description: "레인코트와 나일론 쇼츠")]; }
      else if (temp >= 12) { sc = "rain_mild"; ln = "어반 레인 룩"; ib = "방풍 방수가 되는 아우터를 챙기세요."; sets = [OutfitSet(description: "윈드브레이커와 카고 팬츠")]; }
      else { sc = "rain_cold"; ln = "윈터 레인 워머 룩"; ib = "추위와 비를 동시에 막아야 합니다."; sets = [OutfitSet(description: "경량 패딩과 방수 코트")]; }
    } else {
      color = temp >= 28 ? const Color(0xFFFFAB40) : temp >= 17 ? const Color(0xFF689F38) : const Color(0xFF64B5F6);
      if (temp >= 28) { sc = "02"; ln = "시원한 린넨 룩"; ib = "무더운 한여름, 린넨 소재로 쾌적함을 더하세요."; sets = [OutfitSet(description: "린넨 셔츠와 면 반바지"), OutfitSet(description: "시어서커 셔츠와 와이드 팬츠"), OutfitSet(description: "그래픽 티셔츠와 나일론 쇼츠")]; }
      else if (temp >= 17) { sc = "05"; ln = "베이직 시티 캐주얼"; ib = "선선한 바람이 부네요. 가디건을 추천해요."; sets = [OutfitSet(description: "V넥 가디건과 연청 데님"), OutfitSet(description: "옥스퍼드 셔츠와 치노 팬츠"), OutfitSet(description: "오버핏 맨투맨과 스웻 팬츠")]; }
      else { sc = "07"; ln = "모던 가죽 코디"; ib = "쌀쌀한 날씨, 무게감 있는 소재를 골라보세요."; sets = [OutfitSet(description: "라이더 자켓과 블랙 팬츠"), OutfitSet(description: "헤비 가디건과 코듀로이 팬츠"), OutfitSet(description: "퀼팅 자켓과 생지 데님")]; }
    }
    return {"weather_display": d, "color": color, "txtColor": Colors.white, "lookName": ln, "infoBox": ib, "scenario": sc, "sets": sets, "isRain": isR};
  }
}
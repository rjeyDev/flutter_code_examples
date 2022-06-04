import 'package:DzBurger/contents/colors.dart';
import 'package:DzBurger/contents/no_internet.dart';
import 'package:DzBurger/contents/text_style.dart';
import 'package:DzBurger/pages/home.dart';
import 'package:DzBurger/pages/menu/favorites.dart';
import 'package:DzBurger/pages/menu/promo.dart';
import 'package:DzBurger/services/all_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:DzBurger/pages/menu/components/food_card.dart';
import 'package:DzBurger/pages/menu/search.dart';
import 'package:provider/provider.dart';
import 'components/banner.dart';
import 'components/promo_card.dart';
import 'components/sliver_appbar_delegate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MenuPage extends StatefulWidget {
  final MenuPageController menuPageController;
  final Function toggleFloatingButtonVisibility;
  final bool fabVisibility;
  MenuPage({
    this.menuPageController,
    this.toggleFloatingButtonVisibility,
    this.fabVisibility,
  });
  @override
  State<StatefulWidget> createState() => _MenuPageState(menuPageController);
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  _MenuPageState(MenuPageController menuPageController) {
    menuPageController.animate = animate;
  }

  bool _categoryPress = false;
  bool _search = false;
  PageController _pageController;
  ScrollController _scrollController;
  TabController _tabController;
  Timer timer;
  MyColors color = MyColors();
  TextStyles style = TextStyles();
  double ratio;
  bool _shadow = false;
  bool _fabVisibility;
  GlobalKey<SliverAnimatedListState> _sliverListKey = GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.95,
    );

    _fabVisibility = widget.fabVisibility;

    timer = Timer.periodic(Duration(seconds: 4), (bytimer) {
      if (_pageController.hasClients) {
        setState(() {
          if (_pageController.page.toInt() == Provider.of<AllModels>(context, listen: false).banners.length - 1) {
            _pageController.animateToPage(0, duration: Duration(milliseconds: 700), curve: Curves.easeOut);
          } else {
            _pageController.nextPage(duration: Duration(milliseconds: 700), curve: Curves.easeOut);
          }
        });
      }
    });
    _pageController.addListener(() {
      setState(() {});
    });
    // _sliverListKey.currentState.setState(() {

    // });
    _tabController = TabController(
      vsync: this,
      length: Provider.of<AllModels>(context, listen: false).categories.length,
    );

    Provider.of<AllModels>(context, listen: false).getCategories().then((length) {
      _tabController = TabController(vsync: this, length: length);
    });
  }

  void selectCategory(int category) {
    if (category > -1) {
      setState(() {
        _tabController.animateTo((category + 1), duration: Duration(milliseconds: 200), curve: Curves.easeOut);
      });
    }
  }

  void toggleSearch() {
    setState(() {
      _search = !_search;
    });
  }

  animate() {
    _categoryPress = true;
    Timer(Duration(seconds: 1), () {
      _categoryPress = false;
    });
    _tabController.animateTo(0);
    _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
    _pageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ratio = MediaQuery.of(context).size.width / 360;
    return Consumer<AllModels>(builder: (context, main, child) {
      return Scaffold(
        backgroundColor: color.background,
        body: !main.bannerInternetConnection
            ? NoInternet(page: 'menu')
            : main.menuDataGet.containsValue(false)
                ? SpinKitCircle(
                    color: color.orange,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90 * ratio,
                        decoration: BoxDecoration(
                          color: color.background,
                        ),
                        child: SafeArea(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.easeOut);
                                },
                                child: Container(
                                  width: 120,
                                  margin: EdgeInsets.only(left: 16),
                                  child: SvgPicture.asset(
                                    'assets/images/page_logo.svg',
                                    height: 50,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      main.changeButtonVisibility(false);
                                      // toggleSearch();
                                      main.activePage = 'search';
                                      main.searchFood('');
                                      Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                              reverseTransitionDuration: Duration(seconds: 0),
                                              transitionDuration: Duration(seconds: 0),
                                              pageBuilder: (context, animation, animation1) {
                                                return SearchPage(toggleSearch);
                                              }));
                                      // main.changeNavbarState(false);
                                    },
                                    child: Container(
                                      color: color.background,
                                      child: SvgPicture.asset('assets/icons/search.svg'),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  main.login
                                      ? IconButton(
                                          icon: Icon(Icons.favorite_border),
                                          onPressed: () {
                                            setState(() {
                                              main.changeButtonVisibility(false);
                                              // main.changeNavbarState(false);
                                            });
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                  transitionDuration: Duration(seconds: 0),
                                                  reverseTransitionDuration: Duration(seconds: 0),
                                                  pageBuilder: (context, animation, animation1) {
                                                    return FavoritesPage();
                                                  }),
                                            );
                                          },
                                          color: color.text,
                                        )
                                      : SizedBox(),
                                  SizedBox(width: 5),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollNotification) {
                            if (_scrollController.position.pixels > 519 * ratio && !_fabVisibility) {
                              _fabVisibility = true;
                              widget.toggleFloatingButtonVisibility(true);
                            } else if (_scrollController.position.pixels < 520 * ratio) {
                              widget.toggleFloatingButtonVisibility(false);
                              _fabVisibility = false;
                            }
                            if (_scrollController.position.pixels > 10 && !_shadow) {
                              setState(() {
                                _shadow = true;
                              });
                            } else if (_scrollController.position.pixels <= 10 && _shadow) {
                              setState(() {
                                _shadow = false;
                              });
                            }
                            if (_scrollController.position.pixels.toInt() > (525 * ratio + 20 + 50) && _categoryPress == false) {
                              if (_scrollController.position.pixels >
                                      (525 * ratio + 30) +
                                          ((110 * ratio + 20) * main.categorySize[_tabController.index + 1] +
                                              (_tabController.index) * (10 + 20 * ratio)) &&
                                  _tabController.index < main.categories.length) {
                                _tabController.animateTo(_tabController.index + 1);
                              } else if (_scrollController.position.pixels <
                                  (525 * ratio) +
                                      ((110 * ratio + 20) * main.categorySize[_tabController.index] + (_tabController.index - 2) * (10 + 20 * ratio)))
                                _tabController.animateTo(_tabController.index - 1);
                            }

                            return true;
                          },
                          child: NotificationListener<OverscrollIndicatorNotification>(
                            onNotification: (overscroll) {
                              overscroll.disallowGlow();
                              return true;
                            },
                            child: RefreshIndicator(
                              color: color.orange,
                              backgroundColor: color.background,
                              displacement: 20,
                              onRefresh: () => main.getMenu(),
                              child: CustomScrollView(
                                physics: ClampingScrollPhysics(),
                                controller: _scrollController,
                                slivers: [
                                  SliverPersistentHeader(
                                    delegate: SliverAppBarDelegate(
                                      minHeight: 525 * ratio,
                                      maxHeight: 525 * ratio,
                                      child: Container(
                                        color: color.background,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 10,
                                            ),
                                            // Banners
                                            Container(
                                              height: 110 * ratio,
                                              child: main.banners.length > 0
                                                  ? PageView(
                                                      controller: _pageController,
                                                      allowImplicitScrolling: true,
                                                      children: List.generate(
                                                        main.banners.length,
                                                        (index) => BannerCard(main.banners[index]),
                                                      ),
                                                    )
                                                  : SizedBox(),
                                            ),
                                            Container(
                                              height: 30,
                                              child: Center(
                                                child: main.banners.length > 0
                                                    ? SmoothPageIndicator(
                                                        count: main.banners.length,
                                                        controller: _pageController,
                                                        effect: WormEffect(
                                                          dotHeight: 8 * ratio,
                                                          dotWidth: 8 * ratio,
                                                          dotColor: Color(0xFF8A8A8A),
                                                          activeDotColor: color.orange,
                                                        ),
                                                      )
                                                    : SizedBox(),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    main.getTranslation('promotions'),
                                                    style: TextStyle(
                                                        fontSize: 20 * ratio, fontFamily: style.fsc, fontWeight: style.wbold, color: color.text),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, animation1) {
                                                        return PromoPage(type: 'Promotions');
                                                      }));
                                                    },
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        main.getTranslation('all'),
                                                        style: TextStyle(
                                                          color: color.grey2,
                                                          fontSize: 14 * ratio,
                                                          fontFamily: style.fsc,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: 140 * ratio,
                                              child: ListView(
                                                padding: EdgeInsets.only(left: 16),
                                                scrollDirection: Axis.horizontal,
                                                children: List.generate(
                                                  main.promo.length,
                                                  (index) => PromoCard(index: index, type: 'p'),
                                                ),
                                              ),
                                            ),

                                            //Combo
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    main.getTranslation('combo'),
                                                    style: TextStyle(
                                                      fontSize: 20 * ratio,
                                                      fontFamily: style.fsc,
                                                      fontWeight: style.wbold,
                                                      color: color.text,
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(context, PageRouteBuilder(pageBuilder: (context, animation, animation1) {
                                                        return PromoPage(
                                                          type: 'combo',
                                                        );
                                                      }));
                                                    },
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      child: Text(
                                                        main.getTranslation('all'),
                                                        style: TextStyle(
                                                          color: color.grey2,
                                                          fontSize: 14 * ratio,
                                                          fontFamily: style.fsc,
                                                          fontWeight: FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              height: 140 * ratio,
                                              child: main.combo.length > 0
                                                  ? ListView.builder(
                                                      padding: EdgeInsets.only(left: 16),
                                                      scrollDirection: Axis.horizontal,
                                                      itemCount: main.combo.length,
                                                      itemBuilder: (context, index) {
                                                        return PromoCard(index: index, type: 'c');
                                                      },
                                                    )
                                                  : Container(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: SliverAppBarDelegate(
                                      minHeight: 40 * ratio,
                                      maxHeight: 40 * ratio,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.background,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 30 * ratio,
                                              child: _tabController.length > 0
                                                  ? TabBar(
                                                      onTap: (value) {
                                                        _categoryPress = true;
                                                        _tabController.animateTo(value);
                                                        Timer(Duration(milliseconds: 750), () {
                                                          _categoryPress = false;
                                                        });
                                                        _scrollController.animateTo(
                                                            (525 * ratio + 30) +
                                                                ((110 * ratio + 20) * main.categorySize[value]) +
                                                                (value - 1) * (10 + 20 * ratio),
                                                            duration: Duration(milliseconds: 500),
                                                            curve: Curves.easeOut);
                                                      },
                                                      isScrollable: true,
                                                      indicatorSize: TabBarIndicatorSize.label,
                                                      labelPadding: EdgeInsets.only(left: 0),
                                                      indicatorColor: Colors.transparent,
                                                      physics: ClampingScrollPhysics(),
                                                      unselectedLabelColor: color.category,
                                                      labelColor: Colors.white,
                                                      labelStyle: TextStyle(
                                                        fontSize: 16 * ratio,
                                                        fontFamily: style.fsc,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      unselectedLabelStyle: TextStyle(
                                                        fontWeight: FontWeight.w400,
                                                        fontFamily: style.fsc,
                                                      ),
                                                      indicator: BoxDecoration(
                                                        color: color.orange,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      controller: _tabController,
                                                      tabs: List.generate(main.categories.length, (index) {
                                                        return Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                                          child: Text(main.categories[index].name),
                                                        );
                                                      }),
                                                    )
                                                  : Container(),
                                            ),
                                            SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverList(
                                    key: _sliverListKey,
                                    delegate: SliverChildListDelegate(
                                      List.generate(
                                        main.foods.length,
                                        (index) => FoodCard(index, main.foods[index]),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      );
    });
  }
}

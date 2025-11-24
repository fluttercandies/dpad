import 'dart:ui';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    DpadNavigator(
      enabled: true,
      focusMemory: const FocusMemoryOptions(
        enabled: true,
        maxHistory: 20,
      ),
      onNavigateBack: (context, previousEntry, history) {
        if (previousEntry != null) {
          debugPrint(
              'Restoring focus to: ${previousEntry.debugLabel ?? previousEntry.region}');
          FocusHistory.pop();
          previousEntry.focusNode.requestFocus();
          return KeyEventResult.handled;
        }
        debugPrint('No previous focus entry found - using default back navigation');
        return KeyEventResult.ignored;
      },
      customShortcuts: {
        LogicalKeyboardKey.keyN: () => debugPrint('Next button pressed'),
        LogicalKeyboardKey.keyP: () => debugPrint('Previous button pressed'),
        LogicalKeyboardKey.keyH: () => debugPrint(
            'Focus history: ${Dpad.getFocusHistory().length} entries'),
        LogicalKeyboardKey.keyC: () {
          debugPrint('Clearing focus history');
          Dpad.clearFocusHistory();
        },
        LogicalKeyboardKey.keyM: () => debugPrint('Menu toggle'),
        LogicalKeyboardKey.keyS: () => debugPrint('Settings shortcut'),
        LogicalKeyboardKey.keyD: () {
          final current = Dpad.getCurrentFocusEntry();
          final previous = Dpad.getPreviousFocus();
          debugPrint('Current focus: ${current?.debugLabel ?? "null"}, Previous: ${previous?.debugLabel ?? "null"}');
        },
      },
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: const Color(0xFF007BFF),
        ),
        scrollBehavior: const ScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        debugShowCheckedModeBanner: false,
        home: const ModernTVInterface(),
      ),
    ),
  );
}

class ModernTVInterface extends StatefulWidget {
  const ModernTVInterface({super.key});

  @override
  State<ModernTVInterface> createState() => _ModernTVInterfaceState();
}

class _ModernTVInterfaceState extends State<ModernTVInterface> {
  int _selectedNavIndex = 0;

  // Complete items data structure
  final List<Map<String, dynamic>> continueWatchingItems = [
    {
      'title': 'Cyber City Dystopia',
      'time': '45m left',
      'progress': 0.75,
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDSoAi-44UFP4gDOpFhyUPNl7xTxWdFlgtDIf7gr2J9nS4UpAjSSpzfeztUGPVJbr6UepsPuZ2n9TZhXgv06R-TT2q2mnLbg02b-Y-Y0MHn6ZzHczkfszLfVuw4oFkM8DcZ96rNwFtSUuhExhtM9fayTxgW5bnppTTdD8ODutnmCnvnL0gflC7VSA-KTJGBnFw0UHsR9oRME0-bZw4RsEolB1LNwZu2Oraz6tWuz67TSZijcgttSr05OGzPjXIaOt3bHrNMB7LqKwCo',
    },
    {
      'title': 'The Alchemist S02E04',
      'time': '20m left',
      'progress': 0.40,
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBiTPGF0tUL-men2j_1aPG2HRefIpWMwLi_1Ygm9kf5JrBbFMSMBPHcxcIu30pir0cDI3g56PUvglDnzaoJW2ldP5VDUw_Z2XqWIysk7SNJ_QGMZGJT9XcV1sftpwdYhVEkKk1X8DbYk4PbiWw_6s6yYPDE91XtIYfH1LnT3JIG2x9EFpmyRIjeHkp30rRQdqjTZ5dg4q1fc1QZMuAxShPeS_iKbuihprxtP4nyA8PoJFVcKwPXedrNLpSz6lX7U7gQWy5fdzvRgdMj',
    },
    {
      'title': 'Ocean\'s Breath',
      'time': '1h 15m left',
      'progress': 0.25,
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCgMRrZFKNrd3wv9ITtNQ9tptNIJ9J0Sa1dR45ok5gaDScNf4zAoEj8vn7bJ_xvaJGWE_x2IckaWKdSiU_yJT1p1Ncsujxic5hCIhU6EQsdqafUWv8CmYySC8weyXSTVhBdFaGCZgiZchj-ZuQXf_Wg3RGONLYPjWkQRjbeq28ox4T6iZ9yeeBYCtlkju0ItIjxIN9F3a8sN21XNEK5robOWaIZsaPhJpoOPD5Pwu-LKzocaGOlDnRP9YAROKOTZ6D7ya_hNANgPoi4',
    },
    {
      'title': 'Kingdoms of Old S01E08',
      'time': '18m left',
      'progress': 0.60,
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuANE-qIBLEHhgQre5GjacFXN1Nerh7LzhAO2-3wbYBwIzwT5nCSUw8m4ChOcY4SNtF3DUGrJAxrUokj7fYVMrjCV3yB-OJwzFDD5f2BtsiHTnjaAIJNVauiAQ2RFisiYNU9Ew4eQm9JaipuwowAr5Z3AY_2DAJ6NYbemwB8kG_bW8y0f5yaQnNDWv0ts-07PO6YRWs9hV-yZdGT-HD6E2QJ8wweOK-e_hl5EXIPrwBpkizCSHcoRRNB-35LopBhJ_u1oRoPrR_rWG5i',
    },
  ];

  final List<Map<String, dynamic>> recommendedItems = [
    {
      'title': 'Neon Noir',
      'description':
          'A retired detective is pulled back into a case that haunts him in a rain-soaked, neon-lit city.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCPC4RzmOWr6qAuV6NL6SdI6Wt4UIqqR_hf5Bes8n1Gs7lrWowcoPSk8aov-lzHkzbBSO-5QIgz9m4I2iJbNMPxU7TyyWp7cYbc7YpWmjIazDS16IUQW_dEm_BWs8w-mXIWYZE8fhQFsgoGTLLbXeeLvt2acgF-_ROde1pP9XsJ-QxlsBloeB4H-h9xxy9VDdlHQkRQ33H1xyqTPeV1QYe_eHIvojVEGJ9pofzzw2uL2emKNbpxCXPuzcYyD0GTr9CSIdZdVaS_Cdak',
    },
    {
      'title': 'The Last Stand',
      'description':
          'A small town sheriff and his inexperienced staff must stop a notorious drug lord from crossing border.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAtJ57j5khtfAyGEB8UJgCOBPmrt5QT0cJnmBqMb60usA0fgdEjgm1jqRBxIhQPT4X8wf5zzEqMKgrXvVkuO7-sbGpJgT6J8FuJijZRvnViJAjJZgNsERWkCY1CAZIzx98LQPsFX7IkFmVBWgcHEh8nCmNq1NoPfFoqJh9JuZ2h22Vvb13GdZPuCVHlXpEwlJSnoTiuwUfYJf1Dz3GZEI6Ixnbx7gjceBOPSEm3IFI-XYyzLd6Ei8Ecgl9ZWQVdvDjviQHHgwUWmxj3',
    },
    {
      'title': 'Echoes of Tomorrow',
      'description':
          'A scientist invents a device that can receive messages from future, with unforeseen consequences.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBsak0WBbpAPh3mcO3PhoDmDgrHxfN3NP1e9k-1vsn8NwtThnhZf5jQSg3N2_bD9OZJflIb4hHd-UBBmBQRv9Dqu7Zw396U9HmjoDqYQlUJSiwuKdBDeUGZ8h2cu-udYiD9LtQ2r8uBVyRxG9njs-lwS17PFdZcohCW0w_iKrUaOdSmW3-7buM0vRgPf5VaN8LVsL3gQvszKL-zR6SZW06UwEqFelgAZEyhc7FvB4070eIIp2gw5xvcYkVP7Ec1At77wxW2nbyTkYoB',
    },
    {
      'title': 'Zero Gravity',
      'description':
          'An astronaut gets stranded in space and must find a way to return to Earth before her oxygen runs out.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAU6ayl89p8V2jen6_bPZTgYd0KqpiF_iLvtDlYiRdZLopFIbsLBvDjjbDC0dfHyBm4vatB-E3kaOKDRM1Yff1CQlv2ya2T57QaRmPMjTp-5jclP4dpj1CxWOEkV3BwK-e2MVRXpHI3RhYaTKmHgGWbAFozHi9mLGcYkxrOFCSL94XOjKOdVOqT-4FGBeOFpJ8hDey9GkgXoMR9CC_T9GUq-cERpFqfdQ40TEqxYVAszejdyjrQjoU5BU1pGVY2SFiE_EbdXSkgm_x3',
    },
    {
      'title': 'Desert Bloom',
      'description':
          'In a post-apocalyptic world, a young woman searches for a mythical oasis said to hold the key to life.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuD5vZQniGel5-0Mx5H0YMdFLLoF5r02uGWnqn5lD1a3I-mSTrKxyClm6gZUH65BBm8PINv9URnxwGjY-7ha2XOC38zsu9ySXEbNe-ywiezk_n4qbnANKFKPTvjWtqkv2kGDMBOajL_Rwj7s3ArbPtMTkadjrfi2n0rJ75Wml1B91rxU_2_9U2oK41q0V3glLwDItHXRltXV6nkUXTiT2Jxc17hO2JkRsSdhTb2Mv7BruRO-nA9_957LkUQRRSd_Ljcnc6F_hLs4-sCZ',
    },
    {
      'title': 'The Wanderer',
      'description':
          'A lone swordsman travels through a feudal land, helping those in need while hiding a dark secret.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAtDwyEQexNdB01Lr1foA03k6KDEGqdQs1o-G0FJe0FMvUKO4V-Zsx2CSLWXS_T1vLdOneMl1jQneiD3EJwv2auMoR-UY3iaah-b8rmfCo8JDnBQdetLd4AtWJUvmT0Wm_bZSx5oby99rtX6lEx6s3zrhKeP1bmls1VK5uAwg2gnzJiSOiPlJVplUJ-Jh49u0IDeqe59ycfjN_YBEAL0jLmqh4ziJdHJ9VlCYSddXhiIDsvgNw9PtwUkhOCCjPL0XfZgcfZvCAzuTGN',
    },
  ];

  final List<Map<String, dynamic>> recentlyAddedItems = [
    {
      'title': 'Galactic Chase',
      'description':
          'A daring pilot and his quirky alien co-pilot are on the run from an intergalactic empire after stealing a powerful artifact.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBVpYa2VIb9q_4ExEbIRs38eWHAYhczJstVdmkPM_l9IPhfUgDXAd_K6gUUBQY4uY-HxPbiCWDDm43UDnLbNoRmlfThvGIYRRVD_H0fRcQ6FB_W62SGCnbtmC1spxmBBmwwr_M38ZYQk52SZq-cGmhnjM-Coc5StL4efNtWXN9RCfv5vqOpP9DJem6ZUI3Yojb1VZ6mcikg-p6i22bF0uw0ihQU6F5Deb3TzktKQftqyOrBDGBGOFdm2NnjXmFDBKwhR2P3OZnK7lGl',
    },
    {
      'title': 'Jungle Quest',
      'description':
          'An adventurous archaeologist races against a rival team to find a lost city deep in the Amazon rainforest.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAdGpKb5K1AAX5H26zu0gS5VqU2Qj2n91s1Rf_L2yT9uWhY9IF0crLGl8_SPbYJDYFfzK5eTz6u0Kaz-TCcEwir-tD_VDt41UQBGHxrB89ovB-69V09MmiEShtETVJEhFJybQSlHkP8z9mVnl-ddPVvnc4rmxQPxtSJNW33C5j2gZLVCq6Uf9umYdEq8eT_hrSnm4akXGfhDDCuIv5WOF1BJazewv-RcrCl53e9V234b-1n3FAfjn-01dpxH9jePv_svHx3VfPfN08H',
    },
    {
      'title': 'The Heist',
      'description':
          'A team of expert thieves plans to steal a priceless diamond from a supposedly impenetrable vault.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB8_yqXD9YBDy6zHuWGS3hNdzQsBeVk9mNbUgDeinCITsq7RbLHuAZ4rfOGL81yOB8oL6Ik9zGt6TOhxcqk4l7lOonZMaPf3clKHei44Xq0DlpCQnIDVrCpxfR6oDJ4HBrCJ3ZFxD5ZspgXZzzS66IHJnm1ghwL29rZ9RK2Hr9whIJQWjudVHsR68Shj3TN1JZ3sIXwjOwAlbCmhorK3xvxUYCa9wm3JIx3diT0q-WhHr7KdbAMfnnXXnUUhoEqyHSGnK2HOWNYOQrJ',
    },
    {
      'title': 'Solitude',
      'description':
          'A woman isolates herself in a remote cabin to write a novel, but soon realizes she is not alone.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCRqP2FPYuQ-hlR0un20insSEpZxHT4zpDD4GVI79cxyT4oDvnlw6iVrkMss2It1t4OIXTRlvg7DBbpVF90wRnIAhvTKSRvT7SANzAp8Tpij9XpBv4djkW3BquRS8mqKCUPvEaU7jOob8MgQIqbEzGG0erz1JokDPqePPdKLhMth1_XbtDxC8atIh4IpfUHkEkZGjSnh4flFhf9EnWt8K_ze_tQ7Im9yz6MgP7wdijo_XonnQnbklkpPOq2zyPtYYu4KFTNnoVApe2h',
    },
    {
      'title': 'The Dragon\'s Breath',
      'description':
          'A young warrior must seek out a mythical flower guarded by a dragon to save her village from a deadly plague.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDiiYgFVibWLOxyoV0pp9aLYoaxxS_HFTwXq_33gFAb1nNjBwwK2Xx8vdkAetijzVPIKEc33d3nWD4drgC5yKkQtlejU6KHQy8cFPScLKmWn-2cIHxncXjlkwy4F0q6upKWlwWK0Bk4ahvGfXzv69SCRpj3dwW4Uq1yMeJRmJvSdmWQCZqlLbGTvKn6IknstoZoccmNmS9bMK7JFQAy5S0KA9Dlyy0M4Nc4cpNtA0gtWcpSfJqNtY3j96sO2BUt0s2O_9u8q2nW11MD',
    },
    {
      'title': 'Midnight Run',
      'description':
          'A street racer gets involved with the criminal underworld and must win a dangerous race to save his family.',
      'imageUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBtzvCOuPEu7uXKeNypgB1djeaEQVMZS56rtuu4i0NB9lzMn31xhSyUAA9UosnKwQkcuuC6YPk6YQCmxk1RnYuvpmDpiEWvvYeuGZo0Hsiydc0CJwtC8WHI_qO-HcwZQsKISnnSDYjHIVn84KJdBkysGzuV6nOZvHthpyeg2UVFPOFtln_V14VfomSDYkAoO6Xgwil9AyXJa3cQjxuC-dWOrdZgXBdVue2y9q-gsLWvZMF8r_GimyXiWLG6SIfUTreRY3_oI2OW6tdh',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF090909),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner
                  _buildHeroBanner(),
                  const SizedBox(height: 32),
                  // Continue watching
                  _buildSectionTitle('Continue Watching'),
                  const SizedBox(height: 16),
                  _buildContinueWatching(),
                  const SizedBox(height: 32),
                  // Recommended for you
                  _buildSectionTitle('Recommended for You'),
                  const SizedBox(height: 16),
                  _buildRecommendedGrid(),
                  const SizedBox(height: 32),
                  // Recently added
                  _buildSectionTitle('Recently Added Movies'),
                  const SizedBox(height: 16),
                  _buildRecentlyAdded(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build sidebar
  Widget _buildSidebar() {
    return Container(
      width: 96,
      color: Colors.black.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: Theme.of(context).primaryColor,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Icon(
              Icons.play_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 32),
          // Navigation items
          Expanded(
            child: Column(
              children: [
                _buildNavItem('Home', Icons.home, 0),
                const SizedBox(height: 24),
                _buildNavItem('Movies', Icons.movie, 1),
                const SizedBox(height: 24),
                _buildNavItem('Shows', Icons.tv, 2),
                const SizedBox(height: 24),
                _buildNavItem('Music', Icons.music_note, 3),
                const SizedBox(height: 24),
                _buildNavItem('Live', Icons.live_tv, 4),
              ],
            ),
          ),
          // Settings
          _buildNavItem('Settings', Icons.settings, 5),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    return DpadFocusable(
      region: 'sidebar',
      debugLabel: 'Sidebar $title',
      onFocus: () => debugPrint('Sidebar $title focused'),
      onSelect: () {
        setState(() {
          _selectedNavIndex = index;
        });
        debugPrint('Sidebar $title selected');
      },
      builder: (context, isFocused, child) {
        return Container(
          width: isFocused ? 67 : 64,
          height: isFocused ? 67 : 64,
          decoration: ShapeDecoration(
            color: _selectedNavIndex == index || isFocused
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _selectedNavIndex == index || isFocused
                    ? Colors.white
                    : const Color(0xFF888888),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: _selectedNavIndex == index || isFocused
                      ? Colors.white
                      : const Color(0xFF888888),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hero banner
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 400,
      margin: const EdgeInsets.all(32),
      decoration: ShapeDecoration(
        shape:
            RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(20)),
        image: const DecorationImage(
          image: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBSGPnweHD5U53WX_JHL64tO6IpUyWSJngjxhdM6NQ2kM2LPccDSi1XSPywQlGxJXS41plmUbTZw1W_HE1ALEDkJBl6f-YZ0YRy_HDOPP5n4kTX297tVS2jabbGsMCnGRgTnlaQnmyTFZD2TTEi1K9mPtIcGyuWF26KDkBF1Xd_hiY72-jLBXx0ijSSDRl2sc399klqbEr_6OUPx1PiTFXgCN71lH5QfFPQeZJY2WUoiQO8S4ZrnWOMsT2M41NV4kg28o4a6z3Nbf8Z'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Cosmic Odyssey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: 600,
                      child: Text(
                        'A lone astronaut embarks on a perilous journey across the galaxy to uncover a mystery that could change humanity forever.',
                        style: TextStyle(
                          color: Color(0xFFEAEAEA),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              DpadFocusable(
                region: 'hero',
                debugLabel: 'Play Button',
                autofocus: true,
                onFocus: () => debugPrint('Play button focused'),
                onSelect: () => debugPrint('Play button selected'),
                builder: (context, isFocused, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: ShapeDecoration(
                      color: isFocused
                          ? const Color(0xFF0056B3)
                          : Theme.of(context).primaryColor,
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadows: isFocused
                          ? [
                              const BoxShadow(
                                color: Color(0x40007BFF),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Play',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Continue watching
  Widget _buildContinueWatching() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: continueWatchingItems.length,
        itemBuilder: (context, index) {
          final item = continueWatchingItems[index];
          return _buildContinueWatchingCard(item, index);
        },
      ),
    );
  }

  Widget _buildContinueWatchingCard(Map<String, dynamic> item, int index) {
    return Container(
      width: 288,
      margin: const EdgeInsets.only(right: 24, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Expanded(
            child: DpadFocusable(
                region: 'continue',
                debugLabel: 'Continue ${item['title']}',
                onFocus: () => debugPrint('Continue ${item['title']} focused'),
                onSelect: () =>
                    debugPrint('Continue ${item['title']} selected'),
                builder: (context, isFocused, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage(item['imageUrl'] as String),
                        fit: BoxFit.cover,
                      ),
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Theme.of(context).cardColor,
                      shadows: isFocused
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor,
                                blurRadius: 12,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 4,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: item['progress'] as double,
                child: Container(
                  color: const Color(0xFF007BFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String,
                style: const TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item['time'] as String,
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recommended grid
  Widget _buildRecommendedGrid() {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: recommendedItems.length,
        itemBuilder: (context, index) {
          final item = recommendedItems[index];
          return _buildRecommendedCard(item, index);
        },
      ),
    );
  }

  Widget _buildRecommendedCard(Map<String, dynamic> item, int index) {
    return Container(
      width: 208,
      margin: const EdgeInsets.only(right: 24, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Expanded(
            child: DpadFocusable(
                region: 'recommended',
                debugLabel: 'Recommended ${item['title']}',
                onFocus: () =>
                    debugPrint('Recommended ${item['title']} focused'),
                onSelect: () =>
                    debugPrint('Recommended ${item['title']} selected'),
                builder: (context, isFocused, child) {
                  return AnimatedContainer(
                    width: 208,
                    height: 312,
                    duration: const Duration(milliseconds: 200),
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(20)),
                      image: DecorationImage(
                        image: NetworkImage(item['imageUrl'] as String),
                        fit: BoxFit.cover,
                      ),
                      color: Theme.of(context).cardColor,
                      shadows: isFocused
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor,
                                blurRadius: 12,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            item['title'] as String,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          SizedBox(
            height: 40,
            child: Text(
              item['description'] as String,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Recently added
  Widget _buildRecentlyAdded() {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: recentlyAddedItems.length,
        itemBuilder: (context, index) {
          final item = recentlyAddedItems[index];
          return _buildRecentlyAddedCard(item, index);
        },
      ),
    );
  }

  Widget _buildRecentlyAddedCard(Map<String, dynamic> item, int index) {
    return Container(
      width: 208,
      margin: const EdgeInsets.only(right: 24, top: 12),
      child: DpadFocusable(
        region: 'recent',
        debugLabel: 'Recent ${item['title']}',
        onFocus: () => debugPrint('Recent ${item['title']} focused'),
        onSelect: () => debugPrint('Recent ${item['title']} selected'),
        builder: (context, isFocused, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Expanded(
                child: DpadFocusable(
                    region: 'recent',
                    debugLabel: 'Recent ${item['title']}',
                    onFocus: () =>
                        debugPrint('Recent ${item['title']} focused'),
                    onSelect: () =>
                        debugPrint('Recent ${item['title']} selected'),
                    builder: (context, isFocused, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 208,
                        height: 312,
                        decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: Theme.of(context).cardColor,
                          image: DecorationImage(
                            image: NetworkImage(item['imageUrl'] as String),
                            fit: BoxFit.cover,
                          ),
                          shadows: isFocused
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor,
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                item['title'] as String,
                style: const TextStyle(
                  color: Color(0xFFEAEAEA),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              SizedBox(
                height: 40,
                child: Text(
                  item['description'] as String,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

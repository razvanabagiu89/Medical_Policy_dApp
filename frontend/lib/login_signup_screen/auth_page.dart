import 'package:flutter/material.dart';
import 'login.dart';
import 'registration.dart';
import '../common/pallete.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallete.gradient1,
        title: const Text(
          'Medd dApp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Pallete.gradient1,
                Pallete.gradient2,
                Pallete.gradient3,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Login(),
          Registration(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Pallete.gradient3,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _tabController.index = index;
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: 'Login',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Register',
          ),
        ],
      ),
    );
  }
}

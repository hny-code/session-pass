import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SessionPassApp());
}

class SessionPassApp extends StatelessWidget {
  const SessionPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Session Pass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8FF3B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFE8FF3B))),
          );
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() { _error = 'メールアドレスまたはパスワードが正しくありません'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('SESSION PASS',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFE8FF3B), letterSpacing: 4),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Member App',
                style: TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 12),
                textAlign: TextAlign.center),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8FF3B))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8FF3B))),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Color(0xFFFF4D1C)), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8FF3B),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('ログイン', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _memberId;

  @override
  void initState() {
    super.initState();
    _fetchMemberId();
  }

  Future<void> _fetchMemberId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('members')
        .where('email', isEqualTo: user.email)
        .get();
    if (snap.docs.isNotEmpty) {
      setState(() { _memberId = snap.docs.first.id; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TicketPage(),
      HistoryPage(memberId: _memberId),
      const NoticePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('SESSION PASS',
          style: TextStyle(color: Color(0xFFE8FF3B), fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFE8FF3B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: '回数券'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'お知らせ'),
        ],
      ),
    );
  }
}

class TicketPage extends StatelessWidget {
  const TicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: user?.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF3B)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('会員情報が見つかりません', style: TextStyle(color: Colors.grey)));
        }
        final member = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final tickets = member['tickets'] ?? 0;
        final name = member['name'] ?? '';
        final isLow = tickets <= 3;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('こんにちは、$name さん',
                style: const TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Column(
                  children: [
                    const Text('残り回数', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Text('$tickets',
                      style: TextStyle(
                        fontSize: 96, fontWeight: FontWeight.w900,
                        color: isLow ? const Color(0xFFFF4D1C) : const Color(0xFFE8FF3B),
                        height: 1,
                      )),
                    const SizedBox(height: 8),
                    const Text('枚', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    if (isLow && tickets > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFFFF4D1C),
                        child: const Text('残数わずかです',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                    if (tickets == 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFFFF4D1C),
                        child: const Text('回数券がありません',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('チェックインについて', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
                    SizedBox(height: 8),
                    Text('チェックインはスタッフが操作します。\n道場にお越しの際はスタッフにお声がけください。',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HistoryPage extends StatelessWidget {
  final String? memberId;
  const HistoryPage({super.key, this.memberId});

  @override
  Widget build(BuildContext context) {
    if (memberId == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF3B)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('checkins')
          .where('memberId', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF3B)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('チェックイン履歴がありません', style: TextStyle(color: Colors.grey)));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('チェックイン履歴  ${docs.length}回',
                style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xFF222222), height: 1),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? '${ts.toDate().year}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().day.toString().padLeft(2,'0')}  ${ts.toDate().hour.toString().padLeft(2,'0')}:${ts.toDate().minute.toString().padLeft(2,'0')}'
                      : '—';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    title: Text(date, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: const Color(0xFFE8FF3B),
                      child: const Text('CHECK IN',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE8FF3B)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('お知らせはありません', style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null
                ? '${ts.toDate().year}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().day.toString().padLeft(2,'0')}'
                : '—';
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(data['title'] ?? '',
                    style: const TextStyle(color: Color(0xFFE8FF3B), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(data['body'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

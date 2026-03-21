import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import 'scan_screen.dart';
import 'accounts_screen.dart';
import 'bills_screen.dart';
import 'merchant_qr_screen.dart';
import 'topup_screen.dart';
import 'passport_screen.dart';
import 'visa_screen.dart';
import 'bill_qr_generator_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await WalletService().getDashboard();
      setState(() { _dashboard = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const AccountsScreen(),
      const ScanScreen(),
      const BillsScreen(),
      const MerchantQRScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan & Pay'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'My QR'),
        ],
      ),
    );
  }

  void _pushScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildDashboard() {
    final fmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pay Nomads', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('nomads.one', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService().logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a56db), Color(0xFF7c3aed)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  _loading
                      ? const SizedBox(height: 36, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          fmt.format(_dashboard?['total_balance'] ?? 0),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions — row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(Icons.qr_code_scanner, 'Scan & Pay', () => setState(() => _currentIndex = 2)),
                _quickAction(Icons.receipt_long, 'Bills', () => setState(() => _currentIndex = 3)),
                _quickAction(Icons.add_card, 'Top Up', () => _pushScreen(const TopUpScreen())),
                _quickAction(Icons.store, 'My QR', () => setState(() => _currentIndex = 4)),
              ],
            ),
            const SizedBox(height: 16),

            // Nomad services — row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(Icons.qr_code, 'Bill QR', () => _pushScreen(const BillQrGeneratorScreen())),
                _quickAction(Icons.flight, 'Visa', () => _pushScreen(const VisaScreen())),
                _quickAction(Icons.badge, 'Passport', () => _pushScreen(const PassportScreen())),
                _quickAction(Icons.currency_exchange, 'Exchange', () {}),
              ],
            ),
            const SizedBox(height: 24),

            // Recent transactions
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_dashboard?['recent_transactions'] != null)
              ...(_dashboard!['recent_transactions'] as List).take(10).map((tx) => _txTile(tx, fmt))
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No transactions yet', style: TextStyle(color: Colors.grey[500])),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1a56db).withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1a56db)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _txTile(Map<String, dynamic> tx, NumberFormat fmt) {
    final isCredit = tx['type'] == 'credit' || (tx['amount'] ?? 0) > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isCredit ? Colors.green[50] : Colors.red[50],
        child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.red, size: 20),
      ),
      title: Text(tx['description'] ?? tx['type'] ?? 'Transaction',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Text(
        '${isCredit ? '+' : '-'}${fmt.format((tx['amount'] ?? 0).abs())}',
        style: TextStyle(fontWeight: FontWeight.w600, color: isCredit ? Colors.green : Colors.red[700]),
      ),
    );
  }
}

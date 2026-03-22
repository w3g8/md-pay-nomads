import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import 'scan_screen.dart';
import 'accounts_screen.dart';
import 'cards_screen.dart';
import 'merchant_qr_screen.dart';
import 'topup_screen.dart';
import 'send_screen.dart';
import 'bill_qr_generator_screen.dart';
import 'utilities_screen.dart';
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
      const CardsScreen(),
      const MerchantQRScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Pay'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More'),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pay Nomads', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: NomadsColors.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.logout_outlined, size: 22, color: NomadsColors.textMuted),
                  onPressed: () async {
                    await AuthService().logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance card — hero element
            NCard(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Balance', style: TextStyle(fontSize: 13, color: NomadsColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _loading
                    ? const SizedBox(height: 40, child: CircularProgressIndicator(strokeWidth: 2))
                    : AmountDisplay(
                        currency: 'PHP',
                        amount: (_dashboard?['total_balance'] ?? 0).toDouble(),
                        fontSize: 36,
                      ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: NomadsColors.textMuted, fontSize: 12)),
                  ),
              ]),
            ),
            const SizedBox(height: 24),

            // Quick actions — 4 primary, clean grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _action(Icons.send_outlined, 'Send', () => _push(const SendScreen())),
                _action(Icons.add_circle_outline, 'Top Up', () => _push(const TopUpScreen())),
                _action(Icons.qr_code_scanner_outlined, 'Scan', () => setState(() => _currentIndex = 2)),
                _action(Icons.build_outlined, 'Utilities', () => _push(const UtilitiesScreen())),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _action(Icons.credit_card_outlined, 'Cards', () => setState(() => _currentIndex = 3)),
                _action(Icons.qr_code_outlined, 'My QR', () => setState(() => _currentIndex = 4)),
                _action(Icons.currency_exchange_outlined, 'Exchange', () {}),
                _action(Icons.receipt_long_outlined, 'Bill QR', () => _push(const BillQrGeneratorScreen())),
              ],
            ),
            const SizedBox(height: 32),

            // Recent activity
            const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: NomadsColors.textPrimary)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_dashboard?['recent_transactions'] != null && (_dashboard!['recent_transactions'] as List).isNotEmpty)
              NCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: (_dashboard!['recent_transactions'] as List).take(8).toList().asMap().entries.map((e) {
                    final tx = e.value;
                    final isLast = e.key == (_dashboard!['recent_transactions'] as List).take(8).length - 1;
                    return _txRow(tx, isLast);
                  }).toList(),
                ),
              )
            else
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                subtitle: 'Send money or top up your wallet to get started.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: NomadsColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: NomadsColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: NomadsColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _txRow(Map<String, dynamic> tx, bool isLast) {
    final isCredit = tx['debit_credit'] == 'credit' || tx['type'] == 'credit';
    final amount = _parseAmount(tx['amount']);
    final currency = tx['currency'] ?? '';
    final txType = tx['transaction_type'] ?? tx['type'] ?? '';
    final canRepeat = ['qr_payment', 'invite_hold', 'transfer', 'card_funding', 'bill_payment'].contains(txType);

    return InkWell(
      onTap: () => _showTxDetail(tx, canRepeat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: NomadsColors.border, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isCredit ? NomadsColors.successLight : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? NomadsColors.success : NomadsColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx['description'] ?? txType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: NomadsColors.textMuted)),
          ])),
          AmountDisplay(
            currency: currency,
            amount: amount,
            showSign: true,
            fontSize: 15,
            color: isCredit ? NomadsColors.success : NomadsColors.error,
          ),
        ]),
      ),
    );
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      try {
        final decoded = String.fromCharCodes(Uri.parse('data:,${Uri.decodeComponent(amount)}').data?.contentAsBytes() ?? []);
        return double.tryParse(decoded) ?? double.tryParse(amount) ?? 0;
      } catch (_) {
        return double.tryParse(amount) ?? 0;
      }
    }
    return 0;
  }

  void _showTxDetail(Map<String, dynamic> tx, bool canRepeat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: NomadsColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text(tx['description'] ?? tx['transaction_type'] ?? 'Transaction', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DetailRow(label: 'Amount', value: '${tx['currency'] ?? ''} ${_parseAmount(tx['amount']).abs().toStringAsFixed(2)}', bold: true),
          DetailRow(label: 'Type', value: tx['transaction_type'] ?? tx['type'] ?? ''),
          DetailRow(label: 'Account', value: tx['account_name'] ?? tx['account_number'] ?? ''),
          DetailRow(label: 'Reference', value: tx['reference'] ?? ''),
          DetailRow(label: 'Date', value: tx['created_at']?.toString().substring(0, 19) ?? ''),
          if (canRepeat) ...[
            const SizedBox(height: 20),
            PrimaryButton(label: 'Repeat Payment', onTap: () {
              Navigator.pop(ctx);
              _push(const SendScreen());
            }),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

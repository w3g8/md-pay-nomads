import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/wallet_service.dart';
import '../services/emvco_parser.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

enum BillStep { categories, scanning, form, confirm, done }

class _BillsScreenState extends State<BillsScreen> {
  BillStep _step = BillStep.categories;
  Map<String, dynamic>? _selectedBiller;
  String? _selectedCategory;
  final _accountNumCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  QRPhData? _scannedQR;
  int? _selectedAccountId;
  List<dynamic> _accounts = [];
  List<dynamic> _billers = [];
  bool _loadingBillers = false;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _receipt;
  List<dynamic> _recentBills = [];

  static const categories = [
    {'id': 'electric', 'name': 'Electric', 'icon': Icons.bolt, 'color': Colors.amber},
    {'id': 'water', 'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'id': 'internet', 'name': 'Internet', 'icon': Icons.wifi, 'color': Colors.indigo},
    {'id': 'phone', 'name': 'Phone', 'icon': Icons.phone_android, 'color': Colors.green},
    {'id': 'cable', 'name': 'Cable TV', 'icon': Icons.tv, 'color': Colors.purple},
    {'id': 'insurance', 'name': 'Insurance', 'icon': Icons.shield, 'color': Colors.teal},
    {'id': 'loans', 'name': 'Loans', 'icon': Icons.account_balance, 'color': Colors.brown},
    {'id': 'government', 'name': 'Government', 'icon': Icons.gavel, 'color': Colors.red},
    {'id': 'school', 'name': 'Schools', 'icon': Icons.school, 'color': Colors.orange},
    {'id': 'credit_card', 'name': 'Credit Card', 'icon': Icons.credit_card, 'color': Colors.pink},
    {'id': 'real_estate', 'name': 'Real Estate', 'icon': Icons.home, 'color': Colors.cyan},
    {'id': 'other', 'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadRecentBills();
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await WalletService().getAccounts();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _loadRecentBills() async {
    try {
      _recentBills = await WalletService().getBillPayments();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _loadBillers(String category) async {
    setState(() { _loadingBillers = true; _selectedCategory = category; });
    try {
      _billers = await WalletService().getBillers(category: category);
      setState(() { _loadingBillers = false; });
    } catch (e) {
      // Fallback billers for offline/demo
      _billers = _fallbackBillers(category);
      setState(() { _loadingBillers = false; });
    }
  }

  List<Map<String, dynamic>> _fallbackBillers(String category) {
    switch (category) {
      case 'electric':
        return [
          {'id': 'meralco', 'name': 'Meralco', 'code': 'MERALCO'},
          {'id': 'paleco', 'name': 'PALECO', 'code': 'PALECO'},
          {'id': 'veco', 'name': 'VECO', 'code': 'VECO'},
          {'id': 'beneco', 'name': 'BENECO', 'code': 'BENECO'},
        ];
      case 'water':
        return [
          {'id': 'manila_water', 'name': 'Manila Water', 'code': 'MANILAWATER'},
          {'id': 'maynilad', 'name': 'Maynilad', 'code': 'MAYNILAD'},
          {'id': 'ppwd', 'name': 'Puerto Princesa Water', 'code': 'PPWD'},
        ];
      case 'internet':
        return [
          {'id': 'pldt', 'name': 'PLDT Home', 'code': 'PLDTHOME'},
          {'id': 'globe_broadband', 'name': 'Globe At Home', 'code': 'GLOBEBB'},
          {'id': 'converge', 'name': 'Converge ICT', 'code': 'CONVERGE'},
          {'id': 'sky_broadband', 'name': 'Sky Broadband', 'code': 'SKYBB'},
        ];
      case 'phone':
        return [
          {'id': 'globe', 'name': 'Globe Telecom', 'code': 'GLOBE'},
          {'id': 'smart', 'name': 'Smart / TNT / Sun', 'code': 'SMART'},
          {'id': 'dito', 'name': 'DITO Telecommunity', 'code': 'DITO'},
        ];
      case 'cable':
        return [
          {'id': 'sky_cable', 'name': 'Sky Cable', 'code': 'SKYCABLE'},
          {'id': 'cignal', 'name': 'Cignal TV', 'code': 'CIGNAL'},
        ];
      case 'insurance':
        return [
          {'id': 'sss', 'name': 'SSS', 'code': 'SSS'},
          {'id': 'philhealth', 'name': 'PhilHealth', 'code': 'PHILHEALTH'},
          {'id': 'pagibig', 'name': 'Pag-IBIG', 'code': 'PAGIBIG'},
          {'id': 'sunlife', 'name': 'Sun Life', 'code': 'SUNLIFE'},
        ];
      case 'government':
        return [
          {'id': 'bir', 'name': 'BIR', 'code': 'BIR'},
          {'id': 'nbi', 'name': 'NBI Clearance', 'code': 'NBI'},
          {'id': 'lto', 'name': 'LTO', 'code': 'LTO'},
        ];
      case 'loans':
        return [
          {'id': 'bdo_loan', 'name': 'BDO Loan', 'code': 'BDOLOAN'},
          {'id': 'bpi_loan', 'name': 'BPI Loan', 'code': 'BPILOAN'},
          {'id': 'cimb', 'name': 'CIMB', 'code': 'CIMB'},
        ];
      case 'credit_card':
        return [
          {'id': 'bdo_cc', 'name': 'BDO Credit Card', 'code': 'BDOCC'},
          {'id': 'bpi_cc', 'name': 'BPI Credit Card', 'code': 'BPICC'},
          {'id': 'rcbc_cc', 'name': 'RCBC Credit Card', 'code': 'RCBCCC'},
          {'id': 'metrobank_cc', 'name': 'Metrobank Credit Card', 'code': 'MBCC'},
        ];
      default:
        return [{'id': 'other', 'name': 'Other Biller', 'code': 'OTHER'}];
    }
  }

  Future<void> _payBill() async {
    if (_selectedBiller == null || _selectedAccountId == null || _accountNumCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final res = await WalletService().payBill(
        sourceAccountId: _selectedAccountId!,
        billerCode: _selectedBiller!['code'] ?? _selectedBiller!['id'],
        billerName: _selectedBiller!['name'],
        accountNumber: _accountNumCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        category: _selectedCategory ?? 'other',
      );
      setState(() { _receipt = res; _step = BillStep.done; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _step = BillStep.categories;
      _selectedBiller = null;
      _selectedCategory = null;
      _accountNumCtrl.clear();
      _amountCtrl.clear();
      _selectedAccountId = null;
      _receipt = null;
      _error = null;
      _billers = [];
      _scannedQR = null;
    });
    _loadRecentBills();
  }

  void _onBillQRScan(String raw) {
    final parsed = parseQRPh(raw);
    if (parsed == null) {
      setState(() => _error = 'Not a valid QR Ph bill code');
      return;
    }
    setState(() {
      _scannedQR = parsed;
      _selectedBiller = {
        'name': parsed.merchantName,
        'code': parsed.merchantId,
        'id': parsed.merchantId,
      };
      _accountNumCtrl.text = parsed.referenceLabel ?? parsed.merchantId;
      if (parsed.amount != null) {
        _amountCtrl.text = parsed.amount!.toStringAsFixed(2);
      }
      _selectedCategory = _guessCategoryFromMCC(parsed.mcc);
      _step = BillStep.form;
    });
  }

  String _guessCategoryFromMCC(String mcc) {
    switch (mcc) {
      case '4900': return 'electric';
      case '4816': return 'internet';
      case '4814': return 'phone';
      case '4899': return 'cable';
      case '4812': return 'phone';
      case '6300': return 'insurance';
      case '6012': return 'loans';
      case '9211': case '9222': case '9311': return 'government';
      case '8211': case '8220': case '8299': return 'school';
      default: return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == BillStep.scanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scan Bill QR', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _step = BillStep.categories)),
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) _onBillQRScan(code);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: const Text(
                'Point at a Philippine bill QR code\nAmount and merchant will be auto-filled',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bills'),
        leading: _step != BillStep.categories
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
                if (_step == BillStep.done) { _reset(); return; }
                setState(() {
                  if (_step == BillStep.confirm) {
                    _step = BillStep.form;
                  } else if (_step == BillStep.form) {
                    _step = BillStep.categories;
                    _selectedBiller = null;
                    _scannedQR = null;
                  }
                });
              })
            : null,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case BillStep.categories:
        return _buildCategories();
      case BillStep.scanning:
        return const SizedBox(); // handled in build()
      case BillStep.form:
        return _buildForm();
      case BillStep.confirm:
        return _buildConfirm();
      case BillStep.done:
        return _buildDone();
    }
  }

  Widget _buildCategories() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) _errorBanner(),

        // Scan Bill QR button
        GestureDetector(
          onTap: () => setState(() => _step = BillStep.scanning),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF1a56db), Color(0xFF7c3aed)]),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Scan Bill QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  Text('Auto-fill amount from Philippine bill QR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ],
            ),
          ),
        ),

        // Category grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
          children: categories.map((cat) => _categoryTile(cat)).toList(),
        ),

        // Billers list (shown after selecting a category)
        if (_selectedCategory != null) ...[
          const SizedBox(height: 20),
          Text(
            categories.firstWhere((c) => c['id'] == _selectedCategory, orElse: () => {'name': 'Billers'})['name'] as String,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_loadingBillers)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ...(_billers).map((b) => _billerTile(b)),
        ],

        // Recent bills
        if (_selectedCategory == null && _recentBills.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._recentBills.take(5).map((bill) => _recentBillTile(bill)),
        ],
      ],
    );
  }

  Widget _categoryTile(Map<String, dynamic> cat) {
    final isSelected = _selectedCategory == cat['id'];
    final color = cat['color'] as MaterialColor;
    return GestureDetector(
      onTap: () => _loadBillers(cat['id'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey[200]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat['icon'] as IconData, size: 28, color: color),
            const SizedBox(height: 8),
            Text(cat['name'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? color[700] : Colors.black87),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _billerTile(dynamic biller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1a56db).withAlpha(25),
          child: Text((biller['name'] as String).substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a56db))),
        ),
        title: Text(biller['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(biller['code'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          setState(() {
            _selectedBiller = Map<String, dynamic>.from(biller);
            _step = BillStep.form;
          });
        },
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(),

        // QR scanned indicator
        if (_scannedQR != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.qr_code, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Scanned from QR code${_scannedQR!.amount != null ? ' \u2014 PHP ${_scannedQR!.amount!.toStringAsFixed(2)}' : ''}',
                style: TextStyle(color: Colors.green[700], fontSize: 13),
              )),
            ]),
          ),

        // Biller header
        _card(child: Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF1a56db).withAlpha(25),
            child: Text((_selectedBiller!['name'] as String).substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a56db))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_selectedBiller!['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text(_selectedBiller!['code'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        ])),
        const SizedBox(height: 20),

        // Account number
        const Text('Account / Reference Number', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNumCtrl,
          decoration: InputDecoration(
            hintText: 'Enter your account number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),

        // Amount
        const Text('Amount', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          decoration: InputDecoration(
            prefixText: 'PHP ',
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Source account
        const Text('Pay From', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedAccountId,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
            DropdownMenuItem(value: a['id'], child: Text(
              '${a['name'] ?? a['account_number']} — ${a['currency']} ${(a['available_balance'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13),
            ))).toList(),
          onChanged: (v) => setState(() => _selectedAccountId = v),
        ),
        const SizedBox(height: 24),

        _gradientButton('Review Payment', () {
          if (_accountNumCtrl.text.isNotEmpty && _amountCtrl.text.isNotEmpty && _selectedAccountId != null) {
            setState(() => _step = BillStep.confirm);
          }
        }),
      ],
    );
  }

  Widget _buildConfirm() {
    final fmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(),

        _card(child: Column(children: [
          const Text('Confirm Bill Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          _detailRow('Biller', _selectedBiller!['name']),
          _detailRow('Category', _selectedCategory ?? ''),
          _detailRow('Account No.', _accountNumCtrl.text),
          const Divider(),
          _detailRow('Amount', fmt.format(amount), bold: true, fontSize: 18),
        ])),
        const SizedBox(height: 20),

        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => _step = BillStep.form),
            child: const Text('Back'),
          )),
          const SizedBox(width: 12),
          Expanded(child: _gradientButton(
            _submitting ? 'Processing...' : 'Pay Now',
            _submitting ? null : _payBill,
          )),
        ]),
      ],
    );
  }

  Widget _buildDone() {
    final fmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Center(child: CircleAvatar(radius: 36, backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.check_circle, color: Colors.green, size: 40))),
        const SizedBox(height: 16),
        const Center(child: Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),
        _card(child: Column(children: [
          _detailRow('Biller', _selectedBiller?['name'] ?? ''),
          _detailRow('Account No.', _accountNumCtrl.text),
          _detailRow('Amount', fmt.format(_receipt?['amount'] ?? double.tryParse(_amountCtrl.text) ?? 0), bold: true),
          if (_receipt?['fee_amount'] != null && (_receipt!['fee_amount'] ?? 0) > 0)
            _detailRow('Fee', fmt.format(_receipt!['fee_amount'])),
          _detailRow('Reference', _receipt?['reference'] ?? _receipt?['transaction_id'] ?? ''),
          _detailRow('Date', _receipt?['created_at']?.toString().substring(0, 19) ?? DateTime.now().toString().substring(0, 19)),
        ])),
        const SizedBox(height: 24),
        _gradientButton('Done', _reset),
      ],
    );
  }

  Widget _recentBillTile(dynamic bill) {
    final fmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: Icon(Icons.receipt_long, color: Colors.green[600], size: 20),
        ),
        title: Text(bill['biller_name'] ?? bill['description'] ?? 'Bill Payment',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(bill['created_at']?.toString().substring(0, 10) ?? '',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: Text(fmt.format(bill['amount'] ?? 0),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        onTap: () {
          // Quick re-pay: prefill the biller
          setState(() {
            _selectedBiller = {'name': bill['biller_name'] ?? '', 'code': bill['biller_code'] ?? '', 'id': bill['biller_code'] ?? ''};
            _accountNumCtrl.text = bill['account_number'] ?? '';
            _selectedCategory = bill['category'] ?? 'other';
            _step = BillStep.form;
          });
        },
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _error = null)),
      ]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: fontSize)),
        Flexible(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: fontSize),
            textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _gradientButton(String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: onTap == null
              ? [Colors.grey[400]!, Colors.grey[400]!]
              : [const Color(0xFF1a56db), const Color(0xFF7c3aed)]),
        ),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
      ),
    );
  }
}

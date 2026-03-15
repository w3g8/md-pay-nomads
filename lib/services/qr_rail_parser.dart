/// Multi-rail QR payment parser.
/// Detects and parses: QR Ph, PromptPay (TH), QRIS (ID), VietQR (VN), PIX (BR), PayNow (SG), DuitNow (MY)

import 'emvco_parser.dart';

enum QRRail { qrph, promptpay, qris, vietqr, pix, paynow, duitnow, unknown }

class QRRailResult {
  final QRRail rail;
  final String railName;
  final String countryFlag;
  final String merchantName;
  final String merchantCity;
  final String merchantId;
  final String? acquirerName;
  final String currency;
  final String currencyCode;
  final double? amount;
  final String countryCode;
  final String mcc;
  final String mccDescription;
  final bool crcValid;
  final String rawData;
  final Map<String, String> tlv;

  QRRailResult({
    required this.rail,
    required this.railName,
    required this.countryFlag,
    required this.merchantName,
    required this.merchantCity,
    required this.merchantId,
    this.acquirerName,
    required this.currency,
    required this.currencyCode,
    this.amount,
    required this.countryCode,
    required this.mcc,
    required this.mccDescription,
    required this.crcValid,
    required this.rawData,
    required this.tlv,
  });
}

/// GUID patterns for each rail
const _railGuids = {
  'ph.ppmi': QRRail.qrph,
  'A000000677': QRRail.promptpay,         // PromptPay AID
  'com.p2p.ctpl': QRRail.promptpay,       // PromptPay P2P
  'ID.CO.QRIS': QRRail.qris,
  'vn.napas': QRRail.vietqr,
  'br.gov.bcb.pix': QRRail.pix,
  'sg.paynow': QRRail.paynow,
  'sg.com.nets': QRRail.paynow,
  'my.com.paynet': QRRail.duitnow,
};

const _railNames = {
  QRRail.qrph: 'QR Ph P2M',
  QRRail.promptpay: 'PromptPay',
  QRRail.qris: 'QRIS',
  QRRail.vietqr: 'VietQR',
  QRRail.pix: 'PIX',
  QRRail.paynow: 'PayNow / SGQR',
  QRRail.duitnow: 'DuitNow QR',
  QRRail.unknown: 'Unknown',
};

const _railFlags = {
  QRRail.qrph: '🇵🇭',
  QRRail.promptpay: '🇹🇭',
  QRRail.qris: '🇮🇩',
  QRRail.vietqr: '🇻🇳',
  QRRail.pix: '🇧🇷',
  QRRail.paynow: '🇸🇬',
  QRRail.duitnow: '🇲🇾',
  QRRail.unknown: '🌍',
};

const _railCurrencies = {
  QRRail.qrph: ('PHP', '608'),
  QRRail.promptpay: ('THB', '764'),
  QRRail.qris: ('IDR', '360'),
  QRRail.vietqr: ('VND', '704'),
  QRRail.pix: ('BRL', '986'),
  QRRail.paynow: ('SGD', '702'),
  QRRail.duitnow: ('MYR', '458'),
};

/// Detect which rail a QR code belongs to by scanning merchant info tags 26-51
QRRail _detectRail(Map<String, String> tlv) {
  for (var tag = 26; tag <= 51; tag++) {
    final tagStr = tag.toString().padLeft(2, '0');
    final value = tlv[tagStr];
    if (value == null) continue;
    final sub = parseTLV(value);
    final guid = (sub['00'] ?? '').toLowerCase();
    for (final entry in _railGuids.entries) {
      if (guid.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
  }
  // Fallback: check country code
  switch (tlv['58']?.toUpperCase()) {
    case 'TH': return QRRail.promptpay;
    case 'ID': return QRRail.qris;
    case 'VN': return QRRail.vietqr;
    case 'BR': return QRRail.pix;
    case 'SG': return QRRail.paynow;
    case 'MY': return QRRail.duitnow;
    case 'PH': return QRRail.qrph;
    default: return QRRail.unknown;
  }
}

/// Extract merchant ID from the rail-specific merchant info block
(String merchantId, String? acquirerName) _extractMerchantInfo(Map<String, String> tlv, QRRail rail) {
  for (var tag = 26; tag <= 51; tag++) {
    final tagStr = tag.toString().padLeft(2, '0');
    final value = tlv[tagStr];
    if (value == null) continue;
    final sub = parseTLV(value);
    // Most rails: 00=GUID, 01=acquirer/proxy, 02-03=merchant account
    final id = sub['03'] ?? sub['02'] ?? sub['01'] ?? '';
    String? acq;
    if (rail == QRRail.qrph) acq = bicLabel(sub['01'] ?? '');
    if (rail == QRRail.promptpay) acq = 'PromptPay';
    if (rail == QRRail.qris) acq = sub['01'] ?? 'QRIS';
    if (rail == QRRail.pix) acq = 'PIX';
    if (id.isNotEmpty) return (id, acq);
  }
  return ('', null);
}

/// Parse any EMVCo-compliant QR code and detect the payment rail
QRRailResult? parseQRCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.length < 20) return null;

  final tlv = parseTLV(trimmed);
  if (tlv['00'] != '01') return null; // Must be EMVCo QR

  final rail = _detectRail(tlv);
  final (merchantId, acquirerName) = _extractMerchantInfo(tlv, rail);

  final mcc = tlv['52'] ?? '5999';
  final currencyCode = tlv['53'] ?? '';
  final amountStr = tlv['54'];

  // Determine currency
  final railCurrency = _railCurrencies[rail];
  final currency = currencyMap[currencyCode] ?? railCurrency?.$1 ?? currencyCode;
  final curCode = currencyCode.isNotEmpty ? currencyCode : (railCurrency?.$2 ?? '');

  return QRRailResult(
    rail: rail,
    railName: _railNames[rail] ?? 'Unknown',
    countryFlag: _railFlags[rail] ?? '🌍',
    merchantName: tlv['59'] ?? 'Merchant',
    merchantCity: tlv['60'] ?? '',
    merchantId: merchantId,
    acquirerName: acquirerName,
    currency: currency,
    currencyCode: curCode,
    amount: amountStr != null ? double.tryParse(amountStr) : null,
    countryCode: tlv['58'] ?? '',
    mcc: mcc,
    mccDescription: mccMap[mcc] ?? 'Merchant',
    crcValid: verifyCRC(trimmed),
    rawData: trimmed,
    tlv: tlv,
  );
}

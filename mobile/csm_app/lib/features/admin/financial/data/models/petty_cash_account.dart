class PettyCashAccount {
  const PettyCashAccount({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.siteName,
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String siteName;
  final String accountCode;
  final String accountName;
  final double openingBalance;
  final double currentBalance;
  final bool isActive;

  factory PettyCashAccount.fromJson(Map<String, dynamic> json) {
    return PettyCashAccount(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId: json['constructionSiteId'] as String,
      siteName: json['siteName'] as String? ?? '',
      accountCode: json['accountCode'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      openingBalance: (json['openingBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
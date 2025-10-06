// Result & Failure (unchanged)
class Result<T> {
  final T? data;
  final Failure? failure;
  const Result._({this.data, this.failure});
  bool get isSuccess => failure == null;
  bool get isFailure => !isSuccess;
  static Result<T> ok<T>(T data) => Result._(data: data);
  static Result<T> fail<T>(Failure failure) => Result._(failure: failure);
}

class Failure {
  final String
      code; // network | timeout | server | parse | validation | unknown
  final String message;
  final int? statusCode;
  const Failure({required this.code, required this.message, this.statusCode});
  @override
  String toString() => 'Failure($code, $statusCode): $message';
}

// Enums & helpers
enum AccountType { USER, COMPANY, TASKER }

String accountTypeToApi(AccountType t) {
  switch (t) {
    case AccountType.USER:
      return 'user';
    case AccountType.TASKER:
      return 'tasker';
    case AccountType.COMPANY:
      return 'company'; // or 'business' if your API expects that Testing@123
  }
}

class SelectableItem {
  final String id;
  final String name;
  final bool isSelected;
  const SelectableItem(
      {required this.id, required this.name, this.isSelected = false});

  // If your backend only needs IDs for some fields, you can switch to {'id': id}
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isSelected': isSelected,
      };
}

// Helper to remove empty / null keys
extension _JsonClean on Map<String, dynamic> {
  Map<String, dynamic> cleaned() {
    final out = <String, dynamic>{};
    for (final e in entries) {
      final v = e.value;
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      if (v is List && v.isEmpty) continue;
      if (v is Map && v.isEmpty) continue;
      out[e.key] = v;
    }
    return out;
  }
}

class RegistrationRequest {
  final AccountType type;

  // common
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String password;

  // lists
  final List<SelectableItem>? desiredService;
  final List<SelectableItem>? companyCategory;
  final List<SelectableItem>? companySubCategory;

  // company-only
  final String? abn;
  final String? representativeName;
  final String? representativeNumber;

  // tasker-only
  final String? address;

  RegistrationRequest._({
    required this.type,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.password,
    this.desiredService,
    this.companyCategory,
    this.companySubCategory,
    this.abn,
    this.representativeName,
    this.representativeNumber,
    this.address,
  });

  factory RegistrationRequest.user({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
  }) =>
      RegistrationRequest._(
        type: AccountType.USER,
        fullName: fullName,
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        password: password,
        desiredService: desiredService ?? const [],
        companyCategory: companyCategory ?? const [],
        companySubCategory: companySubCategory ?? const [],
        abn: abn,
      );

  factory RegistrationRequest.company({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    List<SelectableItem>? desiredService,
    List<SelectableItem>? companyCategory,
    List<SelectableItem>? companySubCategory,
    String? abn,
    String? representativeName,
    String? representativeNumber,
  }) =>
      RegistrationRequest._(
        type: AccountType.COMPANY,
        fullName: fullName,
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        password: password,
        desiredService: desiredService ?? const [],
        companyCategory: companyCategory ?? const [],
        companySubCategory: companySubCategory ?? const [],
        abn: abn,
        representativeName: representativeName,
        representativeNumber: representativeNumber,
      );

  factory RegistrationRequest.tasker({
    required String fullName,
    required String phoneNumber,
    required String emailAddress,
    required String password,
    String? address,
  }) =>
      RegistrationRequest._(
        type: AccountType.TASKER,
        fullName: fullName,
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        password: password,
        address: address,
      );

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>>? mapList(List<SelectableItem>? l) =>
        (l == null || l.isEmpty) ? null : l.map((e) => e.toJson()).toList();

    final base = <String, dynamic>{
      'type': accountTypeToApi(type),
      'fullname': fullName,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'password': password,
    };

    switch (type) {
      case AccountType.USER:
        base['desiredService'] = mapList(desiredService);
        base['companyCategory'] = mapList(companyCategory);
        base['companySubCategory'] = mapList(companySubCategory);
        base['abn'] = abn ?? '';
        break;
      case AccountType.COMPANY:
        base['desiredService'] = mapList(desiredService);
        base['companyCategory'] = mapList(companyCategory);
        base['companySubCategory'] = mapList(companySubCategory);
        base['abn'] = abn ?? '';
        base['representativeName'] = representativeName ?? '';
        base['representativeNumber'] = representativeNumber ?? '';
        break;
      case AccountType.TASKER:
        base['address'] = address ?? '';
        break;
    }
    return base.cleaned();
  }
}

class ApiErrorItem {
  final String field;
  final String error;
  ApiErrorItem({required this.field, required this.error});
  factory ApiErrorItem.fromJson(Map<String, dynamic> json) => ApiErrorItem(
        field: (json['field'] ?? '').toString(),
        error: (json['error'] ?? '').toString(),
      );
}

class RegistrationResult {
  final String? userId;
  final String? token;
  RegistrationResult({this.userId, this.token});
  factory RegistrationResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return RegistrationResult();
    return RegistrationResult(
      userId: json['userId']?.toString(),
      token: json['token']?.toString(),
    );
  }
}

class RegistrationResponse {
  final bool isSuccess;
  final String? message;
  final RegistrationResult? result;
  final List<ApiErrorItem> errors;
  final int? statusCode;

  RegistrationResponse({
    required this.isSuccess,
    this.message,
    this.result,
    this.errors = const [],
    this.statusCode,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString(),
      result:
          RegistrationResult.fromJson(json['result'] as Map<String, dynamic>?),
      errors: ((json['errors'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map(ApiErrorItem.fromJson)
          .toList(),
      statusCode: json['statusCode'] is int
          ? json['statusCode'] as int
          : int.tryParse('${json['statusCode'] ?? ''}'),
    );
  }
}

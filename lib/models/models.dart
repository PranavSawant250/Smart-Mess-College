// models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role; // 'student' or 'admin'
  final String rollNumber;
  final String prn;
  final String branch;
  final String passoutYear;
  final String hostelName;
  final String messId;
  final int? messStudentId;
  final bool biometricEnabled;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.password,
    required this.role,
    this.rollNumber = '',
    this.prn = '',
    this.branch = '',
    this.passoutYear = '',
    this.hostelName = '',
    this.messId = '',
    this.messStudentId,
    this.biometricEnabled = false,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'rollNumber': rollNumber,
        'prn': prn,
        'branch': branch,
        'passoutYear': passoutYear,
        'hostelName': hostelName,
        'messId': messId,
        'messStudentId': messStudentId,
        'biometricEnabled': biometricEnabled,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        password: json['password'] ?? '',
        role: json['role'] ?? 'student',
        rollNumber: json['rollNumber'] ?? '',
        prn: json['prn'] ?? '',
        branch: json['branch'] ?? '',
        passoutYear: json['passoutYear'] ?? '',
        hostelName: json['hostelName'] ?? '',
        messId: json['messId']?.toString() ?? '',
        messStudentId: json['messStudentId'],
        biometricEnabled: json['biometricEnabled'] ?? false,
      );
}

class Mess {
  final String id;
  final String messName;
  final String adminId;
  final String address;
  final int monthlyFee;
  final String description;
  final String upiId;
  final String qrCodeImage;

  Mess({
    required this.id,
    required this.messName,
    required this.adminId,
    this.address = '',
    this.monthlyFee = 0,
    this.description = '',
    this.upiId = '',
    this.qrCodeImage = '',
  });

  factory Mess.fromJson(Map<String, dynamic> json) => Mess(
        id: json['_id'] ?? json['id'] ?? '',
        messName: json['messName'] ?? '',
        adminId: json['adminId'] is Map ? (json['adminId']['_id'] ?? json['adminId']['id'] ?? '') : (json['adminId'] ?? ''),
        address: json['address'] ?? '',
        monthlyFee: (json['monthlyFee'] ?? 0) is num ? (json['monthlyFee'] as num).toInt() : int.tryParse(json['monthlyFee'].toString()) ?? 0,
        description: json['description'] ?? '',
        upiId: json['upiId'] ?? '',
        qrCodeImage: json['qrCodeImage'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'messName': messName,
        'adminId': adminId,
        'address': address,
        'monthlyFee': monthlyFee,
        'description': description,
        'upiId': upiId,
        'qrCodeImage': qrCodeImage,
      };
}

class JoinRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String messId;
  String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.messId,
    this.status = 'pending',
    required this.requestedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['studentId'] is Map ? (json['studentId']['_id'] ?? json['studentId']['id'] ?? '') : (json['studentId'] ?? ''),
        userName: json['studentName'] ?? '',
        userEmail: json['studentEmail'] ?? '',
        userPhone: json['studentPhone'] ?? '',
        messId: json['messId'] ?? '',
        status: json['status'] ?? 'pending',
        requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : DateTime.now(),
      );
}

class MealPoll {
  final String id;
  final String title;
  final String mealTime;
  final DateTime date;
  final List<MealOption> vegOptions;
  final List<MealOption> nonVegOptions;
  final List<MealOption> fastOptions;
  bool isActive;
  bool isFinalized;
  String? finalizedVeg;
  String? finalizedNonVeg;
  String? finalizedFast;
  int totalVeg;
  int totalNonVeg;
  int totalFast;
  int totalNotComing;
  final DateTime? pollStartTime;
  final DateTime? pollEndTime;

  MealPoll({
    required this.id,
    required this.title,
    required this.mealTime,
    required this.date,
    required this.vegOptions,
    required this.nonVegOptions,
    required this.fastOptions,
    this.isActive = true,
    this.isFinalized = false,
    this.finalizedVeg,
    this.finalizedNonVeg,
    this.finalizedFast,
    this.totalVeg = 0,
    this.totalNonVeg = 0,
    this.totalFast = 0,
    this.totalNotComing = 0,
    this.pollStartTime,
    this.pollEndTime,
  });

  factory MealPoll.fromJson(Map<String, dynamic> json) => MealPoll(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        mealTime: json['mealTime'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        vegOptions: (json['vegOptions'] as List?)?.map((x) => MealOption.fromJson(x)).toList() ?? [],
        nonVegOptions: (json['nonVegOptions'] as List?)?.map((x) => MealOption.fromJson(x)).toList() ?? [],
        fastOptions: (json['fastOptions'] as List?)?.map((x) => MealOption.fromJson(x)).toList() ?? [],
        isActive: json['isActive'] ?? true,
        isFinalized: json['isFinalized'] ?? false,
        finalizedVeg: json['finalizedVeg'],
        finalizedNonVeg: json['finalizedNonVeg'],
        finalizedFast: json['finalizedFast'],
        totalVeg: json['totalVeg'] ?? 0,
        totalNonVeg: json['totalNonVeg'] ?? 0,
        totalFast: json['totalFast'] ?? 0,
        totalNotComing: json['totalNotComing'] ?? 0,
        pollStartTime: json['pollStartTime'] != null ? DateTime.parse(json['pollStartTime']) : null,
        pollEndTime: json['pollEndTime'] != null ? DateTime.parse(json['pollEndTime']) : null,
      );
}

class MealOption {
  final String id;
  final String name;
  final String description;
  int votes;

  MealOption({
    required this.id,
    required this.name,
    this.description = '',
    this.votes = 0,
  });

  factory MealOption.fromJson(Map<String, dynamic> json) => MealOption(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        votes: json['votes'] ?? 0,
      );
}

class Vote {
  final String userId;
  final String pollId;
  final String mealType;
  final String optionId;
  final List<String> optionIds;
  final bool isComing;
  final DateTime votedAt;

  Vote({
    required this.userId,
    required this.pollId,
    required this.mealType,
    required this.optionId,
    required this.optionIds,
    required this.isComing,
    required this.votedAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => Vote(
        userId: json['userId'] is Map ? (json['userId']['_id'] ?? json['userId']['id'] ?? '') : (json['userId'] ?? ''),
        pollId: json['pollId'] ?? '',
        mealType: json['mealType'] ?? '',
        optionId: json['optionId'] ?? '',
        optionIds: (json['optionIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isComing: json['isComing'] ?? true,
        votedAt: json['votedAt'] != null ? DateTime.parse(json['votedAt']) : DateTime.now(),
      );
}

class MealFeedback {
  final String id;
  final String userId;
  final String userName;
  final String pollId;
  final int foodQuality;
  final int taste;
  final int service;
  final String comment;
  final DateTime submittedAt;

  MealFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pollId,
    required this.foodQuality,
    required this.taste,
    required this.service,
    required this.comment,
    required this.submittedAt,
  });

  double get averageRating => (foodQuality + taste + service) / 3;

  factory MealFeedback.fromJson(Map<String, dynamic> json) => MealFeedback(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] is Map ? (json['userId']['_id'] ?? json['userId']['id'] ?? '') : (json['userId'] ?? ''),
        userName: json['userName'] ?? '',
        pollId: json['pollId'] is Map ? (json['pollId']['_id'] ?? json['pollId']['id'] ?? '') : (json['pollId'] ?? ''),
        foodQuality: json['foodQuality'] ?? 0,
        taste: json['taste'] ?? 0,
        service: json['service'] ?? 0,
        comment: json['comment'] ?? '',
        submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : DateTime.now(),
      );
}

class KitchenOrder {
  final String id;
  final String pollId;
  final String mealTime;
  final DateTime date;
  final int vegCount;
  final int nonVegCount;
  final int fastCount;
  final String finalVegMenu;
  final String finalNonVegMenu;
  final String finalFastMenu;
  final DateTime sentAt;

  KitchenOrder({
    required this.id,
    required this.pollId,
    required this.mealTime,
    required this.date,
    required this.vegCount,
    required this.nonVegCount,
    required this.fastCount,
    required this.finalVegMenu,
    required this.finalNonVegMenu,
    required this.finalFastMenu,
    required this.sentAt,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) => KitchenOrder(
        id: json['_id'] ?? json['id'] ?? '',
        pollId: json['pollId'] is Map ? (json['pollId']['_id'] ?? json['pollId']['id'] ?? '') : (json['pollId'] ?? ''),
        mealTime: json['mealTime'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        vegCount: json['vegCount'] ?? 0,
        nonVegCount: json['nonVegCount'] ?? 0,
        fastCount: json['fastCount'] ?? 0,
        finalVegMenu: json['finalVegMenu'] ?? '',
        finalNonVegMenu: json['finalNonVegMenu'] ?? '',
        finalFastMenu: json['finalFastMenu'] ?? '',
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : DateTime.now(),
      );
}

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.data,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['_id'] ?? json['id'] ?? '',
        userId: json['userId'] ?? '',
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        isRead: json['isRead'] ?? false,
        data: json['data'] ?? {},
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );
}

class Announcement {
  final String id;
  final String messId;
  final String title;
  final String body;
  final String type;
  final bool isActive;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.messId,
    required this.title,
    required this.body,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['_id'] ?? json['id'] ?? '',
        messId: json['messId'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] ?? 'general',
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );
}

class AttendanceRecord {
  final String pollId;
  final DateTime date;
  final String mealTime;
  final String status;

  AttendanceRecord({
    required this.pollId,
    required this.date,
    required this.mealTime,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        pollId: json['pollId'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
        mealTime: json['mealTime'] ?? '',
        status: json['status'] ?? 'missed',
      );
}

class Attendance {
  final String userId;
  final String messId;
  final int month;
  final int year;
  final int totalMeals;
  final int attendedMeals;
  final int skippedMeals;
  final int missedMeals;
  final double attendancePercentage;
  final double billAmount;
  final List<AttendanceRecord> records;

  Attendance({
    required this.userId,
    required this.messId,
    required this.month,
    required this.year,
    required this.totalMeals,
    required this.attendedMeals,
    required this.skippedMeals,
    required this.missedMeals,
    required this.attendancePercentage,
    required this.billAmount,
    required this.records,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        userId: json['userId'] ?? '',
        messId: json['messId'] ?? '',
        month: json['month'] ?? 1,
        year: json['year'] ?? 2026,
        totalMeals: json['totalMeals'] ?? 0,
        attendedMeals: json['attendedMeals'] ?? 0,
        skippedMeals: json['skippedMeals'] ?? 0,
        missedMeals: json['missedMeals'] ?? 0,
        attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
        billAmount: (json['billAmount'] ?? 0).toDouble(),
        records: (json['records'] as List?)?.map((x) => AttendanceRecord.fromJson(x)).toList() ?? [],
      );
}

class Transaction {
  final String id;
  final String studentId;
  final String messId;
  final double amount;
  final String paymentMode;
  final String paymentStatus;
  final DateTime paymentDate;
  final String paymentScreenshot;
  final String proofImage;
  final String transactionId;

  Transaction({
    required this.id,
    required this.studentId,
    required this.messId,
    required this.amount,
    required this.paymentMode,
    required this.paymentStatus,
    required this.paymentDate,
    required this.paymentScreenshot,
    required this.proofImage,
    required this.transactionId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['_id'] ?? json['id'] ?? '',
        studentId: json['studentId'] is Map
            ? (json['studentId']['_id'] ?? json['studentId']['id'] ?? '')
            : (json['studentId'] ?? ''),
        messId: json['messId'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paymentMode: json['paymentMode'] ?? '',
        paymentStatus: json['paymentStatus'] ?? '',
        paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : DateTime.now(),
        paymentScreenshot: json['paymentScreenshot'] ?? '',
        proofImage: json['proofImage'] ?? '',
        transactionId: json['transactionId'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'studentId': studentId,
        'messId': messId,
        'amount': amount,
        'paymentMode': paymentMode,
        'paymentStatus': paymentStatus,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentScreenshot': paymentScreenshot,
        'proofImage': proofImage,
        'transactionId': transactionId,
      };
}

import 'package:isar/isar.dart';

part 'isar_user.g.dart';

@collection
class IsarUser {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String email;

  late String password;
  late String fullName;
  late String company;
  late String taxCode;
  
  // Store role as string, e.g. "financeManager", "expenseAccountant", "revenueAccountant"
  late String role;
}

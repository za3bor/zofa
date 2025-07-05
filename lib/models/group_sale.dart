import 'package:zofa/models/group.dart';

class GroupSale {
  final int saleId;
  final String saleName;
  final List<Group> groups;
  final bool active;

  GroupSale({
    required this.saleId,
    required this.saleName,
    required this.groups,
    required this.active,
  });
}
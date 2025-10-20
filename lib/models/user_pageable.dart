part of '../models.dart';

/// User pageable model for list responses with pagination
class UserPageable extends Pageable<User> {
  UserPageable({required super.data, super.meta});

  factory UserPageable.fromJson(Map<String, dynamic> map) {
    final dataList =
        (map['data'] as List?)
            ?.map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = map['meta'] != null
        ? PaginationMeta.fromJson(map['meta'])
        : null;

    return UserPageable(data: dataList, meta: meta);
  }

  @override
  User parseItem(Map<String, dynamic> itemMap) => User.fromJson(itemMap);

  @override
  Map<String, dynamic> itemToMap(User item) => item.toMap();
}

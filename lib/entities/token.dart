import 'package:app/utils/helper.dart';

class Token {
  int id;
  int penggunaId;
  String token = '';
  String expiredDate = '';
  String playerId = '';
  final String createdAt;
  final String updatedAt;
  final String deletedAt;

  Token({
    required this.id,
    required this.penggunaId,
    required this.token,
    required this.expiredDate,
    required this.playerId,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return getToken(json);
  }

  static getToken(Map<String, dynamic> json){
    if (json != null && json['id'] != null) {
      return Token(
        id: Helper().toInt(json['id']),
        penggunaId: Helper().toInt(json['pengguna_id']),
        token: json['token'],
        expiredDate: json['expired_date'],
        playerId: json['player_id'] ?? '',
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        deletedAt: json['deleted_at'] ?? '',
      );
    }
    return null;
  }

  Map toJson() => {
    'id': id,
    'pengguna_id': penggunaId,
    'token': token,
    'expired_date': expiredDate,
    'player_id': playerId,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'deleted_at': deletedAt,
  };
}
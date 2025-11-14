class RoomChatModel {
  final String roomId;
  final String roomType;
  final String usernameLawan;
  final String idLawan;
  final String idMediaLawan;
  final String tipeUserLawan;
  final DateTime lastMessageAt;
  final String lastMessage;
  final String status;
  final int? unread;
  final List<String> userIds;

  RoomChatModel({
    required this.roomId,
    required this.roomType,
    required this.usernameLawan,
    required this.idLawan,
    required this.idMediaLawan,
    required this.tipeUserLawan,
    required this.lastMessageAt,
    required this.lastMessage,
    required this.status,
    this.unread,
    required this.userIds,
  });

  RoomChatModel copyWith({
    String? roomId,
    String? roomType,
    String? usernameLawan,
    String? idLawan,
    String? idMediaLawan,
    String? tipeUserLawan,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? status,
    int? unread,
    List<String>? userIds,
  }) {
    return RoomChatModel(
      roomId: roomId ?? this.roomId,
      roomType: roomType ?? this.roomType,
      usernameLawan: usernameLawan ?? this.usernameLawan,
      idLawan: idLawan ?? this.idLawan,
      idMediaLawan: idMediaLawan ?? this.idMediaLawan,
      tipeUserLawan: tipeUserLawan ?? this.tipeUserLawan,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      status: status ?? this.status,
      unread: unread ?? this.unread,
      userIds: userIds ?? List<String>.from(this.userIds),
    );
  }

  factory RoomChatModel.fromJson(Map<String, dynamic> json) {
    return RoomChatModel(
      roomId: json["Room_Id"],
      roomType: json["Room_Type"],
      usernameLawan: json["Username_Lawan"],
      idLawan: json["Id_Lawan"],
      idMediaLawan: json["Id_Media_Lawan"],
      tipeUserLawan: json["Tipe_User_Lawan"],
      lastMessageAt: DateTime.parse(json["Last_Message_At"]),
      lastMessage: json["Last_Message"],
      status: json["Status"],
      unread: json["Unread"],
      userIds:
          (json["User_Ids"] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Room_Id": roomId,
      "Room_Type": roomType,
      "Username_Lawan": usernameLawan,
      "Id_Lawan": idLawan,
      "Id_Media_Lawan": idMediaLawan,
      "Tipe_User_Lawan": tipeUserLawan,
      "Last_Message_At": lastMessageAt.toIso8601String(),
      "Last_Message": lastMessage,
      "Status": status,
      "Unread": unread,
      "User_Ids": userIds,
    };
  }
}

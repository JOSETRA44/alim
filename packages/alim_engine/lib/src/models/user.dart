/// Usuario visible en la app (propio o interlocutor).
class AlimUser {
  const AlimUser({
    required this.id,
    required this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) => other is AlimUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

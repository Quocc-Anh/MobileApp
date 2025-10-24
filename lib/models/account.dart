class Account {
  final String id;
  final String name;
  final double initialBalance;

  Account({required this.id, required this.name, required this.initialBalance});

  Map<String, dynamic> toJson() => {'name': name, 'initialBalance': initialBalance};

  factory Account.fromJson(String id, Map<String, dynamic> json) {
    return Account(
      id: id,
      name: json['name'] as String,
      initialBalance: (json['initialBalance'] as num).toDouble(),
    );
  }
}
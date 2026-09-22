enum UserRole { employee, admin }

class Employee {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Employee.fromMap(String id, Map<String, dynamic> map) {
    return Employee(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: (map['role'] as String?) == 'admin' ? UserRole.admin : UserRole.employee,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role == UserRole.admin ? 'admin' : 'employee',
      };

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get roleLabel => role == UserRole.admin ? 'Admin' : 'Employee';
}

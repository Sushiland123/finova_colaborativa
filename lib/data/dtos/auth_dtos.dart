class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthTokensDto {
  final String accessToken;
  final String refreshToken;

  AuthTokensDto({required this.accessToken, required this.refreshToken});

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) => AuthTokensDto(
        accessToken: json['accessToken'] ?? json['access_token'] ?? '',
        refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      );
}

class UserDto {
  final String id;
  final String email;

  UserDto({required this.id, required this.email});

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
      );
}

class LoginResponseDto {
  final AuthTokensDto tokens;
  final UserDto? user;

  LoginResponseDto({required this.tokens, this.user});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    // El backend devuelve: { user: {...}, accessToken: "...", refreshToken: "...", tokenType: "...", expiresIn: "..." }
    // Extraemos tokens del nivel raíz
    final tokens = AuthTokensDto(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
    
    UserDto? user;
    final u = json['user'];
    if (u is Map<String, dynamic>) {
      user = UserDto.fromJson(u);
    }
    
    return LoginResponseDto(tokens: tokens, user: user);
  }
}

class RegisterRequestDto {
  final String nombre;
  final String email;
  final String password;

  RegisterRequestDto({
    required this.nombre,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    // Dividir el nombre en firstName y lastName para el backend
    final nameParts = nombre.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 
        ? nameParts.sublist(1).join(' ') 
        : nameParts.first; // Si solo hay un nombre, usarlo también como lastName

    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      // NO incluir 'nombre' ni 'rol' según el error del backend
    };
  }
}

class RegisterResponseDto {
  final String message;
  final UserRegisteredDto? user;

  RegisterResponseDto({required this.message, this.user});

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    UserRegisteredDto? user;
    final u = json['user'];
    if (u is Map<String, dynamic>) {
      user = UserRegisteredDto.fromJson(u);
    }
    
    return RegisterResponseDto(
      message: json['message'] ?? 'Usuario registrado',
      user: user,
    );
  }
}

class UserRegisteredDto {
  final dynamic id; // Puede ser int o String dependiendo del backend
  final String firstName;
  final String lastName;
  final String email;
  final String? rol;

  UserRegisteredDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.rol,
  });

  factory UserRegisteredDto.fromJson(Map<String, dynamic> json) =>
      UserRegisteredDto(
        id: json['id'] ?? 0,
        firstName: json['firstName'] ?? json['nombre'] ?? '', // Aceptar ambos formatos
        lastName: json['lastName'] ?? '',
        email: json['email'] ?? '',
        rol: json['rol'],
      );
  
  // Obtener nombre completo
  String get fullName => '$firstName $lastName'.trim();
}

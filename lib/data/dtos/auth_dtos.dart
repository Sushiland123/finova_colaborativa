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

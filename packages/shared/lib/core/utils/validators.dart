class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'メールアドレスを入力してください';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'メールアドレスの形式が正しくありません';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'パスワードを入力してください';
    if (value.length < 8) return 'パスワードは8文字以上で入力してください';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'ユーザー名を入力してください';
    if (value.length < 2) return 'ユーザー名は2文字以上で入力してください';
    if (value.length > 50) return 'ユーザー名は50文字以内で入力してください';
    return null;
  }
}

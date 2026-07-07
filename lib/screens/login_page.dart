import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'daftar_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscure = true;
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan username dan password')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://ahmad2711.rf.gd/api/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success']) {
        // Simpan user_id
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user']['id']);
        await prefs.setString('user_name', data['user']['nama']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A85F1), Color(0xFF8FD3F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 768;
                  return Container(
                    width: isMobile ? double.infinity : 900,
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 900,
                      maxHeight: isMobile ? double.infinity : 560,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: isMobile
                        ? SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildLoginPanel(context, isMobile),
                                _buildRegisterPanel(context, isMobile),
                              ],
                            ),
                          )
                        : Row(
                            children: [

                    /// ================= LEFT PANEL (LOGIN) =================
                    Expanded(
                      child: _buildLoginPanel(context, false),
                    ),

                    /// ================= RIGHT PANEL =================
                    _buildRegisterPanel(context, false),
                  ],
                ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Welcome 👋",
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 24 : 34,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Silakan login untuk melanjutkan",
              style: GoogleFonts.poppins(
                  color: Colors.grey[600])),

          const SizedBox(height: 35),

          _inputField(
            icon: Icons.person_outline,
            hint: "Username",
            controller: _usernameController,
            action: TextInputAction.next,
          ),

          const SizedBox(height: 20),

          _inputField(
            icon: Icons.lock_outline,
            hint: "Password",
            controller: _passwordController,
            isPassword: true,
            action: TextInputAction.done,
            submit: _login,
          ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text("Lupa password?"),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                elevation: 8,
                backgroundColor: const Color(0xFF6A85F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text("Login",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPanel(BuildContext context, bool isMobile) {
    final beginAlignment =
        isMobile ? Alignment.centerLeft : Alignment.topCenter;
    final endAlignment =
        isMobile ? Alignment.centerRight : Alignment.bottomCenter;

    return Container(
      width: isMobile ? double.infinity : 360,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF6A85F1), Color(0xFF8FD3F4)],
          begin: beginAlignment,
          end: endAlignment,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(isMobile ? 0 : 28),
          bottomRight: Radius.circular(isMobile ? 0 : 28),
          topLeft: Radius.circular(isMobile ? 28 : 0),
          bottomLeft: Radius.circular(isMobile ? 28 : 0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello, Bro ✨",
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            "Belum punya akun? Daftar sekarang dan mulai perjalananmu 🚀",
            style: GoogleFonts.poppins(
                color: Colors.white70, height: 1.6),
          ),

          const SizedBox(height: 35),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DaftarPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("Daftar Sekarang",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required IconData icon,
    required String hint,
    TextEditingController? controller,
    bool isPassword = false,
    TextInputAction action = TextInputAction.next,
    VoidCallback? submit,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscure : false,
      textInputAction: action,
      onSubmitted: (_) => submit?.call(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF4F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
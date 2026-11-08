import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/auth_state.dart';
import '../cubits/auth_cubit.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acesso ao Sistema"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white
      ),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.erro),
                  backgroundColor: Colors.red,
                )
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder()
                  ),
                ),

                const SizedBox(height: 16),

                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14)
                          ),
                          onPressed: () {
                            context.read<AuthCubit>().realizarLogin(
                              _emailController.text, 
                              _senhaController.text
                            );
                          }, 
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white
                            )
                          )
                        ),

                        const SizedBox(height: 16),

                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)
                          ),
                          onPressed: () {
                            context.read<AuthCubit>().realizarCadastro(
                              _emailController.text, 
                              _senhaController.text
                            );
                          },
                          child: const Text('Criar nova conta')
                        )
                      ],
                    );
                  }
                )
              ],
            ),
          ),
        )
      ),
    );
  }

}
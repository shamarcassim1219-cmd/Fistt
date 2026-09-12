with open('lib/screens/login_screen.dart', 'r') as f:
    content = f.read()

old_block = '''                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _googleLoading ? null : _handleGoogleSignIn,
                            icon: _googleLoading
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            label: const Text('Google', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _comingSoon('Apple'),
                            icon: const Icon(Icons.apple, color: Colors.white, size: 20),
                            label: const Text('Apple', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),'''

new_block = '''                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _handleGoogleSignIn,
                        icon: _googleLoading
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                      ),
                    ),'''

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('lib/screens/login_screen.dart', 'w') as f:
        f.write(content)
    print("REPLACED OK")
else:
    print("NOT FOUND - need manual check")

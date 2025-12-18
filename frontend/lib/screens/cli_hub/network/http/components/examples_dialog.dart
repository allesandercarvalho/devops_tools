import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamplesDialog extends StatelessWidget {
  final Function(Map<String, dynamic>) onSelectExample;

  const ExamplesDialog({super.key, required this.onSelectExample});

  static final List<Map<String, dynamic>> examples = [
    {
      'name': 'GET - Simple Request',
      'description': 'Buscar dados de uma API pública',
      'method': 'GET',
      'url': 'https://jsonplaceholder.typicode.com/posts/1',
      'headers': {},
      'params': {},
      'body': '',
    },
    {
      'name': 'GET - With Query Params',
      'description': 'Buscar repositórios do GitHub',
      'method': 'GET',
      'url': 'https://api.github.com/search/repositories',
      'headers': {'Accept': 'application/vnd.github.v3+json'},
      'params': {'q': 'javascript', 'sort': 'stars'},
      'body': '',
    },
    {
      'name': 'POST - JSON Data',
      'description': 'Criar um novo post',
      'method': 'POST',
      'url': 'https://jsonplaceholder.typicode.com/posts',
      'headers': {'Content-Type': 'application/json'},
      'params': {},
      'body': '{\n  "title": "My Post",\n  "body": "This is the content",\n  "userId": 1\n}',
    },
    {
      'name': 'POST - Login Example',
      'description': 'Exemplo de autenticação',
      'method': 'POST',
      'url': 'https://reqres.in/api/login',
      'headers': {'Content-Type': 'application/json'},
      'params': {},
      'body': '{\n  "email": "eve.holt@reqres.in",\n  "password": "cityslicka"\n}',
    },
    {
      'name': 'GET - With Bearer Token',
      'description': 'Requisição autenticada com token',
      'method': 'GET',
      'url': 'https://api.github.com/user',
      'headers': {'Authorization': 'Bearer YOUR_TOKEN_HERE'},
      'params': {},
      'body': '',
    },
    {
      'name': 'PUT - Update Resource',
      'description': 'Atualizar dados existentes',
      'method': 'PUT',
      'url': 'https://jsonplaceholder.typicode.com/posts/1',
      'headers': {'Content-Type': 'application/json'},
      'params': {},
      'body': '{\n  "id": 1,\n  "title": "Updated Title",\n  "body": "Updated content",\n  "userId": 1\n}',
    },
    {
      'name': 'DELETE - Remove Resource',
      'description': 'Deletar um recurso',
      'method': 'DELETE',
      'url': 'https://jsonplaceholder.typicode.com/posts/1',
      'headers': {},
      'params': {},
      'body': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1e293b),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFf59e0b), size: 28),
                const SizedBox(width: 12),
                Text('Request Examples', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Escolha um exemplo pronto para começar rapidamente', style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  final example = examples[index];
                  return _buildExampleCard(context, example);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(BuildContext context, Map<String, dynamic> example) {
    return InkWell(
      onTap: () {
        onSelectExample(example);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0f172a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMethodColor(example['method']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(example['method'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _getMethodColor(example['method']))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(example['name'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                const Icon(Icons.arrow_forward, color: Colors.white30, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(example['description'], style: GoogleFonts.inter(fontSize: 13, color: Colors.white60)),
            const SizedBox(height: 8),
            Text(example['url'], style: GoogleFonts.jetBrainsMono(fontSize: 11, color: const Color(0xFF3b82f6)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET': return const Color(0xFF3b82f6);
      case 'POST': return const Color(0xFF10b981);
      case 'PUT': return const Color(0xFFf59e0b);
      case 'PATCH': return const Color(0xFF8b5cf6);
      case 'DELETE': return const Color(0xFFef4444);
      default: return Colors.grey;
    }
  }
}

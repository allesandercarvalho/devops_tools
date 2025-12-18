import 'package:flutter/material.dart';

class TooltipHelper {
  static const Map<String, String> tooltips = {
    // Methods
    'GET': '📖 Busca dados do servidor sem modificar nada',
    'POST': '➕ Envia dados para criar algo novo no servidor',
    'PUT': '✏️ Atualiza dados existentes completamente',
    'PATCH': '🔧 Atualiza apenas partes específicas dos dados',
    'DELETE': '🗑️ Remove dados do servidor',
    
    // Headers
    'Content-Type': '📝 Informa o formato dos dados que você está enviando (ex: JSON, XML)',
    'Accept': '📥 Informa quais formatos de resposta você aceita receber',
    'Authorization': '🔐 Credenciais para autenticar sua requisição',
    'User-Agent': '🌐 Identifica qual aplicação está fazendo a requisição',
    'Cache-Control': '💾 Controla como o navegador deve armazenar em cache',
    
    // Status Codes
    '200': '✅ Sucesso! O servidor processou sua requisição corretamente',
    '201': '✅ Criado! Novo recurso foi criado com sucesso',
    '204': '✅ Sucesso sem conteúdo! Operação concluída, mas sem dados para retornar',
    '400': '❌ Requisição inválida. Verifique os dados enviados',
    '401': '🔒 Não autenticado. Você precisa fazer login ou fornecer credenciais',
    '403': '⛔ Proibido. Você não tem permissão para acessar este recurso',
    '404': '🔍 Não encontrado. Verifique se a URL está correta',
    '500': '💥 Erro no servidor. O problema está do lado do servidor',
    
    // Auth Types
    'none': 'Sem autenticação necessária',
    'basic': '🔑 Usuário e senha codificados em Base64',
    'bearer': '🎫 Token de autenticação (geralmente JWT)',
    'apikey': '🔐 Chave de API única para identificar sua aplicação',
  };

  static String get(String key) {
    return tooltips[key] ?? '';
  }

  static Widget wrap(String key, Widget child) {
    final tooltip = get(key);
    if (tooltip.isEmpty) return child;
    
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 20,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3b82f6)),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
      child: child,
    );
  }
}

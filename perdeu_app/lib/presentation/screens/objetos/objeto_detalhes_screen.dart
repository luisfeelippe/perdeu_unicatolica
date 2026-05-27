import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/requerimento_model.dart';

class ObjetoDetalhesScreen extends StatelessWidget {
  const ObjetoDetalhesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recebendo o objeto via DTO (Exigência da arquitetura)
    final requerimento = ModalRoute.of(context)!.settings.arguments as RequerimentoModel;
    final primaryOrange = const Color(0xFFFF6600);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem de destaque no topo
            Hero(
              tag: 'img_${requerimento.id}',
              child: requerimento.fotoUrl != null && requerimento.fotoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: requerimento.fotoUrl!,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria e Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        requerimento.categoria.toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: primaryOrange),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: requerimento.status.toUpperCase() == 'PERDIDO' ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          requerimento.status.toUpperCase(), 
                          style: TextStyle(
                            color: requerimento.status.toUpperCase() == 'PERDIDO' ? Colors.red.shade900 : Colors.green.shade900, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Título/Descrição Curta
                  Text(
                    requerimento.descricao,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  
                  // Informações de Local e Quem Achou
                  _buildInfoRow(Icons.location_on_outlined, 'Local', requerimento.localOcorrencia),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Data', '${requerimento.dataHoraOcorrencia.day}/${requerimento.dataHoraOcorrencia.month}/${requerimento.dataHoraOcorrencia.year}'),
                  const SizedBox(height: 16),
                  // Mock de quem registrou (Até o backend mandar o nome real)
                  _buildInfoRow(Icons.person_outline, 'Registrado por', 'Aluno UniCatólica (Anônimo)'),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  const Text('Detalhes adicionais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Objeto registrado no sistema. Caso você seja o proprietário, clique no botão abaixo para iniciar o processo de acareação e retirada junto ao setor responsável.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Botão Fixo no Rodapé
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () {
              // Aqui vai a lógica para criar um requerimento de "Achei" ou vincular os casos
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Solicitação Enviada'),
                  content: const Text('O administrador foi notificado. Acompanhe o status na aba Atualizações.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Esse objeto é meu!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.grey.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
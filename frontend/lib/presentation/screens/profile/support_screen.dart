import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/support_provider.dart';
import '../../providers/auth_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Open Support Ticket',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: _subjectController,
                style: const TextStyle(color: AppColors.textDark),
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textDark),
                decoration:
                    const InputDecoration(labelText: 'How can we help?'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        final user = ref.read(authStateProvider).value;
                        if (user != null) {
                          await ref
                              .read(supportRepositoryProvider)
                              .createTicket(
                                user.id,
                                _subjectController.text,
                                _messageController.text,
                              );
                          if (!mounted) return;
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Ticket created successfully!'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        }
                        setState(() => _isSubmitting = false);
                      },
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SUBMIT TICKET'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HELP & SUPPORT')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFaqSection(),
                  const SizedBox(height: 48),
                  const Text('My Tickets',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          ticketsAsync.when(
            data: (tickets) => tickets.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('No active tickets.')))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTicketCard(tickets[index]),
                      childCount: tickets.length,
                    ),
                  ),
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (err, _) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketSheet,
        label: const Text('NEW TICKET'),
        icon: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick FAQ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _buildFaqItem('How do I verify my account?',
            'You can upload your ID in the Profile section for manual verification by the admin.'),
        _buildFaqItem('Is my data safe?',
            'Yes, LocalSync uses industry-standard encryption and Firebase security rules to protect your data.'),
        _buildFaqItem('How to report an issue?',
            'Go to the Complaints section to raise a ticket for local infrastructure or security issues.'),
      ],
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [Padding(padding: const EdgeInsets.all(16), child: Text(a))],
    );
  }

  Widget _buildTicketCard(dynamic ticket) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticket.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
              _buildStatusBadge(ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(ticket.message,
              style: const TextStyle(color: AppColors.textGray)),
          const SizedBox(height: 16),
          Text(DateFormat('MMM dd, yyyy').format(ticket.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Open' ? Colors.blue : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

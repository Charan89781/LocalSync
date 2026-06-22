import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../common_widgets/app_bottom_nav.dart';
import '../../../core/services/gemini_service.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Widget _glassContainer({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 50),
              AppBar(
                title: const Text('ADMIN CONSOLE',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatGrid(),
                    const SizedBox(height: 40),
                    const Text('Management Tools',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 20),
                    _buildAdminTool(
                        context,
                        Icons.verified_user_rounded,
                        'Verify Residents',
                        'Review 12 pending requests',
                        AppColors.neonCyan,
                        '/admin/verify-requests'),
                    _buildAdminTool(context, Icons.report_problem_rounded,
                        'Review Complaints', '4 critical issues reported', Colors.redAccent),
                    _buildAdminTool(context, Icons.announcement_rounded,
                        'Broadcast Notice', 'Send official updates', Colors.orangeAccent),
                    _buildAdminTool(context, Icons.analytics_rounded,
                        'System Analytics', 'View community growth', Colors.greenAccent),
                    const SizedBox(height: 40),
                    const _AIHealthDashboard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
            'Total Users', '1,240', Icons.people_rounded, AppColors.neonCyan),
        _buildStatCard('Active SOS', '2', Icons.warning_rounded, Colors.redAccent),
        _buildStatCard(
            'Items Listed', '428', Icons.shopping_bag_rounded, Colors.greenAccent),
        _buildStatCard(
            'Avg Response', '4m', Icons.timer_rounded, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      child: _glassContainer(
        padding: 16,
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTool(BuildContext context, IconData icon, String title,
      String sub, Color color,
      [String? route]) {
    return GestureDetector(
      onTap: route != null ? () => context.push(route) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: _glassContainer(
          padding: 16,
          borderRadius: 20,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.25), width: 1)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AIHealthDashboard extends StatefulWidget {
  const _AIHealthDashboard();

  @override
  State<_AIHealthDashboard> createState() => _AIHealthDashboardState();
}

class _AIHealthDashboardState extends State<_AIHealthDashboard> {
  bool _isRunningDiagnostic = false;
  bool _showErrorLogs = false;

  @override
  void initState() {
    super.initState();
    GeminiService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    GeminiService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostic = true;
    });
    try {
      await GeminiService.instance.runConnectivityTest();
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDiagnostic = false;
        });
      }
    }
  }

  Widget _glassCard({required Widget child, double padding = 16, double borderRadius = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = GeminiService.instance;
    final isConnected = service.isConnected;
    final statusColor = isConnected ? Colors.greenAccent : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Health Console',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            GestureDetector(
              onTap: _isRunningDiagnostic ? null : _runDiagnostics,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRunningDiagnostic)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                        ),
                      )
                    else
                      const Icon(Icons.sync_rounded, size: 14, color: AppColors.neonCyan),
                    const SizedBox(width: 6),
                    Text(
                      _isRunningDiagnostic ? 'Testing...' : 'Test Connection',
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status Header
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gemini API Gateway',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Status: ${service.healthStatus}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isConnected ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.white12, height: 1),
              ),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Total', '${service.totalRequests}', Colors.white70),
                  _buildStatItem('Success', '${service.successfulRequests}', Colors.greenAccent),
                  _buildStatItem('Failed', '${service.failedRequests}', Colors.redAccent),
                  _buildStatItem('Latency', '${service.averageResponseTime.toStringAsFixed(0)}ms', AppColors.neonCyan),
                ],
              ),
              
              // Error Logs Toggle & Viewer
              if (service.errorLogs.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showErrorLogs = !_showErrorLogs;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Error Logs (${service.errorLogs.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      Icon(
                        _showErrorLogs ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (_showErrorLogs) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        service.errorLogs.join('\n'),
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: Colors.redAccent.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

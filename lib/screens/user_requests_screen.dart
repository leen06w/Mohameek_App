import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/request_item.dart';
import '../services/requests_service.dart';

class UserRequestsScreen extends StatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen> {
  final _requestsService = RequestsService();

  List<RequestItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final items = await _requestsService.fetchRequests();

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.userDashboard,
        (route) => false,
      );
    }
  }

  void _openDetails(RequestItem request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailsSheet(request: request),
    );
  }

  void _goToPayment(RequestItem request) {
    Navigator.pushNamed(
      context,
      AppRoutes.userPayment,
      arguments: request,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      scrollable: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'طلباتي',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Text(
              'تتبع حالة طلباتك وقم بإكمال عملية الدفع للطلبات المقبولة',
              style: TextStyle(
                color: AppColors.foreground.withValues(alpha: 0.62),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_items.isEmpty)
              const EmptyState(
                icon: Icons.inbox_outlined,
                message: 'لا توجد طلبات حالياً',
              )
            else
              ..._items.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    request.lawyerName,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    request.lawyerSpecialty,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.foreground
                                          .withValues(alpha: 0.62),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _statusChip(request.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _miniRow('نوع القضية', request.caseType),
                              _miniRow(
                                'نوع الاستشارة',
                                request.consultationType,
                              ),
                              _miniRow(
                                'الموعد المطلوب',
                                '${request.preferredDate} - ${request.preferredTime}',
                              ),
                              if (request.price != null)
                                _miniRow(
                                  'الرسوم',
                                  '${request.price} ر.س',
                                  highlight: true,
                                ),
                              if ((request.decisionAt ?? '').isNotEmpty)
                                _miniRow(
                                  'تاريخ القرار',
                                  request.decisionAt!,
                                ),
                            ],
                          ),
                        ),
                        if (request.negotiationNote != null &&
                            request.negotiationNote!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              request.negotiationNote!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(height: 1.6),
                            ),
                          ),
                        ],
                        if (request.rejectionReason != null &&
                            request.rejectionReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'سبب الرفض',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.destructive,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  request.rejectionReason!,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: 'التفاصيل',
                                onPressed: () => _openDetails(request),
                              ),
                            ),
                            if (request.status == 'accepted' ||
                                request.status == 'negotiating') ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: PrimaryButton(
                                  text: 'الدفع',
                                  onPressed: () => _goToPayment(request),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    switch (status) {
      case 'pending':
        return const InfoChip(
          label: 'قيد الانتظار',
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFC2410C),
          icon: Icons.schedule,
        );
      case 'accepted':
        return const InfoChip(
          label: 'مقبول',
          background: Color(0xFFEAF8EE),
          foreground: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'rejected':
        return const InfoChip(
          label: 'مرفوض',
          background: Color(0xFFFEE2E2),
          foreground: AppColors.destructive,
          icon: Icons.cancel,
        );
      case 'negotiating':
        return const InfoChip(
          label: 'قيد التفاوض',
          background: Color(0xFFEFF6FF),
          foreground: AppColors.primary,
          icon: Icons.gavel,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _miniRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  final RequestItem request;

  const _RequestDetailsSheet({required this.request});

  String _statusLabel() {
    switch (request.status) {
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'negotiating':
        return 'قيد التفاوض';
      default:
        return 'قيد الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: SizedBox(
                width: 50,
                child: Divider(thickness: 4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              request.lawyerName,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              textAlign: TextAlign.right,
              style: const TextStyle(height: 1.7),
            ),
            const SizedBox(height: 16),
            Text(
              'نوع القضية: ${request.caseType}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'نوع الاستشارة: ${request.consultationType}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'الحالة: ${_statusLabel()}',
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              'تم الإرسال: ${request.submittedAt}',
              textAlign: TextAlign.right,
            ),
            if ((request.decisionAt ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'تاريخ القرار: ${request.decisionAt}',
                textAlign: TextAlign.right,
              ),
            ],
            if (request.price != null) ...[
              const SizedBox(height: 8),
              Text(
                'الرسوم: ${request.price} ر.س',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
            if (request.negotiationNote != null &&
                request.negotiationNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request.negotiationNote!,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (request.rejectionReason != null &&
                request.rejectionReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'سبب الرفض:\n${request.rejectionReason!}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'إغلاق',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
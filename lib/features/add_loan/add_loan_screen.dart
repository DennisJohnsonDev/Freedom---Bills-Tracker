import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/colors.dart';
import '../../core/format.dart';
import '../../core/haptics.dart';
import '../../data/models/loan.dart';
import '../../providers/loan_providers.dart';
import '../../shared/widgets/primary_button.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  const AddLoanScreen({super.key, this.existing});
  final Loan? existing;

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lender;
  late final TextEditingController _emi;
  late final TextEditingController _total;
  late final TextEditingController _paid;
  late final TextEditingController _notes;
  late DateTime _firstDue;
  late int _accent;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _lender = TextEditingController(text: e?.lender ?? '');
    _emi = TextEditingController(
        text: e == null ? '' : e.emiAmount.toStringAsFixed(0));
    _total =
        TextEditingController(text: e == null ? '' : e.totalEmis.toString());
    _paid =
        TextEditingController(text: e == null ? '0' : e.emisPaid.toString());
    _notes = TextEditingController(text: e?.notes ?? '');
    _firstDue = e?.firstDueDate ?? _defaultFirstDue();
    _accent = e?.accentIndex ?? 0;
  }

  DateTime _defaultFirstDue() {
    final n = DateTime.now();
    return DateTime(n.year, n.month + 1, 5);
  }

  @override
  void dispose() {
    _lender.dispose();
    _emi.dispose();
    _total.dispose();
    _paid.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    Haptics.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDue,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 30),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: AppColors.accentInk,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _firstDue = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      Haptics.medium();
      return;
    }
    final repo = ref.read(loanRepositoryProvider);
    final lender = _lender.text.trim();
    final emi = double.parse(_emi.text);
    final total = int.parse(_total.text);
    final paid =
        int.tryParse(_paid.text.trim().isEmpty ? '0' : _paid.text) ?? 0;
    final notes = _notes.text.trim();

    if (widget.existing == null) {
      await repo.create(
        lender: lender,
        emiAmount: emi,
        totalEmis: total,
        emisPaid: paid.clamp(0, total),
        firstDueDate: _firstDue,
        notes: notes.isEmpty ? null : notes,
        accentIndex: _accent,
      );
    } else {
      await repo.update(widget.existing!.copyWith(
        lender: lender,
        emiAmount: emi,
        totalEmis: total,
        emisPaid: paid.clamp(0, total),
        firstDueDate: _firstDue,
        notes: notes.isEmpty ? null : notes,
        accentIndex: _accent,
      ));
    }
    Haptics.success();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(editing ? 'Edit loan' : 'New loan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
            physics: const BouncingScrollPhysics(),
            children: [
              _Label('Lender'),
              TextFormField(
                controller: _lender,
                style: t.bodyLarge,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. HDFC, Hero Fincorp, CRED',
                  prefixIcon: Icon(LucideIcons.landmark, size: 18),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Add a name'
                    : null,
              ),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('EMI amount'),
                        TextFormField(
                          controller: _emi,
                          style: t.bodyLarge,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: '₹  ',
                          ),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Add amount';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Total EMIs'),
                        TextFormField(
                          controller: _total,
                          style: t.bodyLarge,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'months',
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Add tenure';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(20),
              _Label('First payment date'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar,
                          size: 18, color: AppColors.textSecondary),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          Dates.dayLong(_firstDue),
                          style: t.bodyLarge,
                        ),
                      ),
                      Text(
                        Dates.relative(_firstDue),
                        style: t.bodySmall
                            ?.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),
              _Label('EMIs already paid (optional)'),
              TextFormField(
                controller: _paid,
                style: t.bodyLarge,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(LucideIcons.circleCheck, size: 18),
                ),
              ),
              const Gap(20),
              _Label('Accent'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.loanAccents.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) {
                    final c = AppColors.loanAccents[i];
                    final selected = i == _accent;
                    return GestureDetector(
                      onTap: () {
                        Haptics.selection();
                        setState(() => _accent = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? c
                                : c.withValues(alpha: 0.25),
                            width: selected ? 1.5 : 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: selected
                            ? Icon(LucideIcons.check, size: 18, color: c)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const Gap(20),
              _Label('Notes (optional)'),
              TextFormField(
                controller: _notes,
                style: t.bodyLarge,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'A note for future-you',
                ),
              ),
              const Gap(28),
              PrimaryButton(
                label: editing ? 'Save changes' : 'Save loan',
                icon: LucideIcons.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: t.labelSmall?.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_bootstrap.dart';
import '../../core/services/app_services.dart';
import '../../core/services/backup_service.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';

/// Hồ sơ → Sao lưu & khôi phục: xuất/nhập file `.mkbackup` (JSON), không cloud.
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;
  String? _status;
  bool _statusIsError = false;

  BackupService _service(AppServices services) => BackupService(
    database: services.database,
    prefs: services.prefs,
    notifications: services.notifications,
  );

  void _setStatus(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _status = message;
      _statusIsError = error;
    });
  }

  Future<void> _export() async {
    if (_busy) return;
    final AppServices services = context.read<AppServices>();
    final BackupService backup = _service(services);
    setState(() => _busy = true);
    try {
      final String json = await backup.exportJson();
      final Uint8List bytes = Uint8List.fromList(utf8.encode(json));
      final BackupPreview summary = backup.parse(json);
      final Uri? saved = await FilePicker.saveFile(
        dialogTitle: 'Lưu file sao lưu',
        fileName: backup.suggestedFileName(),
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );
      if (saved == null) {
        _setStatus('Đã huỷ, chưa lưu file sao lưu.');
      } else {
        _setStatus(
          'Đã xuất ${summary.totalRows} dòng dữ liệu '
          '(${_formatSize(bytes.length)}).\n'
          'File: ${backup.suggestedFileName()} (ở vị trí bạn vừa chọn).',
        );
      }
    } on BackupException catch (e) {
      _setStatus(e.message, error: true);
    } catch (e) {
      _setStatus('Xuất sao lưu thất bại: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy) return;
    final AppServices services = context.read<AppServices>();
    final BackupService backup = _service(services);
    setState(() => _busy = true);
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        dialogTitle: 'Chọn file sao lưu (.mkbackup)',
      );
      if (files.isEmpty) {
        _setStatus('Đã huỷ, chưa chọn file nào.');
        return;
      }
      final PlatformFile picked = files.single;
      final String raw;
      try {
        raw = utf8.decode(await picked.readAsBytes());
      } catch (e) {
        throw BackupException('Không đọc được file đã chọn: $e');
      }
      final BackupPreview preview = backup.parse(raw);
      if (!mounted) return;
      final bool ok = await showAppConfirmDialog(
        context,
        title: 'Thay thế toàn bộ dữ liệu hiện tại?',
        message:
            'File "${picked.name}" tạo lúc ${_formatDate(preview.header.exportedAt)} '
            'gồm ${preview.totalRows} dòng dữ liệu.\n\n'
            'Toàn bộ chủ đề, kiến thức, thẻ ôn, lịch ôn và cài đặt hiện tại sẽ bị '
            'thay bằng nội dung file. Ứng dụng tự lưu một bản sao lưu an toàn của '
            'dữ liệu hiện tại ngay trước khi ghi đè.',
        confirmLabel: 'Thay thế',
        destructive: true,
      );
      if (!ok || !mounted) {
        _setStatus('Đã huỷ khôi phục, dữ liệu không thay đổi.');
        return;
      }
      final Directory docs = await getApplicationDocumentsDirectory();
      final RestoreResult result = await backup.restore(
        preview,
        safetyDir: Directory(p.join(docs.path, 'backups')),
        rescheduleAll: _rescheduleAll,
      );
      AppBootstrap.instance.bumpDataVersion();
      final StringBuffer msg = StringBuffer(
        'Đã khôi phục ${result.counts.values.fold<int>(0, (int a, int b) => a + b)} '
        'dòng dữ liệu.\nBản sao lưu an toàn trước khi ghi đè:\n${result.safetyBackupPath}',
      );
      if (result.notificationsDisabled) {
        msg.write(
          '\n\nChưa có quyền thông báo nên các nhắc học đã được tắt. Bật quyền '
          'trong Cài đặt rồi bật lại ở "Cài đặt thông báo".',
        );
      }
      _setStatus(msg.toString());
    } on BackupException catch (e) {
      _setStatus(e.message, error: true);
    } catch (e) {
      _setStatus('Khôi phục thất bại: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rescheduleAll() async {
    final AppBootstrap boot = AppBootstrap.instance;
    if (!boot.isReady) return;
    await boot.refreshReminderSchedule();
    await boot.refreshKnowledgeReminderSchedule();
    await boot.refreshStudyPlan();
  }

  static String _formatSize(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(1)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

  static String _formatDate(DateTime t) {
    final DateTime l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu & khôi phục')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Sao lưu vào một file', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Xuất toàn bộ chủ đề, kiến thức, thẻ ôn + lịch FSRS, nhật ký ôn, '
                  'bài học, khóa học và cài đặt (nhắc học, mục tiêu ngày, kế hoạch '
                  'học, yêu thích, chế độ bài học, cấp độ mặc định) ra file '
                  '.mkbackup. Dữ liệu chỉ nằm trong file bạn tự lưu — không cloud, '
                  'không tài khoản.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'KHÔNG được sao lưu: khóa API và cấu hình AI, phiên ôn đang chạy, '
                  'lịch thông báo đã đặt (tự lập lại sau khi khôi phục) và file '
                  'media (ảnh/PDF gốc).',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Xuất file sao lưu',
                  icon: Icons.upload_file_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _export,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Khôi phục từ file', style: text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chọn file .mkbackup. Toàn bộ dữ liệu hiện tại sẽ bị thay thế; '
                  'trước khi ghi đè ứng dụng tự lưu một bản sao lưu an toàn. File '
                  'sai định dạng hoặc tạo bởi phiên bản mới hơn sẽ bị từ chối.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Chọn file để khôi phục',
                  icon: Icons.download_rounded,
                  variant: AppButtonVariant.tonal,
                  loading: _busy,
                  onPressed: _busy ? null : _import,
                ),
              ],
            ),
          ),
          if (_status != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              liveRegion: true,
              child: AppCard(
                child: Text(
                  _status!,
                  style: text.bodyMedium?.copyWith(
                    color: _statusIsError
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

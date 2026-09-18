import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/view/complain/complain_thread_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';

/// Daftar semua Complain milik user (aktif + selesai) — diakses dari
/// menu "Complain" di halaman Setting.
class ComplainListPage extends StatefulWidget {
  const ComplainListPage({super.key});

  @override
  State<ComplainListPage> createState() => _ComplainListPageState();
}

class _ComplainListPageState extends State<ComplainListPage> {
  @override
  void initState() {
    super.initState();
    // reset: buang daftar dari sesi sebelumnya supaya yang tampil pertama
    // adalah loading, bukan data lama yang lalu berganti sendiri.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _load(reset: true));
  }

  /// Selama false, halaman selalu menampilkan loading — mencegah frame
  /// pertama sempat merender daftar dari sesi sebelumnya.
  bool _hasLoaded = false;

  Future<void> _load({bool reset = false}) async {
    final userId = context.read<UserProvider>().customer?.noId;
    if (userId != null) {
      await context.read<ComplainProvider>().loadHeaders(userId, reset: reset);
    }
    if (mounted) setState(() => _hasLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: const Text('Complain',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: Consumer<ComplainProvider>(
            builder: (context, provider, _) {
              if (!_hasLoaded ||
                  (provider.isLoadingHeaders && provider.headers.isEmpty)) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.headersError != null && provider.headers.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(
                        provider.headersError!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              if (provider.headers.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Belum ada complain',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: provider.headers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ComplainHeaderCard(
                  header: provider.headers[i],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComplainHeaderCard extends StatelessWidget {
  final ComplainHeaderModel header;
  const _ComplainHeaderCard({required this.header});

  @override
  Widget build(BuildContext context) {
    final closed = header.isClosed;
    final color = closed ? Colors.green : Colors.orange;
    final date = header.lastUpdated ?? header.tglCreated;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ComplainThreadPage(
          noComplain: header.noComplain,
          noOrder: header.noOrder,
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    header.judul.isEmpty ? 'Complain' : header.judul,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    closed ? 'Selesai' : 'Aktif',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              header.noTrackingKomplain.isNotEmpty
                  ? header.noTrackingKomplain
                  : header.noComplain,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal()),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            if (header.prioritas.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Prioritas: ${header.prioritas}',
                  style:
                      TextStyle(fontSize: 10, color: Colors.blueGrey.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

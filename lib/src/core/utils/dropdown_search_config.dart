// lib/src/core/widgets/dropdown_search/dropdown_search_config.dart

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/models/kategori_model.dart';
import 'package:mpjnew/src/data/models/kota_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:provider/provider.dart';

/// Base class untuk konfigurasi dropdown search
abstract class DropdownSearchConfig<T> {
  /// Label yang ditampilkan di atas dropdown
  final String label;

  /// Pesan error jika ada
  final String? errorMessage;

  /// Durasi debounce dalam milliseconds
  final int debounceDuration;

  /// Apakah perlu fetch data dari server saat search
  final bool enableRemoteSearch;

  const DropdownSearchConfig({
    required this.label,
    this.errorMessage,
    this.debounceDuration = 500,
    this.enableRemoteSearch = false,
  });

  /// Mengubah model menjadi string untuk ditampilkan
  String getDisplayText(T item);

  /// Mendapatkan value/id dari model
  String getValue(T item);

  /// Filter data berdasarkan search query
  bool filterItem(T item, String query) {
    return getDisplayText(item).toLowerCase().contains(query.trim().toLowerCase());
  }

  /// Fetch data dari provider/repository
  Future<List<T>> fetchData(BuildContext context, String query);

  /// Get cached data dari provider (untuk filter lokal)
  List<T> getCachedData(BuildContext context);
}

/// Config untuk Kota
class KotaDropdownConfig extends DropdownSearchConfig<KotaModel> {
  const KotaDropdownConfig({
    super.label = 'Kota',
    super.errorMessage,
    super.debounceDuration = 500,
    super.enableRemoteSearch = true,
  });

  @override
  String getDisplayText(KotaModel item) =>
      Helper.capitalizeFirst(item.namaKota);

  @override
  String getValue(KotaModel item) => item.namaKota;

  @override
  Future<List<KotaModel>> fetchData(BuildContext context, String query) async {
    await context.read<KotaProvider>().getKotaName(name: query);
    return context.read<KotaProvider>().kotaList;
  }

  @override
  List<KotaModel> getCachedData(BuildContext context) {
    return context.watch<KotaProvider>().kotaList;
  }
}

/// Config untuk Kategori
class KategoriDropdownConfig extends DropdownSearchConfig<KategoriModel> {
  const KategoriDropdownConfig({
    super.label = 'Kategori',
    super.errorMessage,
    super.debounceDuration = 300,
    super.enableRemoteSearch = false,
  });

  @override
  String getDisplayText(KategoriModel item) => item.nama_kategori;

  @override
  String getValue(KategoriModel item) => item.nama_kategori;

  @override
  Future<List<KategoriModel>> fetchData(
      BuildContext context, String query) async {
    // Kategori tidak perlu remote search, langsung return cached data
    return getCachedData(context);
  }

  @override
  List<KategoriModel> getCachedData(BuildContext context) {
    return context.watch<KategoriProvider>().kategoriList;
  }
}

/// Config untuk Paket
class PaketDropdownConfig extends DropdownSearchConfig<PaketModel> {
  const PaketDropdownConfig({
    super.label = 'Paket',
    super.errorMessage,
    super.debounceDuration = 300,
    super.enableRemoteSearch = false,
  });

  @override
  String getDisplayText(PaketModel item) => item.nama_paket;

  @override
  String getValue(PaketModel item) => item.nama_paket;

  @override
  Future<List<PaketModel>> fetchData(BuildContext context, String query) async {
    return getCachedData(context);
  }

  @override
  List<PaketModel> getCachedData(BuildContext context) {
    return context.watch<PaketProvider>().paketList;
  }
}

class GenderDropdownConfig extends DropdownSearchConfig<String> {
  const GenderDropdownConfig({
    super.label = 'Gender',
    super.errorMessage,
    super.debounceDuration = 0,
    super.enableRemoteSearch = false,
  });

  static const List<String> _genders = [
    'male',
    'female',
  ];

  @override
  String getDisplayText(String item) => Helper.capitalizeFirst(item);

  @override
  String getValue(String item) => item;

  @override
  Future<List<String>> fetchData(BuildContext context, String query) async {
    return _genders;
  }

  @override
  List<String> getCachedData(BuildContext context) {
    return _genders;
  }
}

class ImageSourceDropdownConfig extends DropdownSearchConfig<String> {
  const ImageSourceDropdownConfig({
    super.label = 'Sumber Gambar',
    super.errorMessage,
    super.debounceDuration = 0,
    super.enableRemoteSearch = false,
  });

  static const List<String> _sources = [
    'camera',
    'gallery',
  ];

  @override
  String getDisplayText(String item) {
    switch (item) {
      case 'camera':
        return 'Kamera';
      case 'gallery':
        return 'Galeri';
      default:
        return item;
    }
  }

  @override
  String getValue(String item) => item;

  @override
  Future<List<String>> fetchData(BuildContext context, String query) async {
    return _sources;
  }

  @override
  List<String> getCachedData(BuildContext context) {
    return _sources;
  }
}

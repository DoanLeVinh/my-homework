import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final String apiUrl;
  const ProductDetailPage({super.key, required this.apiUrl});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Product> _futureProduct;

  @override
  void initState() {
    super.initState();
    _futureProduct = _fetchProduct();
  }

  Future<Product> _fetchProduct() async {
    final uri = Uri.parse(widget.apiUrl);
    final resp = await http.get(uri);

    if (resp.statusCode != 200) {
      throw Exception('Failed to load product (status ${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    print('🔹 JSON nhận được: $decoded');

    // JSON là object phẳng -> đọc trực tiếp
    if (decoded is Map<String, dynamic>) {
      return Product.fromJson(decoded);
    }

    throw Exception('Unsupported product JSON format');
  }

  String _formatPrice(double value) {
    final fmt = NumberFormat.decimalPattern('vi_VN');
    return '${fmt.format(value)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Product Detail',
          style: TextStyle(
            color: Color(0xFF00AEEF),
            fontWeight: FontWeight.w600,
          ),
        ),
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00AEEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final p = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: p.imgURL.isNotEmpty
                          ? Image.network(
                              p.imgURL,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 80),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, size: 80),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tên sản phẩm
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Giá
                  Text(
                    'Giá: ${_formatPrice(p.price)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mô tả
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.description.isNotEmpty ? p.description : 'Chưa có mô tả.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

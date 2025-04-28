import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/product_service.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  late MobileScannerController _scannerController;
  int _currentIndex = 0;
  Product? _scannedProduct;
  bool _isFlashOn = false;

  final List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Scan',
      backgroundColor: Color(0xFF2E7D32),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
      backgroundColor: Color(0xFF2E7D32),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Profile',
      backgroundColor: Color(0xFF2E7D32),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    WidgetsBinding.instance.addObserver(this);
    if (_currentIndex == 0) {
      _startCamera();
    }
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    print('Scanner controller initialized');
  }

  Future<void> _startCamera() async {
    try {
      await _scannerController.start();
      print('Camera started successfully');
    } catch (e) {
      print('Error starting camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting camera: $e')),
      );
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _scannerController.stop();
      print('Camera stopped successfully');
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AppLifecycleState changed: $state');
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _startCamera();
    } else if (state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    print('Scanner controller disposed');
    super.dispose();
  }

  Future<void> _fetchProductInfo(String barcode) async {
    print('Fetching product info for barcode: $barcode');
    setState(() => _isLoading = true);

    try {
      final product = await _productService.fetchProduct(barcode);

      if (product != null) {
        print('Product Data: Energy=${product.getEnergy()}, Sugars=${product.getSugar()}, '
            'Fat=${product.getFat()}, Salt=${product.getSalt()}, '
            'Ingredients=${product.ingredientsText}, Allergens=${product.allergens}, '
            'Quality Score=${product.getQualityPercentage().toStringAsFixed(1)}, '
            'Image URL=${product.imageUrl}');

        setState(() {
          _scannedProduct = product;
          print('Product set in state: ${product.productName}');
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .add({
            'productName': product.productName ?? 'Unknown Product',
            'brands': product.brands ?? 'N/A',
            'ingredientsText': product.ingredientsText ?? 'N/A',
            'allergens': product.allergens ?? 'N/A',
            'imageUrl': product.imageUrl ?? '',
            'nutriScore': product.nutriScore ?? 'N/A',
            'novaGroup': product.novaGroup ?? 'N/A',
            'ecoScore': product.ecoScore ?? 'N/A',
            'energy': product.getEnergy(),
            'fat': product.getFat(),
            'sugar': product.getSugar(),
            'salt': product.getSalt(),
            'protein': product.getProtein(),
            'qualityPercentage': product.getQualityPercentage(),
            'energyIndex': product.getEnergyIndex(),
            'nutritionalIndex': product.getNutritionalIndex(),
            'complianceIndex': product.getComplianceIndex(),
            'positiveAspects': product.getPositiveAspects(),
            'negativeAspects': product.getNegativeAspects(),
            'recommendations': product.getRecommendations(),
            'additives': product.getAdditives(),
            'overallAnalysis': product.analyze(),
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('Product saved to Firestore: ${product.productName}');
        }
      } else {
        print('Product not found for barcode: $barcode');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found for barcode: $barcode')),
        );
      }
    } catch (e) {
      print('Error fetching product info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
      print('Loading state reset');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildSnapchatBottomBar(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildScannerView();
      case 1:
        return _buildHistoryView();
      case 2:
        return _buildProfileView();
      default:
        return _buildScannerView();
    }
  }

  Widget _buildHistoryView() {
    _stopCamera();

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scans')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading history: ${snapshot.error}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No scan history available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
              ),
            );
          }

          final scans = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scanData = scans[index].data() as Map<String, dynamic>;
              final qualityPercentage = scanData['qualityPercentage'] as double? ?? 0.0;

              return GestureDetector(
                onTap: () {
                  final product = Product.fromFirestore(scanData);
                  Navigator.pushNamed(context, '/product', arguments: product);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        scanData['imageUrl'] != null && scanData['imageUrl'].isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  scanData['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Color(0xFF757575),
                              ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scanData['productName'] ?? 'Unknown Product',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Brand: ${scanData['brands'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              Text(
                                'Scanned: ${scanData['timestamp'] != null ? (scanData['timestamp'] as Timestamp).toDate().toString() : 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Score: ${qualityPercentage.toStringAsFixed(1)}/100',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(qualityPercentage),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      qualityPercentage >= 50 ? 'Good' : 'Bad',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Color(0xFFF44336)),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('scans')
                                .doc(scans[index].id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSnapchatBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _scannedProduct = null;
              _isFlashOn = false;
              _scannerController = MobileScannerController(
                facing: CameraFacing.back,
                torchEnabled: false,
              );
              _startCamera();
              print('Switched to Scan tab, camera restarted');
            } else {
              _stopCamera();
              print('Camera stopped due to tab switch to index: $index');
            }
          });
        },
        items: _bottomNavItems,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (!_isLoading) {
              print('Barcode detection triggered');
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String barcode = barcodes.first.rawValue ?? '';
                print('Barcode detected: $barcode');
                if (barcode.isNotEmpty) {
                  print('Processing barcode...');
                  _fetchProductInfo(barcode);
                } else {
                  print('Barcode value is empty');
                }
              } else {
                print('No barcodes detected in this frame');
              }
            } else {
              print('Scanner ignored detection because _isLoading is true');
            }
          },
          errorBuilder: (context, exception, child) {
            print('MobileScanner error: $exception');
            return Center(
              child: Text(
                'Error with scanner: $exception',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 40,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isFlashOn = !_isFlashOn;
                  _scannerController.toggleTorch();
                  print('Flashlight toggled: $_isFlashOn');
                });
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _scannedProduct == null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 70),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Point the camera at a barcode to scan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    print('Product card tapped, navigating to ProductDetailsScreen');
                    Navigator.pushNamed(
                      context,
                      '/product',
                      arguments: _scannedProduct,
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
                    margin: const EdgeInsets.only(bottom: 70, left: 16, right: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _scannedProduct!.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _scannedProduct!.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Color(0xFF757575),
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _scannedProduct!.productName ?? 'Unknown Product',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Color(0xFF757575)),
                                      onPressed: () {
                                        setState(() {
                                          _scannedProduct = null;
                                          _startCamera();
                                          print('Product card closed, camera restarted');
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Brand: ${_scannedProduct!.brands ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Score: ${_scannedProduct!.getQualityPercentage().toStringAsFixed(1)}/100',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(_scannedProduct!.getQualityPercentage()),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _scannedProduct!.getQualityPercentage() >= 50 ? 'Good' : 'Bad',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 0) return Color(0xFFF44336);
    if (score >= 100) return Color(0xFF4CAF50);
    final red = (255 * (100 - score) / 100).toInt();
    final green = (255 * score / 100).toInt();
    return Color.fromRGBO(red, green, 0, 1);
  }

  Widget _buildProfileView() {
    _stopCamera();

    final user = FirebaseAuth.instance.currentUser;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                shadowColor: Color(0xFF4CAF50).withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: ${user.email ?? 'Not available'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF44336),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Text(
                'Please log in',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
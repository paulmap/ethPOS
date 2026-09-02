import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../features/inventory/presentation/pages/inventory_home.dart';
import '../../../features/loyalty/presentation/pages/loyalty_home.dart';
import '../../../features/sales/presentation/pages/checkout_page.dart';
import '../../../features/suppliers/presentation/pages/supplier_home.dart';
import '../../../features/purchases/presentation/pages/purchase_home.dart';
import '../../../features/settings/presentation/pages/settings_page.dart';
import '../../../features/assistant/presentation/pages/assistant_chat_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('dd MMMM yyyy EEEE').format(now);
    
    // Brand Blue - matching the logo's deep blue
    const brandBlue = Color(0xFF1565C0); 

    return Scaffold(
      backgroundColor: brandBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 30),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ethPOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateString,
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Grid Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
                    crossAxisCount: 3,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75, // Decreased to increase card height and prevent overflow
                    children: [
                      _buildDashboardItem(
                        context, 
                        Icons.receipt_long_rounded, 
                        'Sales\nReceipting', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage())),
                      ),
                      _buildDashboardItem(
                        context, 
                        Icons.inventory_2_rounded, 
                        'Inventory', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryHome())),
                      ),
                      _buildDashboardItem(
                        context, 
                        Icons.people_alt_rounded, 
                        'Customers', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyHome())),
                      ),
                      _buildDashboardItem(
                        context, 
                        Icons.card_membership_rounded, 
                        'Loyalty\nProgram', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyHome())),
                      ),
                      _buildDashboardItem(
                        context, 
                        Icons.local_shipping_rounded, 
                        'Suppliers', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierHome())),
                      ),
                      _buildDashboardItem(
                        context, 
                        Icons.shopping_cart_rounded, 
                        'Purchases', 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseHome())),
                      ),
                      _buildDashboardItem(
                        context,
                        Icons.settings_suggest_rounded,
                        'Settings',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                      ),
                      _buildDashboardItem(
                        context,
                        Icons.smart_toy_rounded,
                        'AI\nAssistant',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssistantChatPage())),
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

  Widget _buildDashboardItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Raised Icon Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(38),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: Icon(
              icon, 
              color: const Color(0xFF1565C0), // Consistent brand blue for icons
              size: 32,
            ),
          ),
          const SizedBox(height: 6),
          // Flexible label to handle multi-line without overflow
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

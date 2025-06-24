import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../db/payment_helper.dart';
import '../db/bill_helper.dart';
import '../db/customer_helper.dart';
import '../models/payment.dart';
import '../models/bill.dart';
import '../models/customer.dart';
import 'dart:async';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double todaySales = 0;
  double monthlyProfit = 0;
  int billCount = 0;
  int customerCount = 0;
  bool _loading = true;
  List<Payment> _payments = [];
  List<Bill> _bills = [];
  List<double> _weeklySales = List.filled(7, 0);
  Map<String, double> _paymentTypeTotals = {};
  List<double> _monthlySales = List.filled(12, 0);
  List<Map<String, dynamic>> _topCustomers = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loading = true);
    final payments = await PaymentHelper.instance.getAllPayments();
    final bills = await BillHelper.instance.getAllBills();
    final customers = await DatabaseHelper.instance.getAllCustomers();
    final now = DateTime.now();
    double today = 0;
    double month = 0;
    List<double> weekly = List.filled(7, 0);
    Map<String, double> paymentTypeTotals = {};
    List<double> monthlySales = List.filled(12, 0);
    Map<int, double> customerTotals = {};
    
    for (final payment in payments) {
      final bill = bills.firstWhere(
        (b) => b.billingId == payment.billingId,
        orElse: () => Bill(billingId: 0, invoiceDate: null, deliveryDate: null, invoiceTime: '', deliveryTime: '', salesPerson: '', customerId: 0),
      );
      final date = bill.invoiceDate;
      if (date != null) {
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          today += payment.grandTotal;
        }
        if (date.year == now.year && date.month == now.month) {
          month += payment.grandTotal;
        }
        // Weekly sales (last 7 days)
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          weekly[6 - diff] += payment.grandTotal;
        }
        // Monthly sales (for line chart)
        if (date.year == now.year) {
          monthlySales[date.month - 1] += payment.grandTotal;
        }
        // Top customers
        if (bill.customerId != 0) {
          customerTotals[bill.customerId] = (customerTotals[bill.customerId] ?? 0) + payment.grandTotal;
        }
      }
      // Payment type pie
      paymentTypeTotals[payment.paymentType] = (paymentTypeTotals[payment.paymentType] ?? 0) + payment.grandTotal;
    }
    
    // Top 5 customers
    final topCustomers = customerTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCustomerList = topCustomers.take(5).map((e) {
      final customer = customers.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Customer(id: 0, name: 'Unknown', email: '', phoneNumber: '', address: '', createdAt: DateTime.now()),
      );
      return {
        'name': customer.name,
        'total': e.value,
      };
    }).toList();
    
    setState(() {
      todaySales = today;
      monthlyProfit = month;
      billCount = bills.length;
      customerCount = customers.length;
      _payments = payments;
      _bills = bills;
      _weeklySales = weekly;
      _paymentTypeTotals = paymentTypeTotals;
      _monthlySales = monthlySales;
      _topCustomers = topCustomerList;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive breakpoints
    final isExtraWide = screenWidth > 1600;
    final isWide = screenWidth > 1400;
    final isMedium = screenWidth > 1280;
    
    // Dynamic padding based on screen size
    final horizontalPadding = screenWidth * 0.02;
    final verticalPadding = screenHeight * 0.02;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding.clamp(16, 32),
                vertical: verticalPadding.clamp(16, 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: screenHeight * 0.02),
                  _buildStatCards(context, screenWidth),
                  SizedBox(height: screenHeight * 0.03),
                  _buildChartsSection(context, screenWidth, screenHeight, isExtraWide, isWide, isMedium),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Dashboard',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, double screenWidth) {
    // Responsive grid for stat cards
    if (screenWidth > 1400) {
      // 4 cards in a row for wide screens
      return Row(
        children: [
          Expanded(child: _buildStatCard(context, 'Today Sales', 'Rs. ${todaySales.toStringAsFixed(2)}', Icons.trending_up_rounded, Colors.green)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Monthly Profit', 'Rs. ${monthlyProfit.toStringAsFixed(2)}', Icons.pie_chart_rounded, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Bills', billCount.toString(), Icons.receipt_long_rounded, Colors.orange)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Customers', customerCount.toString(), Icons.people_rounded, Colors.purple)),
        ],
      );
    } else {
      // 2x2 grid for smaller screens
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Today Sales', 'Rs. ${todaySales.toStringAsFixed(2)}', Icons.trending_up_rounded, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(context, 'Monthly Profit', 'Rs. ${monthlyProfit.toStringAsFixed(2)}', Icons.pie_chart_rounded, Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Bills', billCount.toString(), Icons.receipt_long_rounded, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(context, 'Customers', customerCount.toString(), Icons.people_rounded, Colors.purple)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, double screenWidth, double screenHeight, bool isExtraWide, bool isWide, bool isMedium) {
    if (isExtraWide) {
      // 3-column layout for extra wide screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSalesChart(context, screenHeight * 0.25),
                SizedBox(height: screenHeight * 0.02),
                _buildMonthlyLineChart(context, screenHeight * 0.25),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildPaymentTypePie(context, screenHeight * 0.25),
                SizedBox(height: screenHeight * 0.02),
                _buildTopCustomersTable(context),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildRecentPaymentsTable(context),
          ),
        ],
      );
    } else if (isWide) {
      // 2-column layout for wide screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSalesChart(context, screenHeight * 0.3),
                SizedBox(height: screenHeight * 0.02),
                _buildMonthlyLineChart(context, screenHeight * 0.3),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildPaymentTypePie(context, screenHeight * 0.25),
                SizedBox(height: screenHeight * 0.02),
                _buildTopCustomersTable(context),
                SizedBox(height: screenHeight * 0.02),
                _buildRecentPaymentsTable(context),
              ],
            ),
          ),
        ],
      );
    } else {
      // Single column layout for smaller screens
      return Column(
        children: [
          _buildSalesChart(context, screenHeight * 0.25),
          SizedBox(height: screenHeight * 0.02),
          _buildMonthlyLineChart(context, screenHeight * 0.25),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              Expanded(child: _buildPaymentTypePie(context, screenHeight * 0.25)),
              const SizedBox(width: 16),
              Expanded(child: _buildTopCustomersTable(context)),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildRecentPaymentsTable(context),
        ],
      );
    }
  }

  Widget _buildSalesChart(BuildContext context, double height) {
    final weekDays = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return "${date.day}/${date.month}";
    });
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_weeklySales.reduce(max) * 1.2).clamp(100, double.infinity),
                  barTouchData: const BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              weekDays[idx],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _weeklySales[i],
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyLineChart(BuildContext context, double height) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Sales Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(12, (i) => FlSpot(i.toDouble(), _monthlySales[i])),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: (_monthlySales.reduce(max) * 1.2).clamp(100, double.infinity),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 11) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              months[idx],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypePie(BuildContext context, double height) {
    final total = _paymentTypeTotals.values.fold(0.0, (a, b) => a + b);
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height * 0.7,
              child: PieChart(
                PieChartData(
                  sections: _paymentTypeTotals.entries.map((e) {
                    final idx = _paymentTypeTotals.keys.toList().indexOf(e.key);
                    return PieChartSectionData(
                      color: colors[idx % colors.length],
                      value: e.value,
                      title: total > 0 ? "${((e.value / total) * 100).toStringAsFixed(1)}%" : '',
                      radius: 40,
                      titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _paymentTypeTotals.keys.map((type) {
                final idx = _paymentTypeTotals.keys.toList().indexOf(type);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[idx % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(type, style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersTable(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Customers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Total Spent')),
                ],
                rows: _topCustomers.map((c) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        c['name'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text('Rs. ${(c['total'] as double).toStringAsFixed(2)}'),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPaymentsTable(BuildContext context) {
    final recent = _payments.take(6).toList();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Payments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text('Bill ID')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Type')),
                ],
                rows: recent.map((p) => DataRow(
                  cells: [
                    DataCell(Text(p.billingId.toString())),
                    DataCell(Text('Rs. ${p.grandTotal.toStringAsFixed(2)}')),
                    DataCell(
                      Text(
                        p.paymentType,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
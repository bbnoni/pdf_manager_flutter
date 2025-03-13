import 'package:flutter/material.dart';

class CommissionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> commission;
  const CommissionDetailsScreen({super.key, required this.commission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commission Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Commission Earned: GH₵${commission['amount']}",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Date: ${commission['date']}",
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text("Commission Period: ${commission['commission_period']}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            _buildTransactionSection("Cash-In Transactions", [
              _buildRow(
                  "Transactions", commission['cashin_total_transactions']),
              _buildRow("Valid Transactions",
                  commission['cashin_total_number_valid']),
              _buildRow("Value", "GH₵${commission['cashin_total_value']}"),
              _buildRow("Valid Value",
                  "GH₵${commission['cashin_total_value_valid']}"),
              _buildRow("Tax", "GH₵${commission['cashin_total_tax_on_valid']}"),
              _buildRow(
                  "Payout", "GH₵${commission['cashin_payout_commission']}"),
            ]),
            _buildTransactionSection("Cash-Out Transactions", [
              _buildRow(
                  "Transactions", commission['cashout_total_transactions']),
              _buildRow("Valid Transactions",
                  commission['cashout_total_number_valid']),
              _buildRow("Value", "GH₵${commission['cashout_total_value']}"),
              _buildRow("Valid Value",
                  "GH₵${commission['cashout_total_value_valid']}"),
              _buildRow(
                  "Tax", "GH₵${commission['cashout_total_tax_on_valid']}"),
              _buildRow(
                  "Payout", "GH₵${commission['cashout_payout_commission']}"),
            ]),

            /// **Total Commissions Due**
            const SizedBox(height: 20),
            const Divider(thickness: 1.5),
            _buildRow(
              "Total Commissions Due",
              "GH₵${commission['total_commissions_due']}",
              isBold: true,
              color: Colors.green,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Divider(thickness: 1.5), Text(title), ...rows],
    );
  }

  Widget _buildRow(String label, dynamic value,
      {bool isBold = false, Color color = Colors.black, double fontSize = 14}) {
    return Text("$label: ${value ?? "N/A"}",
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color));
  }
}

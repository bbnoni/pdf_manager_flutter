import 'package:flutter/material.dart';

class CommissionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> commission;
  const CommissionDetailsScreen({super.key, required this.commission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commission Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Commission Earned: GH₵${commission['amount'] ?? 'N/A'}",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                "Commission Period: ${commission['commission_period'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.blue)),
            const SizedBox(height: 20),
            _sectionTitle("🪙 Cash-In Transactions"),
            _infoRow(
                "Direct Cash In Value", commission['direct_cash_in_value']),
            _infoRow("Above GHS 1000", commission['above_ghs_1000']),
            _infoRow("Number of Trxn Above GHS 1000",
                commission['num_of_trxn_above_ghs_1000']),
            _infoRow("Trxn Below GHS 1000", commission['trxn_below_ghs_1000']),
            _infoRow("Commission Above GHS 1000",
                commission['commission_above_ghs_1000']),
            _infoRow("Commission Below GHS 1000",
                commission['commission_below_ghs_1000']),
            _infoRow("Total Comm On Direct Cash In",
                commission['total_comm_on_direct_cash_in']),
            _infoRow("RAFM Total Comm Due Merchant",
                commission['rafm_total_comm_due_merchant']),
            _infoRow("Super Agent", commission['super_agent']),
            _infoRow("Super Agent 10%", commission['super_agent_10_percent']),
            _infoRow("Comm After Super Agent Deduction",
                commission['comm_due_merchant_after_super_agent_deduction']),
            _infoRow(
                "RAFM Withholding Tax", commission['rafm_withholding_tax']),
            _infoRow("RAFM Pay Out Commission",
                commission['rafm_pay_out_commission']),
            _infoRow("RAFM Commission >= GHS 1000",
                commission['rafm_commission_gte_ghs_1000']),
            _infoRow("RAFM Commission < GHS 1000",
                commission['rafm_commission_below_ghs_1000']),
            _infoRow("Commissions to Same Account Owner",
                commission['commissions_on_txns_to_same_account_owner']),
            _infoRow("RAFM Total Trxn Volume >= GHS 1000",
                commission['rafm_total_trxn_volume_gte_ghs_1000']),
            _infoRow("RAFM Total Split Trxn Volume >= GHS 1000",
                commission['rafm_total_split_trxn_volume_gte_ghs_1000']),
            _infoRow("RAFM Total Trxn Value >= GHS 1000",
                commission['rafm_total_trxn_value_gte_ghs_1000']),
            _infoRow("RAFM Total Split Trxn Value >= GHS 1000",
                commission['rafm_total_split_trxn_value_gte_ghs_1000']),
            _infoRow("RAFM Total Trxn Below GHS 1000",
                commission['rafm_total_trxn_below_ghs_1000']),
            _infoRow("RAFM Total Split Trxn Below GHS 1000",
                commission['rafm_total_split_trxn_below_ghs_1000']),
            const SizedBox(height: 20),
            _sectionTitle("💸 Cash-Out Transactions"),
            _infoRow("RAFM Trxn Volume", commission['rafm_trxn_volume']),
            _infoRow(
                "RAFM Trxn Value (Ghs)", commission['rafm_trxn_value_ghs']),
            _infoRow("RAFM Total Revenue", commission['rafm_total_revenue']),
            _infoRow("RAFM Total Commission On Trxns",
                commission['rafm_total_commission_on_trxns']),
            _infoRow("Commission Already Paid Out",
                commission['commission_already_paid_out']),
            _infoRow("RAFM Pay Out Commission",
                commission['rafm_pay_out_commission']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text("$label: ${value ?? 'N/A'}"),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1.5),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

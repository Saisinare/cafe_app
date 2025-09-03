import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/sales.dart';
import '../../models/money_in.dart';
import '../../models/money_out.dart';
import '../../models/purchase.dart';
import '../../models/expense.dart';

class ReceiptsCenterScreen extends StatelessWidget {
  const ReceiptsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receipts'),
          backgroundColor: const Color(0xFF6F4E37),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sales'),
              Tab(text: 'Money In'),
              Tab(text: 'Money Out'),
              Tab(text: 'Purchases'),
              Tab(text: 'Expenses'),
            ],
            isScrollable: true,
          ),
        ),
        body: const TabBarView(
          children: [
            _SalesReceiptsTab(),
            _MoneyInReceiptsTab(),
            _MoneyOutReceiptsTab(),
            _PurchaseReceiptsTab(),
            _ExpenseReceiptsTab(),
          ],
        ),
      ),
    );
  }
}

class _SalesReceiptsTab extends StatelessWidget {
  const _SalesReceiptsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalesTransaction>>(
      stream: FirestoreService.instance.streamSales(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = snapshot.data ?? [];
        if (sales.isEmpty) {
          return const Center(child: Text('No sales receipts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = sales[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white,
              title: Text(s.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.items.length} items • ${s.createdAt}'),
              trailing: Text('₹${s.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

class _ExpenseReceiptsTab extends StatelessWidget {
  const _ExpenseReceiptsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseEntry>>(
      stream: FirestoreService.instance.streamExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final expenses = snapshot.data ?? [];
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = expenses[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white,
              title: Text(e.category, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.paymentMode} • ${e.expenseDate.toString().split(' ').first}'),
              trailing: Text('₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

class _MoneyInReceiptsTab extends StatelessWidget {
  const _MoneyInReceiptsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MoneyInEntry>>(
      stream: FirestoreService.instance.streamMoneyIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('No money-in receipts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = entries[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white,
              title: Text(e.partyName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.paymentMode} • ${e.moneyInDate.toString().split(' ').first}'),
              trailing: Text('₹${e.amountReceived.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

class _MoneyOutReceiptsTab extends StatelessWidget {
  const _MoneyOutReceiptsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MoneyOutEntry>>(
      stream: FirestoreService.instance.streamMoneyOut(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('No money-out receipts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = entries[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white,
              title: Text(e.partyName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.paymentMode} • ${e.moneyOutDate.toString().split(' ').first}'),
              trailing: Text('₹${e.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}

class _PurchaseReceiptsTab extends StatelessWidget {
  const _PurchaseReceiptsTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PurchaseOrder>>(
      stream: FirestoreService.instance.streamPurchases(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final purchases = snapshot.data ?? [];
        if (purchases.isEmpty) {
          return const Center(child: Text('No purchase receipts'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: purchases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = purchases[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: Colors.white,
              title: Text(p.supplierName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p.items.length} items • ${p.createdAt.toString().split(' ').first}'),
              trailing: Text('₹${p.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}



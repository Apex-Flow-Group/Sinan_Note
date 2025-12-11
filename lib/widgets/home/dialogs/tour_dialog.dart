// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class TourDialog {
  static void show(
    BuildContext context,
    bool isArabic,
    VoidCallback onComplete,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: Text(
          isArabic ? 'مرحباً بك في سِنان!' : 'Welcome to Sinan!',
          style: const TextStyle(
              color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTourItem(
                  Icons.add_circle,
                  isArabic
                      ? 'زر + لإضافة ملاحظة جديدة'
                      : '+ button to add new note'),
              _buildTourItem(
                  Icons.search,
                  isArabic
                      ? 'شريط البحث للعثور على ملاحظاتك'
                      : 'Search bar to find notes'),
              _buildTourItem(
                  Icons.grid_view,
                  isArabic
                      ? 'زر العرض لتغيير التخطيط'
                      : 'View button to change layout'),
              _buildTourItem(
                  Icons.menu,
                  isArabic
                      ? 'قائمة جانبية للإعدادات'
                      : 'Side menu for settings'),
              _buildTourItem(
                  Icons.swipe,
                  isArabic
                      ? 'اسحب الملاحظة للحذف/الأرشفة'
                      : 'Swipe note to delete/archive'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onComplete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF0A1929),
            ),
            child: Text(isArabic ? 'فهمت!' : 'Got it!'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTourItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

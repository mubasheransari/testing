import 'package:flutter/material.dart';

enum ChatRole { user, tasker, system }

enum ViewerRole { user, tasker }

class ChatMessage {
  final String id;
  final String text;
  final ChatRole senderRole;
  final DateTime time;
  final bool isRead;
  final String? imageUrl;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderRole,
    required this.time,
    this.isRead = true,
    this.imageUrl,
    this.isSystem = false,
  });
}

class ChatParticipant {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isVerified;

  ChatParticipant({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isVerified = false,
  });
}

class ChatBookingInfo {
  final String bookingId;
  final String serviceName;
  final String status;
  final String dateTimeLabel;
  final String location;
  final double amount;

  ChatBookingInfo({
    required this.bookingId,
    required this.serviceName,
    required this.status,
    required this.dateTimeLabel,
    required this.location,
    required this.amount,
  });
}
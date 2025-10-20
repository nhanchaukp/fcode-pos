import 'package:flutter/material.dart';

import 'config/environment.dart';

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'models.dart' as models;
import 'enums.dart' as enums;
import 'services.dart' as services;

import 'storage/secure_storage.dart';
import 'storage/user_prefs.dart';

part 'id.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

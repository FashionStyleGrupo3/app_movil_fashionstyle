import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/data/services/app_updater_service.dart';
import 'package:path_provider/path_provider.dart';

const int kAppBuildNumber = 5 ;

const String kAppVersion = '1.2.0';
